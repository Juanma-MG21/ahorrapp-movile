import 'dart:convert';
// PRUEBA TODAVIA SE SIGUE TESTEANDO 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/categoria_model.dart';
import '../services/categorias_service.dart';

// ─────────────────────────────────────────────────────────────────────
// PALETA · misma idea que en pantallas anteriores: constantes locales
// que aproximan los colores de Tailwind que usabas (amber, emerald,
// orange, indigo, zinc, slate). Si ya tienes una paleta compartida
// (como el `Tokens` del dashboard), reemplaza estas por esas.
// ─────────────────────────────────────────────────────────────────────

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

  List<CategoriaData> _categorias = [];
  // Nombre del usuario leído de storage — reemplaza tu
  // `JSON.parse(localStorage.getItem('usuario'))` de arriba del
  // archivo. Lo guardo como estado porque leerlo es async (`await`),
  // así que no puede ir en una variable de nivel de archivo como en JS.
  String? _nombreUsuario;

  // Nota: `menuOpen` del original quedó comentado como "agregado pero
  // no revisado" y no se usaba en ninguna parte visible del JSX, así
  // que no lo traigo aquí — si luego lo necesitas (por ejemplo para un
  // menú de opciones), lo agregamos con su propósito claro.

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
    } catch (_) {
      // Igual que tu `catch { usuario = null }`: si el JSON está mal
      // formado, simplemente nos quedamos sin nombre, sin tronar la app.
    }
  }

  // `Future.wait` es el `Promise.all` de Dart: lanza las 5 llamadas al
  // mismo tiempo (no una tras otra) y espera a que TODAS terminen
  // antes de seguir. El resultado es una `List` en el mismo orden en
  // que pusiste los Futures, por eso puedo desestructurarla con
  // índices `[0]`, `[1]`, etc. — Dart no tiene destructuring posicional
  // como `const [a, b] = arr` de JS para listas de tipos distintos
  // aquí, así que la leo por índice.
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

      // `firstWhere` es el `.find()` de Dart, pero EXIGE un
      // `orElse` si hay chance de no encontrar nada (a diferencia de
      // `.find()`, que devuelve `undefined` sin quejarse). Aquí
      // devuelvo un Map vacío `{}` como "no encontrado", y luego uso
      // `['clave'] as num? ?? 0` para leerlo de forma segura.
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

        // Uso `CategoriaData.fromJson` sobre el Map de gastos (que trae
        // id/nombre/descripcion/activa/es_global) y luego `copyWith`
        // para clavarle el total ya sumado.
        return CategoriaData.fromJson(cat).copyWith(totalMovimientos: total);
      }).toList();

      setState(() => _categorias = combinadas);
    } catch (error) {
      // `debugPrint` = tu `console.error`.
      debugPrint('Error al cargar categorías combinadas: $error');
    }
  }

  // Getters: se calculan solos cada vez que los lees, no hace falta
  // guardarlos como estado aparte — igual de "derivados" que tus
  // constantes `activas`/`inactivas` dentro del render de React.
  List<CategoriaData> get _activas => _categorias.where((c) => c.activa).toList();
  List<CategoriaData> get _inactivas => _categorias.where((c) => !c.activa).toList();

  String _formatMoney(num valor) {
    return NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(valor);
  }

  // ── Toast / Alert / Confirm ─────────────────────────────────────
  // Flutter no tiene un `alert()`/`confirm()` de navegador; los
  // simulamos con SnackBar (para el toast) y AlertDialog (para
  // mensajes bloqueantes y confirmaciones).

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

  // Devuelve `true`/`false` según el botón que toque el usuario —
  // reemplaza tu `window.confirm(...)`, que en JS devuelve el bool
  // directamente porque BLOQUEA el hilo; aquí, como todo es async,
  // hay que `await` este método para obtener la respuesta.
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
    // Si el usuario cierra el diálogo tocando fuera (sin elegir botón),
    // `resultado` llega `null`; el `?? false` lo trata como "canceló".
    return resultado ?? false;
  }

  // ── Handlers CRUD ────────────────────────────────────────────────

  Future<void> _handleAgregar(String nombre, String descripcion) async {
    if (nombre.trim().isEmpty) {
      await _mostrarAlerta('El nombre es obligatorio');
      return;
    }
    try {
      final respuesta = await _service.crearCategoria(nombre: nombre.trim(), descripcion: descripcion.trim());
      if (respuesta['ok'] == true) {
        _mostrarToast('Categoría registrada correctamente');
        setState(() {
          _categorias = [
            ..._categorias,
            CategoriaData(
              id: respuesta['id'] as int,
              nombre: nombre.trim(),
              descripcion: descripcion.trim(),
              activa: true,
              esGlobal: false,
              sistema: false,
            ),
          ];
        });
        if (mounted) Navigator.of(context).pop(); // cierra el modal
      } else {
        await _mostrarAlerta(respuesta['mensaje'] as String? ?? 'Error al crear la categoría');
      }
    } catch (error) {
      await _mostrarAlerta('Error al crear la categoría');
    }
  }

  Future<void> _handleGuardarEdicion(CategoriaData original, String nombre, String descripcion) async {
    if (nombre.trim().isEmpty) {
      await _mostrarAlerta('El nombre es obligatorio');
      return;
    }
    try {
      final respuesta = await _service.editarCategoria(original.id, nombre: nombre.trim(), descripcion: descripcion.trim());
      if (respuesta['ok'] == true) {
        _mostrarToast('Categoría actualizada correctamente');
        setState(() {
          _categorias = _categorias
              .map((c) => c.id == original.id ? c.copyWith(nombre: nombre.trim(), descripcion: descripcion.trim()) : c)
              .toList();
        });
        if (mounted) Navigator.of(context).pop();
      } else {
        await _mostrarAlerta(respuesta['mensaje'] as String? ?? 'Error al editar la categoría');
      }
    } catch (error) {
      await _mostrarAlerta('Error al editar la categoría');
    }
  }

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

  // ── Modales ──────────────────────────────────────────────────────

  void _abrirModalAgregar() {
    showDialog(context: context, builder: (context) => _FormularioCategoria(titulo: '🧩 Nueva Categoría', onGuardar: _handleAgregar));
  }

  void _abrirModalEditar(CategoriaData cat) {
    showDialog(
      context: context,
      builder: (context) => _FormularioCategoria(
        titulo: '✏️ Editar Categoría',
        nombreInicial: cat.nombre,
        descripcionInicial: cat.descripcion ?? '',
        onGuardar: (nombre, descripcion) => _handleGuardarEdicion(cat, nombre, descripcion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // aproximación plana del radial-gradient de fondo
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Reemplaza tu <HeaderModulos section="Categorías" />. Si ya
            // tienes ese componente portado a Flutter, cámbialo por ese
            // widget aquí en vez de este título simple.
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
      // `Wrap` en vez de `Row` fijo, para que en pantallas angostas el
      // botón caiga debajo del contador en vez de desbordarse — tu
      // versión web resolvía esto con `flex-col sm:flex-row`.
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
          ElevatedButton(
            onPressed: _abrirModalAgregar,
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
                  // `LayoutBuilder` hace de "media query": decide layout
                  // según el ancho disponible, igual que tu `md:hidden` /
                  // `hidden md:block` de Tailwind.
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

  // Vista "card" para pantallas angostas (equivalente al `grid md:hidden`).
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
                    Expanded(child: _botonEditar(() => _abrirModalEditar(cat))),
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

  // Vista tabla para pantallas anchas (equivalente al `hidden md:block` + <table>).
  Widget _tablaActivas() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // `DataTable` es el widget nativo de Flutter para tablas con
      // encabezado y filas; reemplaza tu `<table><thead>...<tbody>`.
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
                      _botonEditar(() => _abrirModalEditar(cat)),
                      const SizedBox(width: 8),
                      _botonDeshabilitar(() => _handleDeshabilitar(cat.id)),
                    ]),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _tarjetaInactiva(CategoriaData cat) {
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

// ─────────────────────────────────────────────────────────────────────
// FORMULARIO (modal) · lo separé en su propio StatefulWidget porque
// necesita sus PROPIOS TextEditingController — si lo dejara como
// método dentro de la pantalla, cada `setState` de la pantalla
// recrearía los controllers y perderías lo que el usuario escribió.
// ─────────────────────────────────────────────────────────────────────

class _FormularioCategoria extends StatefulWidget {
  final String titulo;
  final String nombreInicial;
  final String descripcionInicial;
  // Función que este formulario llama al guardar; la pantalla decide
  // si eso significa "crear" o "editar" (se la pasamos distinta en
  // cada caso desde `_abrirModalAgregar` / `_abrirModalEditar`).
  final Future<void> Function(String nombre, String descripcion) onGuardar;

  const _FormularioCategoria({
    required this.titulo,
    this.nombreInicial = '',
    this.descripcionInicial = '',
    required this.onGuardar,
  });

  @override
  State<_FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<_FormularioCategoria> {
  // `TextEditingController` es el equivalente Dart de tu
  // `value={formNombre} onChange={e => setFormNombre(e.target.value)}`:
  // en vez de guardar el texto en una variable de estado y
  // reescribirla en cada tecla, el controller "es" el texto del campo
  // y tú lo lees cuando lo necesitas (`.text`).
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreInicial);
    _descCtrl = TextEditingController(text: widget.descripcionInicial);
  }

  // Los controllers reservan recursos nativos; hay que liberarlos
  // manualmente cuando el widget se destruye — Dart/Flutter no tiene
  // garbage collector para esto como sí lo tiene JS con sus closures.
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xF2020617),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _amber400)),
            const SizedBox(height: 16),
            const Text('NOMBRE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _zinc400, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: _zinc100),
              decoration: _decoracionInput('Ej: Ropa, Mascotas...'),
            ),
            const SizedBox(height: 16),
            const Text('DESCRIPCIÓN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _zinc400, letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: _zinc100),
              decoration: _decoracionInput('Descripción opcional'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: _zinc400)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => widget.onGuardar(_nombreCtrl.text, _descCtrl.text),
                  style: ElevatedButton.styleFrom(backgroundColor: _emerald400, foregroundColor: _slate950),
                  child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracionInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _zinc500),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}