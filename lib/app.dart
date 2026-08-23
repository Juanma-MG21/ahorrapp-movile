import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';

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
      },
    );
  }
}
