import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/auth_widgets.dart';
import 'auth_gate.dart';

class FastLoginScreen extends StatelessWidget {
  const FastLoginScreen({
    this.userName,
    this.userEmail,
    super.key,
  });

  /// Nombre y correo del usuario de la sesión guardada. Son opcionales
  /// porque, por ahora, AuthService solo persiste el token (ver
  /// hasSession()) y no el perfil del usuario. Si en el futuro guardas
  /// también nombre/correo (por ejemplo junto al token en el storage
  /// seguro), pásalos aquí al navegar desde AuthGate para personalizar
  /// el saludo.
  final String? userName;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 50),

          // Avatar del usuario
          Container(
            width: 90,
            height: 90,
            decoration: _clayCircle(),
            child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
          ),

          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido de vuelta!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userName ?? 'Tu cuenta',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (userEmail != null) ...[
            const SizedBox(height: 2),
            Text(
              userEmail!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],

          const SizedBox(height: 60),

          // Botones de acceso rápido
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FastAccessButton(
                icon: Icons.fingerprint_rounded,
                label: "Huella",
                onTap: () => Navigator.of(context).pushNamed('/biometric-access'),
              ),
              const SizedBox(width: 30),
              _FastAccessButton(
                icon: Icons.pin_rounded,
                label: "PIN",
                onTap: () => Navigator.of(context).pushNamed('/pin-access'),
              ),
            ],
          ),

          const SizedBox(height: 60),

          TextButton(
            onPressed: () {
              // Nota: esto solo navega al login. Si "usar otra cuenta"
              // debe cerrar la sesión guardada (borrar el token), hay
              // que llamar primero a un método de logout en AuthService
              // (por ejemplo AuthService.instance.logout()) antes de
              // navegar, una vez que exista.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            child: const Text(
              'Usar otra cuenta',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Réplica local del estilo "clayRaised" circular de app_theme.dart, usando
/// solo AppColors (evita importar app_theme.dart junto con design_tokens.dart).
BoxDecoration _clayCircle() {
  return BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.surface,
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black54, offset: Offset(6, 8), blurRadius: 16),
      BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(-4, -4), blurRadius: 12),
    ],
  );
}

class _FastAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FastAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Icon(icon, color: AppColors.accent, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}