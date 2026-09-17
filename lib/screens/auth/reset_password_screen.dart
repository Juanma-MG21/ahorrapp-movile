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
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    final email = arguments is Map ? arguments['email'] as String? : null;
    final resetToken = arguments is String ? arguments :
        arguments is Map ? arguments['resetToken'] as String? : null;

    if ((email == null || email.isEmpty) && (resetToken == null || resetToken.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró la información de recuperación. Solicítala de nuevo.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String resolvedToken = resetToken ?? '';

      if (resolvedToken.isEmpty) {
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          throw ApiException('Ingresa el código que recibiste por correo.');
        }

        resolvedToken = await AuthService.instance.verifyResetCode(
          email: email!,
          code: code,
        );
      }

      if (resolvedToken.isEmpty) {
        throw ApiException(
          'El código o enlace de recuperación no es válido. Inténtalo de nuevo.',
        );
      }

      await AuthService.instance.resetPassword(
        resetToken: resolvedToken,
        nuevaPassword: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contrasena actualizada con exito')),
      );

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
                  backgroundColor: AppColors.surfaceAlt,
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
                if (ModalRoute.of(context)?.settings.arguments is Map &&
                    (ModalRoute.of(context)?.settings.arguments as Map)['resetToken'] == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'CÓDIGO DE VERIFICACIÓN',
                        suffixIcon: Icon(Icons.confirmation_number_rounded, size: 20),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Ingresa el código recibido';
                        }
                        return null;
                      },
                    ),
                  ),
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
                        color: AppColors.textMuted,
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
                        color: AppColors.textMuted,
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