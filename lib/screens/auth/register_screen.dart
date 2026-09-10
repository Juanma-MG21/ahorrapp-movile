import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
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
        nombre: '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso. Ya puedes iniciar sesión.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la cuenta: $error'), backgroundColor: AppColors.error),
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
          const SizedBox(height: 20),
          const Text('AhorrApp', textAlign: TextAlign.center, style: TextStyle(color: AppColors.accent, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Crea tu cuenta', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const Text('Comienza a gestionar tus finanzas', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 30),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(controller: _nombreController, label: 'NOMBRE', hint: 'Sofía', icon: Icons.person_rounded),
                const SizedBox(height: 16),
                _buildField(controller: _apellidoController, label: 'APELLIDO', hint: 'Párraga', icon: Icons.person_outline_rounded),
                const SizedBox(height: 16),
                _buildField(controller: _emailController, label: 'CORREO ELECTRÓNICO', hint: 'sofi@gmail.com', icon: Icons.mail_rounded, type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'CONTRASEÑA',
                  hide: _hidePassword,
                  onToggle: () => setState(() => _hidePassword = !_hidePassword),
                ),
                const SizedBox(height: 8),
                _StrengthMeter(value: _passwordStrength, label: _passwordStrengthText, color: _passwordStrengthColor),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'CONFIRMAR CONTRASEÑA',
                  hide: _hideConfirmPassword,
                  onToggle: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                  isConfirm: true,
                ),
                const SizedBox(height: 30),
                PrimaryAuthButton(label: 'Crear cuenta', isLoading: _isLoading, onPressed: _submit),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
          style: IconButton.styleFrom(backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: Icon(icon, size: 20, color: AppColors.accent)),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) return 'Este campo es obligatorio';
        if (type == TextInputType.emailAddress && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'Email inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String label, required bool hide, required VoidCallback onToggle, bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(onPressed: onToggle, icon: Icon(hide ? Icons.lock_rounded : Icons.lock_open_rounded, size: 20, color: AppColors.accent)),
      ),
      validator: (value) {
        if ((value ?? '').isEmpty) return 'Ingresa tu contraseña';
        if (!isConfirm && value!.length < 8) return 'Mínimo 8 caracteres';
        if (isConfirm && value != _passwordController.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _StrengthMeter({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: value == 0 ? 0.05 : value, minHeight: 4, color: color, backgroundColor: AppColors.inset),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onLogin;
  const _Footer({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        GestureDetector(
          onTap: onLogin,
          child: const Text('Iniciar sesion', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
