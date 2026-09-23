import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Modo en el que se abre [BiometricAccessScreen]:
///  - [manage]: se usa desde Inicio para activar o desactivar la
///    biometría de la cuenta.
///  - [confirm]: segunda verificación (alternativa al PIN) para
///    confirmar una acción sensible sobre una sesión ya autenticada.
enum BiometricAccessMode { manage, confirm }

/// Ya NO es una pantalla de "login rápido": nunca navega a '/home'.
/// Siempre resuelve con Navigator.pop(true/false), igual que
/// PinAccessScreen.
class BiometricAccessScreen extends StatefulWidget {
  const BiometricAccessScreen({
    super.key,
    this.mode = BiometricAccessMode.manage,
  });

  final BiometricAccessMode mode;

  @override
  State<BiometricAccessScreen> createState() => _BiometricAccessScreenState();
}

class _BiometricAccessScreenState extends State<BiometricAccessScreen> {
  bool _isAuthenticating = false;
  bool _isConfiguring = false;
  bool _yaActivada = false;
  String _authStatus = 'Cargando...';

  bool get _esGestion => widget.mode == BiometricAccessMode.manage;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    if (!await AuthService.instance.hasSession()) {
      if (!mounted) return;
      setState(() => _authStatus = 'Inicia sesión con tu correo y contraseña');
      return;
    }

    final activada = await AuthService.instance.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _yaActivada = activada;
      if (_esGestion) {
        _authStatus = activada
            ? 'La biometría ya está activada en esta cuenta'
            : 'Activa la biometría para esta cuenta';
      } else {
        _authStatus = 'Confirma la acción con tu huella';
      }
    });

    // En modo confirmación vamos directo al prompt biométrico, ya que
    // solo se llega aquí cuando la biometría ya está activada.
    if (!_esGestion) {
      _autenticar();
    }
  }

  Future<void> _autenticar() async {
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

      final autenticado = await AuthService.instance.authenticateBiometric();

      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _authStatus = autenticado ? 'Identidad confirmada' : 'Autenticación fallida';
      });

      if (autenticado) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _authStatus = 'Error: $e';
      });
    }
  }

  Future<void> _activar() async {
    setState(() {
      _isAuthenticating = true;
      _isConfiguring = true;
      _authStatus = 'Confirma tu identidad para activar la biometría...';
    });

    try {
      await AuthService.instance.configureBiometrics();
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _isConfiguring = false;
        _yaActivada = true;
        _authStatus = 'Biometría activada';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometría activada correctamente')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _isConfiguring = false;
        _authStatus = error.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _isConfiguring = false;
        _authStatus = 'Error: $e';
      });
    }
  }

  Future<void> _desactivar() async {
    await AuthService.instance.disableBiometrics();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometría desactivada')),
    );
    Navigator.of(context).pop(true);
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
          if (_esGestion && !_isAuthenticating && !_isConfiguring) ...[
            if (!_yaActivada)
              ElevatedButton.icon(
                onPressed: _activar,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Activar biometría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                ),
              )
            else
              TextButton.icon(
                onPressed: _desactivar,
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.error),
                label: const Text(
                  'Desactivar biometría',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
          if (!_esGestion && !_isAuthenticating)
            TextButton.icon(
              onPressed: _autenticar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
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
          onPressed: () => Navigator.of(context).pop(false),
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
      onTap: (_isAuthenticating || _isConfiguring)
          ? null
          : (_esGestion ? null : _autenticar),
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
