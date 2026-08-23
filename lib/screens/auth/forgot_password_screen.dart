import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'ma***@gmail.com');

  bool _isLoading = false;
  bool _emailDetected = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace de recuperacion listo')),
    );
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
                  color: AppTheme.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Icon(
            Icons.alternate_email_rounded,
            color: AppTheme.blue,
            size: 44,
          ),
          const SizedBox(height: 28),
          const Text(
            'Olvidaste tu contrasena?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Te enviaremos un enlace de recuperacion a tu correo registrado',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 22),
          const _ProgressDots(),
          const SizedBox(height: 26),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _emailDetected = value.trim().contains('@');
                });
              },
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
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _emailDetected
                ? const _DetectedEmailBanner()
                : const _SearchEmailBanner(),
          ),
          const SizedBox(height: 16),
          PrimaryAuthButton(
            label: 'Enviar enlace de recuperacion',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reenvio listo para conectar')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.blue),
            child: const Text(
              'Reenviar en 60 segundos',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
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
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == 0;
        return Container(
          width: active ? 18 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppTheme.amber : const Color(0xFF334057),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _DetectedEmailBanner extends StatelessWidget {
  const _DetectedEmailBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('detected'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF0E312B),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF1D5C50)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_box_rounded, color: Color(0xFF34D399), size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correo detectado',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Encontramos una cuenta asociada a este correo',
                  style: TextStyle(color: Color(0xFFB9E7DC), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmailBanner extends StatelessWidget {
  const _SearchEmailBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('searching'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151222),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF2A2640)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppTheme.muted, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Escribe tu correo registrado para buscar la cuenta',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
