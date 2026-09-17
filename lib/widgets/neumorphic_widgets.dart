import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_theme.dart';

/// Encabezado estándar para pantallas de registro con diseño neumórfico.
class NeumorphicHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const NeumorphicHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NeumorphicIcon(
          icon: Icons.arrow_back,
          size: 20,
          onTap: onBack,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Etiqueta de campo estilizada para formularios.
class NeumorphicLabel extends StatelessWidget {
  final String text;
  final bool required;

  const NeumorphicLabel({
    super.key,
    this.text = '',
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Caja contenedora con efecto de hundido (clayInset).
class NeumorphicInsetBox extends StatelessWidget {
  final Widget child;
  final double? radius;

  const NeumorphicInsetBox({
    super.key,
    required this.child,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: clayInset(radius: radius ?? AppRadius.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? AppRadius.md),
        child: child,
      ),
    );
  }
}

/// Campo de texto neumórfico con soporte para ícono y validación.
class NeumorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Color? iconColor;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const NeumorphicTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.iconColor,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicInsetBox(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          prefixIcon: icon != null
              ? Icon(icon, color: iconColor ?? AppColors.accent, size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          errorStyle: const TextStyle(height: 0, fontSize: 0), // Ocultar error nativo
        ),
      ),
    );
  }
}

/// Campo interactivo (no editable) para selectores o fechas.
class NeumorphicActionField extends StatelessWidget {
  final VoidCallback onTap;
  final String? value;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final IconData trailingIcon;

  const NeumorphicActionField({
    super.key,
    required this.onTap,
    this.value,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.trailingIcon = Icons.expand_more,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicInsetBox(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(trailingIcon, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón principal con resplandor neumórfico.
class NeumorphicPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool isLoading;

  const NeumorphicPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: clayGlow(color: color, radius: AppRadius.lg),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Botón secundario elevado neumórfico.
class NeumorphicSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const NeumorphicSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: clayRaised(color: AppColors.surface, radius: AppRadius.lg),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono neumórfico interno para el encabezado o botones pequeños.
class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _NeumorphicIcon({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: clayRaised(color: AppColors.surface, radius: 20),
        child: Icon(icon, color: AppColors.textSecondary, size: size),
      ),
    );
  }
}
