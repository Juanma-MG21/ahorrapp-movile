import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AhorrApp - Inicio'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.accent),
            label: const Text(
              'Salir',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: clayRaised(radius: AppRadius.lg),
              child: const SizedBox(
                width: 112,
                height: 112,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 56,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '¡Bienvenido a AhorrApp!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestión financiera al alcance de tu mano',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
