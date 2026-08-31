import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/biometric_access_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/pin_access_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/main_screen.dart';

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AhorrApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/biometric-access': (context) => const BiometricAccessScreen(),
        '/pin-access': (context) => const PinAccessScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}