import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  double get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score / 4;
  }

  String get _passwordStrengthText {
    final strength = _passwordStrength;
    if (strength == 0) return 'Seguridad';
    if (strength <= 0.5) return 'Seguridad baja';
    if (strength < 1) return 'Seguridad media';
    return 'Seguridad alta';
  }

  Color get _passwordStrengthColor {
    final strength = _passwordStrength;
    if (strength <= 0.5) return AppColors.error;
    if (strength < 1) return AppColors.accent;
    return AppColors.success;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Ya puedes iniciar sesión.'),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la cuenta'),
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
          _buildTopBar(context),
          const SizedBox(height: 24),
          const Text(
            'AhorrApp',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accent, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          const Text(
            'Crea tu cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'Comienza a gestionar tus finanzas',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  controller: _nombreController,
                  label: 'NOMBRE',
                  hint: 'Manuel',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _apellidoController,
                  label: 'APELLIDO',
                  hint: 'Guevara',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'CORREO ELECTRÓNICO',
                  hint: 'correo@ejemplo.com',
                  icon: Icons.mail_rounded,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'CONTRASEÑA',
                  hide: _hidePassword,
                  onToggle: () => setState(() => _hidePassword = !_hidePassword),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _StrengthMeter(
                  value: _passwordStrength,
                  label: _passwordStrengthText,
                  color: _passwordStrengthColor,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'CONFIRMAR CONTRASEÑA',
                  hide: _hideConfirmPassword,
                  onToggle: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                  isConfirm: true,
                ),
                const SizedBox(height: 24),
                PrimaryAuthButton(label: 'Crear cuenta', isLoading: _isLoading, onPressed: _submit),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Footer(onLogin: () => Navigator.of(context).pop()),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      textCapitalization: type == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      autocorrect: type != TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(icon, size: 20, color: AppColors.accent),
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Este campo es obligatorio';
        if (type == TextInputType.emailAddress &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool hide,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: hide,
      textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: hide ? 'Mostrar' : 'Ocultar',
          onPressed: onToggle,
          icon: Icon(
            hide ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 20,
            color: AppColors.accent,
          ),
        ),
      ),
      validator: (value) {
        final v = value ?? '';
        if (v.isEmpty) return 'Ingresa tu contraseña';
        if (!isConfirm && v.length < 8) return 'Usa al menos 8 caracteres';
        if (isConfirm && v != _passwordController.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.value, required this.label, required this.color});

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value == 0 ? 0.08 : value,
            minHeight: 4,
            color: color,
            backgroundColor: const Color(0xFF232A3B),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? ', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Iniciar sesión', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}