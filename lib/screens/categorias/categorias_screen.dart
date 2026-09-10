import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/categorias_model.dart';
import '../../services/categorias_service.dart';
import 'agregar_categorias_screen.dart'; // ajusta la ruta si la carpeta es distinta

const Color _emerald400 = Color(0xFF34d399);
const Color _emerald500 = Color(0xFF10b981);
const Color _amber300 = Color(0xFFfcd34d);
const Color _amber400 = Color(0xFFfbbf24);
const Color _orange400 = Color(0xFFfb923c);
const Color _indigo300 = Color(0xFFa5b4fc);
const Color _indigo400 = Color(0xFF818cf8);
const Color _zinc100 = Color(0xFFf4f4f5);
const Color _zinc400 = Color(0xFFa1a1aa);
const Color _zinc500 = Color(0xFF71717a);
const Color _zinc600 = Color(0xFF52525b);
const Color _slate950 = Color(0xFF020617);

class ModuloCategoriasScreen extends StatefulWidget {
  const ModuloCategoriasScreen({super.key});

  @override
  State<ModuloCategoriasScreen> createState() => _ModuloCategoriasScreenState();
}

class _ModuloCategoriasScreenState extends State<ModuloCategoriasScreen> {
  final _service = CategoriasService();
  final _storage = const FlutterSecureStorage();

