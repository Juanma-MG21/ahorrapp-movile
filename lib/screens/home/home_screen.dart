import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AhorrApp - Inicio'),
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 80, color: AppColors.accent),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido a AhorrApp!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Gestión financiera al alcance de tu mano',
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}