import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
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
  final _localAuth = LocalAuthentication();

  bool _rememberSession = false;
  bool _hidePassword = true;
  bool _isLoading = false;

  // Gate para el acceso rápido por huella: solo tiene sentido ofrecerlo
  // si hay una sesión guardada que restaurar (si no, manda a un
  // callejón sin salida en BiometricAccessScreen).
  // Nota: '/pin-access' ya no vive aquí — es una segunda verificación
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

    // AuthService no expone (ni debería) chequeos de hardware biométrico;
    // eso es responsabilidad de la UI, igual que en BiometricAccessScreen.
    final hasSession = await AuthService.instance.hasSession();
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!mounted) return;
    setState(() {
      _canUseBiometric = hasSession && canCheck && isSupported;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido de nuevo!')),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Necesitas ayuda?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Si tienes problemas para entrar, contacta a soporte o usa la opción de recuperar contraseña.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openForgotPassword();
            },
            child: const Text('Recuperar contraseña'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          const SizedBox(height: 26),
          _buildBrandHeader(),
          const SizedBox(height: 32),
          _buildLoginForm(),
          if (_canUseBiometric) ...[
            const SizedBox(height: 24),
            _buildQuickAccess(),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/fast-login'),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Acceso rápido'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          _RegisterCallout(onTap: _openRegister),
          const SizedBox(height: 12),
          _BottomAccessNav(onRegister: _openRegister, onHelp: _showHelpDialog),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return const Column(
      children: [
        Text(
          'AhorrApp',
          style: TextStyle(color: AppColors.accent, fontSize: 34, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 5),
        Text(
          'Gestión financiera personal',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 24),
        Text(
          'Bienvenido de vuelta',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 6),
        Text('Inicia sesión para continuar', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'CONTRASEÑA',
              hintText: '********',
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Mostrar' : 'Ocultar',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ),
            validator: (value) => (value ?? '').isEmpty ? 'Ingresa tu contraseña' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _rememberSession,
                onChanged: (v) => setState(() => _rememberSession = v ?? false),
                activeColor: AppColors.accent,
                checkColor: AppColors.background,
                visualDensity: VisualDensity.compact,
              ),
              const Text('Recordar sesión', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: _openForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blue,
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
          const SizedBox(height: 14),
          PrimaryAuthButton(label: 'Iniciar sesión', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderLight)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('o continúa con', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),
            Expanded(child: Divider(color: AppColors.borderLight)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _AccessTile(
                icon: Icons.fingerprint_rounded,
                label: 'Huella',
                onTap: () => Navigator.of(context).pushNamed('/biometric-access'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accent, size: 24),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
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
        const Text('¿No tienes cuenta? ', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Regístrate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _BottomAccessNav extends StatelessWidget {
  const _BottomAccessNav({required this.onRegister, required this.onHelp});

  final VoidCallback onRegister;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _BottomNavItem(icon: Icons.key_rounded, label: 'Acceso', selected: true),
          _BottomNavButton(icon: Icons.receipt_long_rounded, label: 'Registro', onTap: onRegister),
          _BottomNavButton(icon: Icons.help_rounded, label: 'Ayuda', onTap: onHelp),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        child: _BottomNavItem(icon: icon, label: label),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.icon, required this.label, this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
        ),
      ],
    );
  }
}