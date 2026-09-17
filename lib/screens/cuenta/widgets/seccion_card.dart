import 'package:flutter/material.dart';

/// Paleta local, independiente de core/theme/design_tokens.dart, para
/// no asumir tokens que no están confirmados en el proyecto. Los
/// valores replican la paleta ya usada en la web (PanelAdmin/Micuenta),
/// así la app móvil se ve consistente con el panel de administración.
class CuentaColors {
  static const background = Color(0xFF0B1120);
  static const surface = Color(0xFF0D1526);
  static const surfaceAlt = Color(0xFF111A2E);
  static const border = Color(0xFF1C2942);
  static const accent = Color(0xFFE0B855);
  static const textPrimary = Color(0xFFF4F1E8);
  static const textSecondary = Color(0xFF9AA6C4);
  static const textMuted = Color(0xFF7D8AA8);
  static const danger = Color(0xFFE24B4A);
  static const success = Color(0xFF97C459);
  static const info = Color(0xFF85B7EB);
}

/// Tarjeta contenedora de una sección (agrupa varias [SeccionTile]).
class SeccionCard extends StatelessWidget {
  const SeccionCard({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                color: CuentaColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: CuentaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CuentaColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, color: CuentaColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Una fila de "settings": icono + título + subtítulo opcional +
/// chevron (o un widget trailing custom). Pensada para navegar a una
/// subpantalla, manteniendo la vista principal de Cuenta liviana.
class SeccionTile extends StatelessWidget {
  const SeccionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? CuentaColors.danger : (iconColor ?? CuentaColors.accent);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive ? CuentaColors.danger : CuentaColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: CuentaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded, color: CuentaColors.textMuted, size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
