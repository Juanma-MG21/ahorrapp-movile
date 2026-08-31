import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/auth_widgets.dart';
import '../../services/auth_service.dart';
import 'auth_gate.dart';

class BiometricAccessScreen extends StatefulWidget {
  const BiometricAccessScreen({super.key});

  @override
  State<BiometricAccessScreen> createState() => _BiometricAccessScreenState();
}

class _BiometricAccessScreenState extends State<BiometricAccessScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Esperando autenticación...';

  @override
  void initState() {
    super.initState();
    // Iniciar autenticación automáticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Escaneando huella/rostro...';
      });

      authenticated = await auth.authenticate(
        localizedReason: 'Escanea tu huella para acceder a AhorrApp',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
        _authStatus = authenticated ? 'Acceso concedido' : 'Acceso denegado';
      });

      if (authenticated && mounted) {
        // La huella es correcta, pero eso solo confirma que es el dueño
        // del dispositivo. Antes de dejarlo entrar, confirmamos que
        // sigue habiendo una sesión guardada y válida en AuthService.
        final tieneSesion = await AuthService.instance.hasSession();

        if (!mounted) return;

        if (tieneSesion) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Bienvenido!')),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // No hay sesión válida (por ejemplo, expiró). Mandamos a
          // AuthGate para que decida qué pantalla mostrar (login, etc.)
          // en vez de forzar '/home' sin sesión real.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu sesión expiró, inicia sesión nuevamente'),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error al autenticar: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: _isAuthenticating ? null : _authenticate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAuthenticating
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surface,
                border: Border.all(
                  color: _isAuthenticating ? AppColors.accent : AppColors.borderLight,
                  width: 2,
                ),
                boxShadow: _isAuthenticating
                    ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
                    : [],
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: 100,
                color: _isAuthenticating ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _authStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (!_isAuthenticating)
            TextButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Usar contraseña',
              style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}