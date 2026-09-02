import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // El resetToken llega como argumento de ruta desde
    // forgot_password_screen.dart (Navigator.pushNamed con arguments).
    final resetToken = ModalRoute.of(context)?.settings.arguments as String?;

    if (resetToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de recuperación no es válido. Solicítalo de nuevo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.resetPassword(
        resetToken: resetToken,
        nuevaPassword: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrasena actualizada con exito')),
      );

      // Volver al login despues de cambiar la clave
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF12213C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nueva contrasena',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.accent,
            size: 44,
          ),
          const SizedBox(height: 28),
          const Text(
            'Crea una nueva clave',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Asegurate de usar una clave segura que no hayas usado antes',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 26),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'NUEVA CONTRASENA',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF52627B),
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 8) return 'Minimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'CONFIRMAR CONTRASENA',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                      icon: Icon(
                        _hideConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF52627B),
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'No coincide';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryAuthButton(
            label: 'Actualizar contrasena',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}