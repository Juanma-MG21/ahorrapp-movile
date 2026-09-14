import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../models/categoria_model.dart';
import '../../services/auth_service.dart';
import '../../services/categorias_service.dart';
import './agregar_categorias_screen.dart';

class ModuloCategoriasScreen extends StatefulWidget {
  const ModuloCategoriasScreen({super.key});

  @override
  State<ModuloCategoriasScreen> createState() => _ModuloCategoriasScreenState();
}

class _ModuloCategoriasScreenState extends State<ModuloCategoriasScreen> {
  final _service = CategoriasService();

  // Antes: `List<CategoriaData>`. Cambiado a `CategoriaModel`.
  List<CategoriaModel> _categorias = [];
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarCategoriasCombinadas();
  }

  // Antes leía directo de FlutterSecureStorage con la clave 'usuario'
  // (que ni siquiera existe: AuthService guarda el usuario cacheado
  // bajo 'auth_user', como Usuario.toJson()). Se reemplaza por el
  // mismo método que ya usa el resto de la app.
  Future<void> _cargarUsuario() async {
    final usuario = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() => _nombreUsuario = usuario?.nombre);
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
        backgroundColor: AppColors.surface,
        content: Text(mensaje, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<bool> _confirmar(String mensaje) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Text(mensaje, style: const TextStyle(color: AppColors.textPrimary)),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Categorías', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.accent, thickness: 1, height: 1),
            ),
            const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('${_nombreUsuario ?? 'Usuario'} 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _tarjetaResumen(),
            const SizedBox(height: 20),
            _seccionCategorias(),
            const SizedBox(height: 24),
            const Center(child: Text('© 2026 Ahorrapp. Todos los derechos reservados.', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        gradient: LinearGradient(colors: [
          AppColors.success.withValues(alpha: 0.2),
          AppColors.success.withValues(alpha: 0.03),
        ]),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧩 CATEGORÍAS ACTIVAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${_activas.length}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
          // El botón "+ Agregar Categoría" que pediste — ya existía en
          // tu código, solo cambié a qué método llama.
          ElevatedButton(
            onPressed: _abrirAgregarCategoria,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              // Texto negro plano sobre botón de color sólido, mismo
              // criterio que ya usa _buildGuardarButton en
              // agregar_categoria_screen.dart sobre clayGlow().
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
            child: const Text('📋 Módulo de Categorías', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accent)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay categorías activas.', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
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
                  Text('Categorías deshabilitadas (${_inactivas.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1)),
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
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                        Text(cat.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : 'Sin descripción', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.inset, border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total movimientos', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text(_formatMoney(cat.totalMovimientos), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
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
          DataColumn(label: Text('Nombre', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Descripción', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Tipo', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Total movimientos', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Acciones', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))),
        ],
        rows: _activas.map((cat) {
          return DataRow(cells: [
            DataCell(Text(cat.nombre, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
            DataCell(Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : '—', style: const TextStyle(color: AppColors.textSecondary))),
            DataCell(_chipTipo(cat.esGlobal)),
            DataCell(Text(_formatMoney(cat.totalMovimientos), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
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
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cat.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(cat.descripcion?.isNotEmpty == true ? cat.descripcion! : 'Sin descripción', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleHabilitar(cat.id),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                child: const Text('Habilitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipTipo(bool esGlobal) {
    // Sin equivalente exacto para "índigo" en la paleta: se usa el
    // lila ya existente (AppCategoryColors.almuerzo) como color más
    // cercano para categorías "Personal" (no globales/sistema).
    final color = esGlobal ? AppColors.success : AppCategoryColors.almuerzo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(esGlobal ? 'Sistema' : 'Personal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _botonEditar(VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
      child: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _botonDeshabilitar(VoidCallback onTap) {
    // Sin equivalente exacto para "naranja/advertencia": se usa
    // AppColors.error, el mismo criterio que ya usa el resto de la
    // app para acciones destructivas/negativas.
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
      child: const Text('Deshabilitar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

// La clase `_FormularioCategoria` (el Dialog viejo) se ELIMINÓ por
// completo — ya no se usa en ningún lado de este archivo.