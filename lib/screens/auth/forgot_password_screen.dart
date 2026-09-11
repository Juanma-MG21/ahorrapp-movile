import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  // 0 = pidiendo correo, 1 = pidiendo código de verificación
  int _step = 0;
  bool _isLoading = false;
  String? _email; // guardado tras el paso 1, para usarlo en verifyResetCode

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      final mensaje = await AuthService.instance.forgotPassword(email: email);

      if (!mounted) return;

      setState(() {
        _email = email;
        _step = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el código: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarCodigo() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final resetToken = await AuthService.instance.verifyResetCode(
        email: _email!,
        code: _codeController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamed(
        '/reset-password',
        arguments: resetToken,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo verificar el código: $e'),
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
          const SizedBox(height: 34),
          Icon(
            _step == 0 ? Icons.alternate_email_rounded : Icons.pin_rounded,
            color: AppColors.blue,
            size: 44,
          ),
          const SizedBox(height: 28),
          Text(
            _step == 0 ? '¿Olvidaste tu contraseña?' : 'Revisa tu correo',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _step == 0
                ? 'Te enviaremos un código de recuperación a tu correo registrado'
                : 'Ingresa el código de 6 dígitos que enviamos a $_email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          _ProgressDots(step: _step),
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _step == 0 ? _buildEmailStep() : _buildCodeStep(),
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
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Recuperar acceso',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _emailFormKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'CORREO ELECTRÓNICO',
              suffixIcon: Icon(Icons.mail_rounded, color: AppColors.textMuted),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) return 'Ingresa tu correo';

              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                return 'Ingresa un correo válido';
              }

              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        PrimaryAuthButton(
          label: 'Enviar código de recuperación',
          isLoading: _isLoading,
          onPressed: _enviarCodigo,
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: AppColors.surfaceAlt,
          ),
          child: const Text(
            'Volver al inicio de sesión',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('code-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _codeFormKey,
          child: TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'CÓDIGO DE VERIFICACIÓN',
              suffixIcon: Icon(Icons.pin_rounded, color: AppColors.textMuted),
            ),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (code.isEmpty) return 'Ingresa el código';
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        PrimaryAuthButton(
          label: 'Verificar código',
          isLoading: _isLoading,
          onPressed: _verificarCodigo,
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _isLoading ? null : _enviarCodigo,
          style: TextButton.styleFrom(foregroundColor: AppColors.blue),
          child: const Text(
            'Reenviar código',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _step = 0),
          child: const Text(
            'Corregir correo',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == step;

        return Container(
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : const Color(0xFF334057),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}