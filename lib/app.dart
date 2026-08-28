import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/pin_access_screen.dart';
import 'screens/auth/biometric_access_screen.dart';
import 'screens/auth/fast_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/gastos/modulo_gastos.dart';

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AhorrApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/pin-access': (context) => const PinAccessScreen(),
        '/biometric-access': (context) => const BiometricAccessScreen(),
        '/fast-login': (context) => const FastLoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/gastos': (context) => const ModuloGastos(),
      },
    );
  }
}
