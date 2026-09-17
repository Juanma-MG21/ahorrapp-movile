import 'package:flutter/material.dart';

import '../../models/historial_item.dart';
import '../../services/admin_service.dart';
import '../cuenta/widgets/seccion_card.dart';
import 'panel_dependientes_screen.dart';
import 'panel_usuarios_screen.dart';

/// Panel de administración — visible solo para roles admin/superuser.
/// Equivalente móvil de PanelAdmin.jsx: totales del sistema, accesos a
/// "Panel de usuarios" y "Panel de dependientes" (globales, de todos
/// los usuarios), y un resumen de actividad reciente del sistema.
class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> {
  late Future<_ResumenAdmin> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_ResumenAdmin> _cargar() async {
    final resultados = await Future.wait([
      AdminService.instance.getTotalUsuarios(),
      AdminService.instance.getTotalDependientes(),
      AdminService.instance.getHistorial(limite: 8),
    ]);
    return _ResumenAdmin(
      totalUsuarios: resultados[0] as int,
      totalDependientes: resultados[1] as int,
      actividad: resultados[2] as List<HistorialItem>,
    );
  }

  Future<void> _recargar() async {
    setState(() => _future = _cargar());
    await _future;
  }

  String _formatearFechaHora(DateTime? fecha) {
    if (fecha == null) return '';
    final f = fecha.toLocal();
    final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
    final ampm = f.hour >= 12 ? 'p.m.' : 'a.m.';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} · '
        '$h:${f.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuentaColors.background,
      appBar: AppBar(
        backgroundColor: CuentaColors.background,
        elevation: 0,
        title: const Text('Panel de administración',
            style: TextStyle(color: CuentaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CuentaColors.textPrimary),
      ),
      body: SafeArea(
        child: FutureBuilder<_ResumenAdmin>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: CuentaColors.accent));
            }

            if (snapshot.hasError) {
              return RefreshIndicator(
                color: CuentaColors.accent,
                onRefresh: _recargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 80),
                    Center(
                      child: Text(
                        'No se pudo cargar la información del panel',
                        style: TextStyle(color: CuentaColors.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }

            final resumen = snapshot.data!;

            return RefreshIndicator(
              color: CuentaColors.accent,
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  const Text(
                    'Resumen general del sistema',
                    style: TextStyle(color: CuentaColors.textMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Usuarios',
                          sublabel: 'Cuentas activas',
                          valor: resumen.totalUsuarios,
                          icon: Icons.groups_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Dependientes',
                          sublabel: 'Total registrados',
                          valor: resumen.totalDependientes,
                          icon: Icons.diversity_1_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SeccionCard(
                    title: 'Gestión',
                    children: [
                      SeccionTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Panel de usuarios',
                        subtitle: 'Editar datos y roles',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PanelUsuariosScreen()),
                        ),
                      ),
                      SeccionTile(
                        icon: Icons.family_restroom_outlined,
                        title: 'Panel de dependientes',
                        subtitle: 'Dependientes de todos los usuarios',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PanelDependientesScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ACTIVIDAD RECIENTE',
                      style: TextStyle(
                        color: CuentaColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: CuentaColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CuentaColors.border),
                    ),
                    child: resumen.actividad.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                            child: Text(
                              'No hay actividad registrada todavía.',
                              style: TextStyle(color: CuentaColors.textMuted, fontSize: 13),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < resumen.actividad.length; i++) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '${resumen.actividad[i].usuarioNombre} '
                                                        '${resumen.actividad[i].usuarioApellido ?? ''}'.trim(),
                                                    style: const TextStyle(
                                                        color: CuentaColors.textPrimary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13),
                                                  ),
                                                  TextSpan(
                                                    text: ' — ${resumen.actividad[i].accion}',
                                                    style: const TextStyle(
                                                        color: CuentaColors.textSecondary, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (resumen.actividad[i].detalles != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                resumen.actividad[i].detalles!,
                                                style: const TextStyle(color: CuentaColors.textMuted, fontSize: 11.5),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatearFechaHora(resumen.actividad[i].fecha),
                                        style: const TextStyle(color: CuentaColors.textMuted, fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i != resumen.actividad.length - 1)
                                  const Divider(height: 1, color: CuentaColors.border),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResumenAdmin {
  _ResumenAdmin({
    required this.totalUsuarios,
    required this.totalDependientes,
    required this.actividad,
  });

  final int totalUsuarios;
  final int totalDependientes;
  final List<HistorialItem> actividad;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.sublabel,
    required this.valor,
    required this.icon,
  });

  final String label;
  final String sublabel;
  final int valor;
  final IconData icon;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: CuentaColors.textSecondary, fontSize: 12.5)),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: CuentaColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: CuentaColors.accent, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('$valor', style: const TextStyle(color: CuentaColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(color: CuentaColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
