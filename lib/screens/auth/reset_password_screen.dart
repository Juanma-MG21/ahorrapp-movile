import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

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

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contrasena actualizada con exito')),
    );
    
    // Volver al login despues de cambiar la clave
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                  color: AppTheme.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Icon(
            Icons.lock_reset_rounded,
            color: AppTheme.amber,
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
            style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.4),
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
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
