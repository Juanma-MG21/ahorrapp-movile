import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

import '../../models/dependiente_model.dart';
import '../../services/dependiente_services.dart';
import '../../core/network/api_client.dart';
import '../dependientes/agregar_dependientes_screen.dart';

const Map<int, String> _pesoLabels = {
  1: 'Muy bajo',
  2: 'Bajo',
  3: 'Medio',
  4: 'Alto',
  5: 'Muy alto',
};

Color _pesoColor(int? peso) {
  final p = peso ?? 3;
  if (p <= 1) return AppColors.success;
  if (p <= 2) return AppCategoryColors.transporte;
  if (p <= 3) return AppColors.accent;
  if (p <= 4) return AppColors.accent;
  return AppColors.error;
}

class PanelDependientesScreen extends StatefulWidget {
  const PanelDependientesScreen({super.key});

  @override
  State<PanelDependientesScreen> createState() =>
      _PanelDependientesScreenState();
}

class _PanelDependientesScreenState extends State<PanelDependientesScreen> {
  List<DependienteModel> _dependientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getDependientes();
  }

  // ─────────────────────────────────────────────────────────────
  // CARGA
  // ─────────────────────────────────────────────────────────────

  Future<void> _getDependientes({bool mostrarLoader = true}) async {
    if (mostrarLoader) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final lista = await DependientesService.getDependientes();
      if (!mounted) return;
      setState(() => _dependientes = lista);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al obtener dependientes');
      debugPrint('$e');
    } finally {
      if (mounted && mostrarLoader) {
        setState(() => _cargando = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FECHA
  // ─────────────────────────────────────────────────────────────

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha registrada';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  // ─────────────────────────────────────────────────────────────
  // NAVEGACIÓN (con optimistic update)
  // ─────────────────────────────────────────────────────────────

  Future<void> _abrirAgregarDependiente() async {
    final resultado = await Navigator.push<DependienteModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarDependienteScreen(),
      ),
    );

    if (resultado == null || !mounted) return;

    // Optimistic update: añade el nuevo a la lista YA.
    // NO refrescamos del backend: el POST ya devolvió el objeto con id.
    setState(() {
      _dependientes = [..._dependientes, resultado];
    });
  }

  Future<void> _abrirEditarDependiente(DependienteModel dep) async {
    final resultado = await Navigator.push<DependienteModel>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AgregarDependienteScreen(dependienteParaEditar: dep),
      ),
    );

    if (resultado == null || !mounted) return;

    // Optimistic update: reemplaza el item YA.
    setState(() {
      _dependientes = _dependientes
          .map((d) => d.id == resultado.id ? resultado : d)
          .toList();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ELIMINAR
  // ─────────────────────────────────────────────────────────────

  Future<void> _confirmarEliminar(DependienteModel dep) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar dependiente',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Seguro que deseas eliminar a "${dep.nombre}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await _eliminar(dep);
  }

  Future<void> _eliminar(DependienteModel dep) async {
    if (dep.id == null) return;

    // Guarda copia para restaurar si falla.
    final backup = List<DependienteModel>.from(_dependientes);

    // Optimistic update: quita el item de la lista YA.
    setState(() {
      _dependientes = _dependientes.where((d) => d.id != dep.id).toList();
    });

    try {
      await DependientesService.eliminarDependiente(dep.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${dep.nombre} eliminado')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _dependientes = backup);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dependientes = backup);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el dependiente'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.4,
            colors: [AppColors.surfaceAlt, AppColors.surface, AppColors.background],
            stops: [0.1, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _getDependientes,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textPrimary.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppCategoryColors.almuerzo.withOpacity(0.35),
              AppCategoryColors.almuerzo.withOpacity(0.04),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL DEPENDIENTES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppCategoryColors.almuerzo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_dependientes.length}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _abrirAgregarDependiente,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCategoryColors.almuerzo,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '➕ Agregar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            'Cargando dependientes...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
        ),
      );
    }

    if (_dependientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay dependientes registrados. Agrega tu primer dependiente para comenzar.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _dependientes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dep = _dependientes[index];
        return _DependienteCard(
          dependiente: dep,
          fechaFormateada: _formatFecha(dep.fechaNacimiento),
          onEditar: () => _abrirEditarDependiente(dep),
          onEliminar: () => _confirmarEliminar(dep),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CARD CON BOTONES EDITAR / ELIMINAR
// ═════════════════════════════════════════════════════════════════

class _DependienteCard extends StatelessWidget {
  final DependienteModel dependiente;
  final String fechaFormateada;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _DependienteCard({
    required this.dependiente,
    required this.fechaFormateada,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final color = _pesoColor(dependiente.pesoEconomico);
    final label = _pesoLabels[dependiente.pesoEconomico] ?? 'N/A';

    // Ya no hay GestureDetector envolviendo toda la card.
    // Los toques solo se manejan en los IconButton de abajo.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.05),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.09)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: nombre + acciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dependiente.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [dependiente.relacion, dependiente.ocupacion]
                          .where((v) => v != null && v.isNotEmpty)
                          .join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 👇 Botón Editar (lápiz)
              IconButton(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined),
                color: AppCategoryColors.transporte,
                tooltip: 'Editar dependiente',
                splashRadius: 22,
              ),
              // 👇 Botón Eliminar (papelera)
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: 'Eliminar dependiente',
                splashRadius: 22,
              ),
            ],
          ),
          if (dependiente.fechaNacimiento != null) ...[
            const SizedBox(height: 4),
            Text(
              'Nac: $fechaFormateada',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              border: Border.all(color: color.withOpacity(0.27)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Peso económico: $label',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}