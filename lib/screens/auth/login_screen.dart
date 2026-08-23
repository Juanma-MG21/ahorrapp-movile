import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'manuel@correo.com');
  final _passwordController = TextEditingController();

  bool _rememberSession = false;
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicio de sesion listo para conectar')),
    );
  }

  void _showPendingFeature(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature aun no esta conectado')));
  }

  void _openRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  void _openForgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF081326), Color(0xFF0C1A33), Color(0xFF12051D)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const _StatusBar(),
                        const SizedBox(height: 26),
                        const _BrandHeader(),
                        const SizedBox(height: 22),
                        _LoginForm(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          rememberSession: _rememberSession,
                          hidePassword: _hidePassword,
                          isLoading: _isLoading,
                          onRememberChanged: (value) {
                            setState(() => _rememberSession = value);
                          },
                          onTogglePassword: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                          onSubmit: _submit,
                          onForgotPassword: _openForgotPassword,
                        ),
                        const SizedBox(height: 18),
                        _QuickAccess(
                          onFingerprint: () =>
                              _showPendingFeature('Acceso por biometria'),
                          onPin: () => _showPendingFeature('Acceso por PIN'),
                        ),
                        const SizedBox(height: 16),
                        _RegisterCallout(onTap: _openRegister),
                        const Spacer(),
                        _BottomAccessNav(
                          onRegister: _openRegister,
                          onHelp: () => _showPendingFeature('Ayuda'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Spacer(),
        Icon(Icons.more_horiz_rounded, color: AppTheme.muted, size: 20),
        SizedBox(width: 8),
        Icon(Icons.battery_5_bar_rounded, color: Color(0xFF34D399), size: 18),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'AhorrApp',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.amber,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Gestion financiera personal',
          style: TextStyle(
            color: Color(0xFF5F7290),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 26),
        Text(
          'Bienvenido de vuelta',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Inicia sesion para continuar',
          style: TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberSession,
    required this.hidePassword,
    required this.isLoading,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberSession;
  final bool hidePassword;
  final bool isLoading;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
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
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'CONTRASENA',
              hintText: '********',
              suffixIcon: IconButton(
                tooltip: hidePassword ? 'Mostrar' : 'Ocultar',
                onPressed: onTogglePassword,
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF52627B),
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Ingresa tu contrasena';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: rememberSession,
                onChanged: (value) => onRememberChanged(value ?? false),
                activeColor: AppTheme.amber,
                checkColor: AppTheme.background,
                visualDensity: VisualDensity.compact,
              ),
              const Text(
                'Recordar sesion',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.blue,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Olvidaste tu contrasena?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [AppTheme.amber, AppTheme.orange],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55FFB000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Text(
                        'Iniciar sesion',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onFingerprint, required this.onPin});

  final VoidCallback onFingerprint;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF202B40))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'o continua con',
                style: TextStyle(color: Color(0xFF52627B), fontSize: 11),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFF202B40))),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _AccessTile(
                icon: Icons.fingerprint_rounded,
                label: 'Huella',
                onTap: onFingerprint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccessTile(
                icon: Icons.pin_rounded,
                label: 'PIN',
                onTap: onPin,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151222),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2A2640)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.amber, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        const Text(
          'No tienes cuenta? ',
          style: TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.amber,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Registrate',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
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
        border: Border(top: BorderSide(color: Color(0xFF141E31))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _BottomNavItem(
            icon: Icons.key_rounded,
            label: 'Acceso',
            selected: true,
          ),
          _BottomNavButton(
            icon: Icons.receipt_long_rounded,
            label: 'Registro',
            onTap: onRegister,
          ),
          _BottomNavButton(
            icon: Icons.help_rounded,
            label: 'Ayuda',
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.amber : const Color(0xFF43516B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
