import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberSession = false;
  bool _hidePassword = true;
  bool _isLoading = false;

  // Gate para el acceso rápido por huella: viene de
  // AuthService.canUseBiometricAccess(), que ya valida sesión guardada
  // y soporte del dispositivo (si no, mandaría a un callejón sin salida
  // en BiometricAccessScreen).
  // Nota: '/pin-access' no vive aquí — es una segunda verificación
  // para acciones sensibles (cambiar contraseña, editar datos
  // personales), no un método de login rápido.
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberSession = prefs.getBool('remember_me') ?? false;
      if (_rememberSession) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });

    // Decisión de equipo: el chequeo de hardware biométrico ahora vive
    // centralizado en AuthService.canUseBiometricAccess(), para que
    // cualquier pantalla (incluida BiometricAccessScreen) use la misma
    // regla sin duplicar lógica.
    final canUseBiometric = await AuthService.instance.canUseBiometricAccess();

    if (!mounted) return;
    setState(() {
      _canUseBiometric = canUseBiometric;
    });
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberSession) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberSession: _rememberSession,
      );

      await _handleRememberMe();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Bienvenido de nuevo!')));
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegister() => Navigator.of(context).pushNamed('/register');

  void _openForgotPassword() =>
      Navigator.of(context).pushNamed('/forgot-password');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(27, 14, 27, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 34),
                    _buildBrandHeader(),
                    const SizedBox(height: 36),
                    _buildLoginForm(),
                    const SizedBox(height: 25),
                    _buildQuickAccess(),
                    const SizedBox(height: 27),
                    _RegisterCallout(onTap: _openRegister),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return const Column(
      children: [
        Text(
          'AhorrApp',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Gestión financiera personal',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 34),
        Text(
          'Bienvenido de vuelta',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Inicia sesión para continuar',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInputShell(
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'CORREO ELECTRÓNICO',
                suffixIcon: Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.textMuted,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Ingresa tu correo';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(email)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 22),
          AuthInputShell(
            child: TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'CONTRASEÑA',
                hintText: '********',
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Mostrar' : 'Ocultar',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Ingresa tu contraseña' : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _rememberSession,
                onChanged: (v) => setState(() => _rememberSession = v ?? false),
                activeColor: AppColors.accent,
                checkColor: AppColors.background,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Recordar sesión',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryAuthButton(
            label: 'Iniciar sesión',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      children: [
        const Text(
          'O CONTINÚA CON',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _AccessTile(
                icon: Icons.fingerprint_rounded,
                label: 'Huella',
                onTap: () => Navigator.of(context).pushNamed(
                  _canUseBiometric ? '/biometric-access' : '/fast-login',
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _AccessTile(
                icon: Icons.lock_outline_rounded,
                label: 'PIN',
                badge: '123',
                onTap: () => Navigator.of(context).pushNamed('/fast-login'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: clayRaised(radius: AppRadius.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: AppColors.accent, size: 23),
                    if (badge != null)
                      Positioned(
                        left: 25,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterCallout extends StatelessWidget {
  const _RegisterCallout({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No tienes cuenta? ',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Regístrate',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
