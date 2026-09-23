import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/pin_access_screen.dart';
import '../auth/biometric_access_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cargando = true;
  bool _pinConfigurado = false;
  bool _biometriaActivada = false;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final pin = await AuthService.instance.hasPinSet();
    final bio = await AuthService.instance.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _pinConfigurado = pin;
      _biometriaActivada = bio;
      _cargando = false;
    });
  }

  Future<void> _abrirGestionPin() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinAccessScreen(mode: PinAccessMode.manage),
      ),
    );
    _cargarEstado();
  }

  Future<void> _abrirGestionBiometria() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BiometricAccessScreen(mode: BiometricAccessMode.manage),
      ),
    );
    _cargarEstado();
  }

  Future<void> _cerrarSesion() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AhorrApp'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppColors.accent),
                const SizedBox(height: 14),
                const Text(
                  '¡Bienvenido a AhorrApp!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gestión financiera al alcance de tu mano',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 28),
                const Text(
                  'SEGURIDAD',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTarjetaSeguridad(
                  icon: Icons.pin_rounded,
                  titulo: 'PIN',
                  subtitulo: _pinConfigurado
                      ? 'Configurado — se usa para confirmar cambios en tu cuenta'
                      : 'No configurado',
                  configurado: _pinConfigurado,
                  onTap: _abrirGestionPin,
                ),
                const SizedBox(height: 12),
                _buildTarjetaSeguridad(
                  icon: Icons.fingerprint_rounded,
                  titulo: 'Biometría',
                  subtitulo: _biometriaActivada
                      ? 'Activada — puedes usarla como alternativa al PIN'
                      : 'No activada',
                  configurado: _biometriaActivada,
                  onTap: _abrirGestionBiometria,
                ),
              ],
            ),
    );
  }

  Widget _buildTarjetaSeguridad({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required bool configurado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: clayRaised(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (configurado ? AppColors.success : AppColors.accent).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: configurado ? AppColors.success : AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Text(
              configurado ? 'Editar' : 'Configurar',
              style: const TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
