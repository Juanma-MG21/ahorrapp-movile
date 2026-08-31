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
        _isLoading = false;
        _email = email;
        _step = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
      setState(() => _isLoading = false);
      Navigator.of(context).pushNamed('/reset-password', arguments: resetToken);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
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
                'Recuperar acceso',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Icon(
            _step == 0 ? Icons.alternate_email_rounded : Icons.pin_rounded,
            color: AppColors.blue,
            size: 44,
          ),
          const SizedBox(height: 28),
          Text(
            _step == 0 ? 'Olvidaste tu contrasena?' : 'Revisa tu correo',
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
            style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
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
              labelText: 'CORREO ELECTRONICO',
              suffixIcon: Icon(Icons.mail_rounded, color: Color(0xFFC6B0D8)),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Ingresa tu correo';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Ingresa un correo valido';
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
            foregroundColor: const Color(0xFFB9C7E1),
            side: const BorderSide(color: Color(0xFF2A2640)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: const Color(0xFF151222),
          ),
          child: const Text(
            'Volver al inicio de sesion',
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
              suffixIcon: Icon(Icons.pin_rounded, color: Color(0xFFC6B0D8)),
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