import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import 'login_screen.dart';

/// Al abrir la app: si hay una sesión guardada (token en disco), entra
/// directo a MainScreen. Si no, muestra LoginScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _hasSession;

  @override
  void initState() {
    super.initState();
    _hasSession = AuthService.instance.hasSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final loggedIn = snapshot.data ?? false;
        return loggedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }
}