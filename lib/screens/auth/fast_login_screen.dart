import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';

class FastLoginScreen extends StatelessWidget {
  const FastLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulamos un usuario que ya ha iniciado sesión antes
    const String userName = "Manuel Guevara";
    const String userEmail = "ma***@gmail.com";

    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppTheme.amber,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 50),
          
          // Avatar del usuario
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppTheme.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
          ),
          
          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido de vuelta!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            userName,
            style: TextStyle(
              color: AppTheme.amber,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            userEmail,
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          
          const SizedBox(height: 60),
          
          // Botones de acceso rápido
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FastAccessButton(
                icon: Icons.fingerprint_rounded,
                label: "Huella",
                onTap: () => Navigator.of(context).pushNamed('/biometric-access'),
              ),
              const SizedBox(width: 30),
              _FastAccessButton(
                icon: Icons.pin_rounded,
                label: "PIN",
                onTap: () => Navigator.of(context).pushNamed('/pin-access'),
              ),
            ],
          ),
          
          const Spacer(),
          
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text(
              'Usar otra cuenta',
              style: TextStyle(
                color: AppTheme.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FastAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FastAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.amber, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
