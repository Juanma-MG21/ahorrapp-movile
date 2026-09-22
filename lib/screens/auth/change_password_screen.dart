import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'auth_gate.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Si la sesión ya no es válida, no tiene sentido pedir el PIN ni
    // intentar el cambio de contraseña: avisamos y mandamos al usuario
    // de vuelta a AuthGate, igual que en el flujo biométrico.
    final hasSession = await AuthService.instance.hasSession();
    if (!mounted) return;

    if (!hasSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión expiró, inicia sesión nuevamente'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    }

    final confirmed = await Navigator.of(context).pushNamed('/pin-access');
    if (!mounted || confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.changePassword(
        passwordActual: _currentPasswordController.text,
        passwordNueva: _newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cambiar la contraseña'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const Icon(Icons.lock_reset_rounded, color: AppColors.accent, size: 52),
          const SizedBox(height: 18),
          const Text(
            'Cambiar contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Antes de guardar, confirma la acción con tu PIN',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 30),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _passwordField(
                  controller: _currentPasswordController,
                  label: 'CONTRASEÑA ACTUAL',
                  hidden: _hideCurrent,
                  onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                  validator: (value) => (value ?? '').isEmpty
                      ? 'Ingresa tu contraseña actual'
                      : null,
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _newPasswordController,
                  label: 'NUEVA CONTRASEÑA',
                  hidden: _hideNew,
                  onToggle: () => setState(() => _hideNew = !_hideNew),
                  validator: (value) => (value ?? '').length < 8
                      ? 'Mínimo 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _confirmPasswordController,
                  label: 'CONFIRMAR CONTRASEÑA',
                  hidden: _hideConfirm,
                  onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                  validator: (value) => value != _newPasswordController.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryAuthButton(
            label: 'Continuar con PIN',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
          ),
        ),
      ),
      validator: validator,
    );
  }
}