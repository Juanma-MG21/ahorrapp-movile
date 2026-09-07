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
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 50),
          
          // Avatar del usuario
          Container(
            width: 90,
            height: 90,
            decoration: clayRaised(radius: 100),
            child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
          ),
          
          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido de vuelta!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            userName,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            userEmail,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
          
          const SizedBox(height: 60),
          
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text(
              'Usar otra cuenta',
              style: TextStyle(
                color: AppColors.accent,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 75,
            height: 75,
            decoration: clayRaised(radius: 16),
            child: Icon(icon, color: AppColors.accent, size: 34),
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
