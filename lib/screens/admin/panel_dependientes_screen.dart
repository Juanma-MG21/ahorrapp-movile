import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/dependiente_admin.dart';
import '../../services/admin_service.dart';
import '../cuenta/widgets/seccion_card.dart';

/// Panel de dependientes — equivalente móvil de PanelDependientes.jsx.
/// Muestra TODOS los dependientes del sistema (de cualquier usuario),
/// no solo los del usuario logueado; es la gestión global que ve el
/// administrador.
class PanelDependientesAdminScreen extends StatefulWidget {
  const PanelDependientesAdminScreen({super.key});

  @override
  State<PanelDependientesAdminScreen> createState() => _PanelDependientesAdminScreenState();
}

class _PanelDependientesAdminScreenState extends State<PanelDependientesAdminScreen> {
  List<DependienteAdmin> _dependientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final dependientes = await AdminService.instance.getDependientesGlobales();
      if (!mounted) return;
      setState(() {
        _dependientes = dependientes;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al obtener dependientes';
        _cargando = false;
      });
    }
  }

  Future<void> _confirmarEliminar(DependienteAdmin dependiente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CuentaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar dependiente', style: TextStyle(color: CuentaColors.textPrimary)),
        content: Text(
          '¿Seguro deseas eliminar a ${dependiente.nombre}?',
          style: const TextStyle(color: CuentaColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: CuentaColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: CuentaColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await AdminService.instance.eliminarDependiente(dependiente.id);
      if (!mounted) return;
      setState(() => _dependientes = _dependientes.where((d) => d.id != dependiente.id).toList());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el dependiente'), backgroundColor: CuentaColors.danger),
      );
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuentaColors.background,
      appBar: AppBar(
        backgroundColor: CuentaColors.background,
        elevation: 0,
        title: const Text('Lista de dependientes',
            style: TextStyle(color: CuentaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CuentaColors.textPrimary),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: CuentaColors.accent))
            : RefreshIndicator(
                color: CuentaColors.accent,
                onRefresh: _cargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text('${_dependientes.length} registrados',
                        style: const TextStyle(color: CuentaColors.textMuted, fontSize: 12.5)),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: CuentaColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CuentaColors.danger.withValues(alpha: 0.35)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: CuentaColors.danger, fontSize: 13)),
                      ),
                    if (_dependientes.isEmpty && _error == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('No hay dependientes registrados.', style: TextStyle(color: CuentaColors.textMuted)),
                        ),
                      ),
                    for (final dependiente in _dependientes) ...[
                      _DependienteCard(
                        dependiente: dependiente,
                        onEliminar: () => _confirmarEliminar(dependiente),
                        formatearFecha: _formatearFecha,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _DependienteCard extends StatelessWidget {
  const _DependienteCard({
    required this.dependiente,
    required this.onEliminar,
    required this.formatearFecha,
  });

  final DependienteAdmin dependiente;
  final VoidCallback onEliminar;
  final String Function(DateTime?) formatearFecha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuentaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CuentaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CuentaColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(dependiente.inicial,
                      style: const TextStyle(color: CuentaColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dependiente.nombre,
                        style: const TextStyle(color: CuentaColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    Text('ID ${dependiente.id}', style: const TextStyle(color: CuentaColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              if (dependiente.relacion != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CuentaColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(dependiente.relacion!,
                      style: const TextStyle(color: CuentaColors.info, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const Divider(height: 20, color: CuentaColors.border),
          _fila(Icons.person_outline, 'Dependiente de ${dependiente.usuarioNombre} (ID ${dependiente.idUsuario})'),
          const SizedBox(height: 8),
          _fila(Icons.work_outline, dependiente.ocupacion?.isNotEmpty == true ? dependiente.ocupacion! : 'Sin ocupación registrada'),
          const SizedBox(height: 8),
          _fila(Icons.cake_outlined, formatearFecha(dependiente.fechaNacimiento)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline, size: 15, color: CuentaColors.danger),
              label: const Text('Borrar', style: TextStyle(color: CuentaColors.danger, fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: CuentaColors.danger.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: CuentaColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: const TextStyle(color: CuentaColors.textSecondary, fontSize: 12.5)),
        ),
      ],
    );
  }
}
