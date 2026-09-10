import 'package:flutter/material.dart';
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

  bool _rememberSession = false;
  bool _hidePassword = true;
  bool _isLoading = false;

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
        const SnackBar(content: Text('Ocurrió un error inesperado'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildBrandHeader(),
          const SizedBox(height: 40),
          _buildLoginForm(),
          const SizedBox(height: 32),
          _buildGoogleButton(),
          const SizedBox(height: 30),
          _buildQuickAccess(),
          const SizedBox(height: 40),
          _RegisterCallout(onTap: () => Navigator.of(context).pushNamed('/register')),
          const SizedBox(height: 40),
          _buildHelpFooter(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return const Column(
      children: [
        Text('AhorrApp', style: TextStyle(color: AppColors.accent, fontSize: 36, fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text('Gestión financiera personal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
            decoration: const InputDecoration(labelText: 'CORREO ELECTRÓNICO', suffixIcon: Icon(Icons.mail_rounded, size: 20)),
            validator: (value) {
              if ((value ?? '').isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              labelText: 'CONTRASEÑA',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
              ),
            ),
            validator: (value) => (value ?? '').isEmpty ? 'Ingresa tu contraseña' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 20, width: 20,
                child: Checkbox(
                  value: _rememberSession,
                  onChanged: (v) => setState(() => _rememberSession = v ?? false),
                  activeColor: AppColors.accent, checkColor: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Recordar sesión', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          PrimaryAuthButton(label: 'Iniciar sesión', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente'))),
      icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_Logo.svg/1024px-Google_\"G\"_Logo.svg.png', height: 20),
      label: const Text('Continuar con Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderLight)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o accede rápido', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
            Expanded(child: Divider(color: AppColors.borderLight)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _AccessTile(icon: Icons.fingerprint_rounded, label: 'Huella', onTap: () => Navigator.of(context).pushNamed('/biometric-access'))),
            const SizedBox(width: 16),
            Expanded(child: _AccessTile(icon: Icons.pin_rounded, label: 'PIN', onTap: () => Navigator.of(context).pushNamed('/pin-access'))),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.help_outline_rounded, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
          child: const Text('¿Necesitas ayuda?', style: TextStyle(color: AppColors.textMuted, fontSize: 13, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}

class _AccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AccessTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class _RegisterCallout extends StatelessWidget {
  final VoidCallback onTap;
  const _RegisterCallout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿No tienes cuenta? ', style: TextStyle(color: AppColors.muted, fontSize: 14)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Regístrate', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
