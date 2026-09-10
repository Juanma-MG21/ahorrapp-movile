import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/auth_widgets.dart';

class FastLoginScreen extends StatefulWidget {
  const FastLoginScreen({super.key});

  @override
  State<FastLoginScreen> createState() => _FastLoginScreenState();
}

class _FastLoginScreenState extends State<FastLoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _tryBiometricImmediately();
  }

  Future<void> _tryBiometricImmediately() async {
    final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (canAuthenticate) {
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Inicia sesión rápidamente',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (authenticated && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Text('AhorrApp', style: TextStyle(color: AppColors.accent, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 50),
          _buildAvatar(),
          const SizedBox(height: 20),
          const Text('¡Bienvenido de vuelta!', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Manuel Guevara', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AccessBtn(icon: Icons.fingerprint_rounded, label: "Huella", onTap: () => Navigator.of(context).pushNamed('/biometric-access')),
            ],
          ),
          const SizedBox(height: 80),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text('Usar otra cuenta', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: AppColors.surface, shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
    );
  }
}

class _AccessBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AccessBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(4, 4), blurRadius: 10)],
            ),
            child: Icon(icon, color: AppColors.accent, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
