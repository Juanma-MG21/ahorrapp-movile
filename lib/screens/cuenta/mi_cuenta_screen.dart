import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/cuenta_service.dart';
import '../admin/panel_admin_screen.dart';
import 'cambiar_password_screen.dart';
import 'editar_perfil_screen.dart';
import 'mis_movimientos_screen.dart';
import 'widgets/movimiento_tile.dart';
import 'widgets/seccion_card.dart';
import '../../models/movimiento.dart';

/// Pantalla raíz de "Mi cuenta" en móvil.
///
/// Reúne, en un único lugar pensado para pantallas pequeñas:
///  - Encabezado de perfil (avatar, nombre, correo, badge de rol).
///  - Resumen compacto de "Mis movimientos" (estilo cajitas de Nu),
///    con acceso a la lista completa en otra pantalla.
///  - Accesos a "Editar mis datos" y "Cambiar contraseña" (RF 3),
///    cada uno en su propia subpantalla para no saturar esta vista.
///  - Botón "Panel de administración", visible SOLO para roles
///    admin/superuser (RF 4).
///  - Zona de peligro: desactivar la cuenta, con aviso de eliminación
///    a los 30 días (RF 6).
///
/// A propósito NO incluye nada de notificaciones (no aplica en móvil).
class MiCuentaScreen extends StatefulWidget {
  const MiCuentaScreen({super.key});

  @override
  State<MiCuentaScreen> createState() => _MiCuentaScreenState();
}

class _MiCuentaScreenState extends State<MiCuentaScreen> {
  Usuario? _usuario;
  bool _cargandoUsuario = true;

  late Future<List<Movimiento>> _futureMovimientos;
  static const int _maxMovimientosResumen = 5;

