import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class BiometricAccessScreen extends StatefulWidget {
  const BiometricAccessScreen({super.key});

  @override
  State<BiometricAccessScreen> createState() => _BiometricAccessScreenState();
}

class _BiometricAccessScreenState extends State<BiometricAccessScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authStatus = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _startBiometric();
  }

  Future<void> _startBiometric() async {
    if (!await AuthService.instance.hasSession()) {
      if (!mounted) return;
      setState(() => _authStatus = 'Inicia sesión con tu correo y contraseña');
      return;
    }

    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      setState(
        () => _authStatus = 'Biometría no soportada en este dispositivo',
      );
      return;
    }

    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      if (!await AuthService.instance.hasSession()) {
        if (mounted) {
          setState(() => _authStatus = 'Tu sesión ya no está disponible');
        }
        return;
      }

      setState(() {
        _isAuthenticating = true;
        _authStatus = 'Escaneando huella / rostro...';
      });

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Accede de forma segura a AhorrApp',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
        _authStatus = authenticated
            ? 'Acceso concedido'
            : 'Autenticación fallida';
      });

      if (authenticated && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTopBar(context),
          const SizedBox(height: 50),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 80),
          _buildBiometricIcon(),
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
          const SizedBox(height: 30),
          if (!_isAuthenticating)
            TextButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          const SizedBox(height: 80),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Ingresar con contraseña',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricIcon() {
    return GestureDetector(
      onTap: _isAuthenticating ? null : _authenticate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(35),
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
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Icon(
          Icons.fingerprint_rounded,
          size: 100,
          color: _isAuthenticating ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}