  // Antes: `List<CategoriaData>`. Cambiado a `CategoriaModel`.
  List<CategoriaModel> _categorias = [];
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarCategoriasCombinadas();
  }

  Future<void> _cargarUsuario() async {
    final crudo = await _storage.read(key: 'usuario');
    if (crudo == null) return;
    try {
      final data = jsonDecode(crudo) as Map<String, dynamic>;
      setState(() => _nombreUsuario = data['nombre'] as String?);
    } catch (_) {}
  }

  Future<void> _cargarCategoriasCombinadas() async {
    try {
      final resultados = await Future.wait([
        _service.getGastosPorCategoria(),
        _service.getIngresosPorCategoria(),
        _service.getAhorrosPorCategoria(),
        _service.getImprevistosPorCategoria(),
        _service.getDeudasPorCategoria(),
      ]);

      final gastos = resultados[0];
      final ingresos = resultados[1];
      final ahorros = resultados[2];
      final imprevistos = resultados[3];
      final deudas = resultados[4];

      final combinadas = gastos.map((cat) {
        final ing = ingresos.firstWhere((c) => c['id'] == cat['id'], orElse: () => {});
        final aho = ahorros.firstWhere((c) => c['id'] == cat['id'], orElse: () => {});
        final imp = imprevistos.firstWhere((c) => c['id'] == cat['id'], orElse: () => {});
        final deu = deudas.firstWhere((c) => c['id'] == cat['id'], orElse: () => {});

        final total = (cat['total_gastos'] as num? ?? 0) +
            (ing['total_ingresos'] as num? ?? 0) +
            (aho['total_ahorros'] as num? ?? 0) +
            (imp['total_imprevistos'] as num? ?? 0) +
            (deu['total_deudas'] as num? ?? 0);

        // Antes: `CategoriaData.fromJson(...)`.
        return CategoriaModel.fromJson(cat).copyWith(totalMovimientos: total);
      }).toList();

      setState(() => _categorias = combinadas);
    } catch (error) {
      debugPrint('Error al cargar categorías combinadas: $error');
    }
  }

  List<CategoriaModel> get _activas => _categorias.where((c) => c.activa).toList();
  List<CategoriaModel> get _inactivas => _categorias.where((c) => !c.activa).toList();

  String _formatMoney(num valor) {
    return NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(valor);
  }

  void _mostrarToast(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _mostrarAlerta(String mensaje) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _slate950,
        content: Text(mensaje, style: const TextStyle(color: _zinc100)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<bool> _confirmar(String mensaje) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _slate950,
        content: Text(mensaje, style: const TextStyle(color: _zinc100)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Aceptar')),
        ],
      ),
    );
    return resultado ?? false;
  }

  // ── CRUD que sigue viviendo en esta pantalla ──────────────────────
  // `_handleAgregar` y `_handleGuardarEdicion` YA NO EXISTEN AQUÍ:
  // esa lógica ahora vive dentro de `AgregarCategoriaScreen`
  // (`_guardarCategoria`, en ese archivo). Esta pantalla solo necesita
  // abrir esa pantalla y, cuando vuelva con un resultado `true`,
  // recargar la lista — igual que hicimos con dependientes.
  //
  // Deshabilitar/habilitar SÍ se quedan aquí, porque son acciones que
  // se disparan directo desde la lista, sin pasar por un formulario.

  Future<void> _handleDeshabilitar(int id) async {
    final confirma = await _confirmar('¿Seguro que deseas deshabilitar esta categoría?');
    if (!confirma) return;

    try {
      final respuesta = await _service.deshabilitarCategoria(id);
      if (respuesta['ok'] == true) {
        _mostrarToast('Categoría deshabilitada correctamente');
        setState(() {
          _categorias = _categorias.map((c) => c.id == id ? c.copyWith(activa: false) : c).toList();
        });
      } else {
        await _mostrarAlerta(respuesta['mensaje'] as String? ?? 'Error al deshabilitar la categoría');
      }
    } catch (error) {
      await _mostrarAlerta('Error al deshabilitar la categoría');
    }
  }

  Future<void> _handleHabilitar(int id) async {
    try {
      final respuesta = await _service.habilitarCategoria(id);
      if (respuesta['ok'] == true) {
        _mostrarToast('Categoría habilitada correctamente');
        setState(() {
          _categorias = _categorias.map((c) => c.id == id ? c.copyWith(activa: true) : c).toList();
        });
      } else {
        await _mostrarAlerta(respuesta['mensaje'] as String? ?? 'Error al habilitar la categoría');
      }
    } catch (error) {
      await _mostrarAlerta('Error al habilitar la categoría');
    }
  }

  // ── Navegación al formulario (reemplaza los antiguos modales) ────

  // Antes: `_abrirModalAgregar` abría un `Dialog`. Ahora navega a la
  // pantalla completa. `Navigator.push<bool>` tipa el resultado que
  // esperamos recibir: `AgregarCategoriaScreen` hace
  // `Navigator.pop(context, true)` cuando guarda con éxito.
  Future<void> _abrirAgregarCategoria() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AgregarCategoriaScreen()),
    );

    // Si volvió con `true`, algo se creó — recargamos desde el
    // backend en vez de intentar armar el objeto a mano aquí (como
    // hacía el `_handleAgregar` viejo), para que el total de
    // movimientos y demás datos calculados vengan siempre frescos.
    if (guardado == true) {
      _cargarCategoriasCombinadas();
    }
  }

  Future<void> _abrirEditarCategoria(CategoriaModel cat) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarCategoriaScreen(categoriaParaEditar: cat),
      ),
    );

    if (guardado == true) {
      _cargarCategoriasCombinadas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Categorías', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: _amber400, thickness: 1, height: 1),
            ),
            const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 13, color: _zinc400)),
            Text('${_nombreUsuario ?? 'Usuario'} 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            _tarjetaResumen(),
            const SizedBox(height: 20),
            _seccionCategorias(),
            const SizedBox(height: 24),
            const Center(child: Text('© 2026 Ahorrapp. Todos los derechos reservados.', style: TextStyle(fontSize: 11, color: _zinc600))),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: LinearGradient(colors: [_emerald500.withOpacity(0.2), _emerald500.withOpacity(0.03)]),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧩 CATEGORÍAS ACTIVAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _emerald400, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${_activas.length}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          // El botón "+ Agregar Categoría" que pediste — ya existía en
          // tu código, solo cambié a qué método llama.
          ElevatedButton(
            onPressed: _abrirAgregarCategoria,
            style: ElevatedButton.styleFrom(
              backgroundColor: _emerald400,
              foregroundColor: _slate950,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('+ Agregar Categoría', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _seccionCategorias() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
            child: const Text('📋 Módulo de Categorías', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _amber400)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay categorías activas.', style: TextStyle(fontSize: 13, color: _zinc500, fontStyle: FontStyle.italic)),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final esAncho = constraints.maxWidth >= 768;
                      return esAncho ? _tablaActivas() : _tarjetasActivas();
                    },
                  ),
                if (_inactivas.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text('Categorías deshabilitadas (${_inactivas.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _zinc500, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ..._inactivas.map(_tarjetaInactiva),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetasActivas() {
    return Column(
      children: _activas.map((cat) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _zinc100)),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : 'Sin descripción', style: const TextStyle(fontSize: 13, color: _zinc400)),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), border: Border.all(color: Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total movimientos', style: TextStyle(fontSize: 11, color: _zinc500)),
                              Text(_formatMoney(cat.totalMovimientos), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _amber300)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _chipTipo(cat.esGlobal),
                ],
              ),
              if (!cat.esSistemaOGlobal) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _botonEditar(() => _abrirEditarCategoria(cat))),
                    const SizedBox(width: 8),
                    Expanded(child: _botonDeshabilitar(() => _handleDeshabilitar(cat.id))),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tablaActivas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre', style: TextStyle(color: _zinc500, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Descripción', style: TextStyle(color: _zinc500, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Tipo', style: TextStyle(color: _zinc500, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Total movimientos', style: TextStyle(color: _zinc500, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Acciones', style: TextStyle(color: _zinc500, fontWeight: FontWeight.w700))),
        ],
        rows: _activas.map((cat) {
          return DataRow(cells: [
            DataCell(Text(cat.nombre, style: const TextStyle(color: _zinc100, fontWeight: FontWeight.w700))),
            DataCell(Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : '—', style: const TextStyle(color: _zinc400))),
            DataCell(_chipTipo(cat.esGlobal)),
            DataCell(Text(_formatMoney(cat.totalMovimientos), style: const TextStyle(color: _amber300, fontWeight: FontWeight.w700))),
            DataCell(
              cat.esSistemaOGlobal
                  ? const SizedBox.shrink()
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      _botonEditar(() => _abrirEditarCategoria(cat)),
                      const SizedBox(width: 8),
                      _botonDeshabilitar(() => _handleDeshabilitar(cat.id)),
                    ]),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _tarjetaInactiva(CategoriaModel cat) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), border: Border.all(color: Colors.white.withOpacity(0.1)), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cat.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _zinc500, decoration: TextDecoration.lineThrough)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : 'Sin descripción', style: const TextStyle(fontSize: 13, color: _zinc600)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleHabilitar(cat.id),
                style: OutlinedButton.styleFrom(foregroundColor: _emerald400, side: const BorderSide(color: _emerald400)),
                child: const Text('Habilitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipTipo(bool esGlobal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (esGlobal ? _emerald400 : _indigo400).withOpacity(0.15),
        border: Border.all(color: (esGlobal ? _emerald400 : _indigo400).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(esGlobal ? 'Sistema' : 'Personal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: esGlobal ? _emerald400 : _indigo300)),
    );
  }

  Widget _botonEditar(VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: _emerald400, side: const BorderSide(color: _emerald400)),
      child: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _botonDeshabilitar(VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: _orange400, side: const BorderSide(color: _orange400)),
      child: const Text('Deshabilitar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

// La clase `_FormularioCategoria` (el Dialog viejo) se ELIMINÓ por
// completo — ya no se usa en ningún lado de este archivo.