  bool _desactivando = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _futureMovimientos = CuentaService.instance.getMovimientos();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _usuario = usuario;
      _cargandoUsuario = false;
    });
  }

  bool _tieneRol(String rol) {
    final roles = _usuario?.roles;
    if (roles is List) return roles.map((r) => '$r'.toLowerCase()).contains(rol);
    return false;
  }

  bool get _puedeVerPanelAdmin => _tieneRol('admin') || _tieneRol('superuser');

  String get _iniciales {
    final n = _usuario?.nombre ?? '';
    final a = _usuario?.apellido ?? '';
    final i1 = n.isNotEmpty ? n[0] : '';
    final i2 = a.isNotEmpty ? a[0] : '';
    return ('$i1$i2').toUpperCase();
  }

  Future<void> _abrirEditarPerfil() async {
    if (_usuario == null) return;
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditarPerfilScreen(
          nombreActual: _usuario!.nombre,
          apellidoActual: _usuario!.apellido,
          emailActual: _usuario!.email,
        ),
      ),
    );
    if (actualizado == true) {
      await _cargarUsuario();
    }
  }

  Future<void> _abrirCambiarPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CambiarPasswordScreen()),
    );
  }

  Future<void> _abrirPanelAdmin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PanelAdminScreen()),
    );
  }

  Future<void> _abrirTodosMovimientos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MisMovimientosScreen()),
    );
  }

  Future<void> _confirmarDesactivar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CuentaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desactivar mi cuenta', style: TextStyle(color: CuentaColors.textPrimary)),
        content: const Text(
          'Tu cuenta quedará desactivada de inmediato y se eliminará de forma '
          'PERMANENTE en 30 días si no la reactivas antes (contactando soporte: '
          'proyectofinanzassena@gmail.com).\n\n¿Deseas continuar?',
          style: TextStyle(color: CuentaColors.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: CuentaColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, desactivar', style: TextStyle(color: CuentaColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    await _desactivarCuenta();
  }

  Future<void> _desactivarCuenta() async {
    setState(() => _desactivando = true);
    try {
      final mensaje = await CuentaService.instance.desactivarCuentaPropia();
      if (!mounted) return;

      // Mostramos el mensaje del backend (incluye la fecha límite de
      // eliminación) y solo al cerrar el diálogo cerramos sesión,
      // igual que en la web: el backend ya bloquea el login de
      // cuentas inactivas, así que no tiene sentido mantener sesión.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: CuentaColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cuenta desactivada', style: TextStyle(color: CuentaColors.textPrimary)),
          content: Text(mensaje, style: const TextStyle(color: CuentaColors.textSecondary, fontSize: 13.5, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido', style: TextStyle(color: CuentaColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: CuentaColors.danger),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar la cuenta'), backgroundColor: CuentaColors.danger),
      );
    } finally {
      if (mounted) setState(() => _desactivando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuentaColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: CuentaColors.accent,
          onRefresh: () async {
            await _cargarUsuario();
            setState(() {
              _futureMovimientos = CuentaService.instance.getMovimientos();
            });
            await _futureMovimientos;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const Text(
                'Mi cuenta',
                style: TextStyle(color: CuentaColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _buildPerfilHeader(),
              const SizedBox(height: 20),
              if (_puedeVerPanelAdmin) ...[
                _buildBannerPanelAdmin(),
                const SizedBox(height: 20),
              ],
              _buildMovimientosResumen(),
              const SizedBox(height: 20),
              SeccionCard(
                title: 'Cuenta',
                children: [
                  SeccionTile(
                    icon: Icons.person_outline,
                    title: 'Editar mis datos',
                    subtitle: 'Nombre, apellido y correo',
                    onTap: _abrirEditarPerfil,
                  ),
                  SeccionTile(
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    onTap: _abrirCambiarPassword,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SeccionCard(
                title: 'Zona de peligro',
                children: [
                  SeccionTile(
                    icon: Icons.person_off_outlined,
                    title: 'Desactivar mi cuenta',
                    subtitle: 'Se elimina de forma permanente en 30 días',
                    destructive: true,
                    trailing: _desactivando
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: CuentaColors.danger),
                          )
                        : null,
                    onTap: _desactivando ? null : _confirmarDesactivar,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '© 2026 Ahorrapp',
                  style: TextStyle(color: CuentaColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilHeader() {
    if (_cargandoUsuario) {
      return const SizedBox(
        height: 76,
        child: Center(child: CircularProgressIndicator(color: CuentaColors.accent, strokeWidth: 2)),
      );
    }

    final nombreCompleto = '${_usuario?.nombre ?? ''} ${_usuario?.apellido ?? ''}'.trim();
    final rolPrincipal = _tieneRol('superuser')
        ? 'Superusuario'
        : _tieneRol('admin')
            ? 'Administrador'
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuentaColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CuentaColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CuentaColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: CuentaColors.accent.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                _iniciales.isEmpty ? '?' : _iniciales,
                style: const TextStyle(color: CuentaColors.accent, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
                  style: const TextStyle(color: CuentaColors.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _usuario?.email ?? '',
                  style: const TextStyle(color: CuentaColors.textMuted, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (rolPrincipal != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CuentaColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rolPrincipal,
                      style: const TextStyle(color: CuentaColors.accent, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPanelAdmin() {
    return InkWell(
      onTap: _abrirPanelAdmin,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CuentaColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CuentaColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: CuentaColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_outlined, color: CuentaColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel de administración',
                      style: TextStyle(color: CuentaColors.accent, fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Usuarios y dependientes del sistema',
                      style: TextStyle(color: CuentaColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: CuentaColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientosResumen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'MIS MOVIMIENTOS',
                  style: TextStyle(color: CuentaColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              GestureDetector(
                onTap: _abrirTodosMovimientos,
                child: const Text(
                  'Ver todos',
                  style: TextStyle(color: CuentaColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CuentaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CuentaColors.border),
          ),
          child: FutureBuilder<List<Movimiento>>(
            future: _futureMovimientos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: CuentaColors.accent, strokeWidth: 2)),
                );
              }

              final movimientos = snapshot.data ?? [];
              if (movimientos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                  child: Text(
                    'Todavía no tienes movimientos registrados.',
                    style: TextStyle(color: CuentaColors.textMuted, fontSize: 13),
                  ),
                );
              }

              final visibles = movimientos.take(_maxMovimientosResumen).toList();
              return Column(
                children: [
                  for (int i = 0; i < visibles.length; i++) ...[
                    MovimientoTile(movimiento: visibles[i]),
                    if (i != visibles.length - 1)
                      const Divider(height: 1, color: CuentaColors.border),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
