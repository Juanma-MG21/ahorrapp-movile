import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final mensaje = await AuthService.instance.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      
      // En un flujo real de Render, aquí podrías navegar a una pantalla de "Ingresar Código"
      // o simplemente avisar al usuario. Por ahora, regresamos al login para que use el enlace.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          _buildTopBar(context),
          const SizedBox(height: 40),
          const Icon(Icons.lock_outline_rounded, color: AppColors.blue, size: 60),
          const SizedBox(height: 30),
          const Text('¿Olvidaste tu contraseña?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Ingresa tu correo y te enviaremos las instrucciones para recuperarla', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 40),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'CORREO ELECTRÓNICO', suffixIcon: Icon(Icons.mail_rounded, size: 20)),
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Ingresa tu correo';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'Email inválido';
                return null;
              },
            ),
          ),
          const SizedBox(height: 30),
          PrimaryAuthButton(label: 'Enviar instrucciones', isLoading: _isLoading, onPressed: _submit),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al Inicio de Sesión', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
          ),
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
}
