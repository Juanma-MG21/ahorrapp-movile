import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/presupuesto_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/pin_access_screen.dart';
import 'screens/auth/biometric_access_screen.dart';
import 'screens/auth/fast_login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/gastos/modulo_gastos.dart';

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Se crea una sola vez y vive mientras la app esté abierta.
        // Si en el futuro quieres que se recargue justo al hacer login
        // (para no arrastrar datos de una sesión anterior), muévelo a
        // un ChangeNotifierProvider más abajo en el árbol (ej. dentro
        // de MainScreen) o llama a provider.cargar() de nuevo tras el
        // login.
        ChangeNotifierProvider(create: (_) => PresupuestoProvider()),
      ],
      child: MaterialApp(
        title: 'AhorrApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const AuthGate(),
        routes: {
          '/home': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/biometric-access': (context) => const BiometricAccessScreen(),
          '/pin-access': (context) => const PinAccessScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/fast-login': (context) => const FastLoginScreen(),
          '/gastos': (context) => const ModuloGastos(),
        },
      ),
    );
  }
}