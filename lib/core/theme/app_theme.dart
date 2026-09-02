import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Construye el ThemeData global de la app.
/// Los colores vienen SIEMPRE de AppColors (design_tokens.dart) — este
/// archivo no define ningún color propio.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.success,
        surface: AppColors.surface,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

// --- Decoraciones Claymorphism (heredadas de Juan, sin cambios de lógica) ---

BoxDecoration clayRaised({
  Color color = AppColors.surface,
  double radius = AppRadius.md,
  Border? border,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: border ?? Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black54, offset: Offset(6, 8), blurRadius: 16),
      BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(-4, -4), blurRadius: 12),
    ],
  );
}

BoxDecoration claySunken({
  Color color = AppColors.inset,
  double radius = AppRadius.sm,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 6, blurStyle: BlurStyle.inner),
    ],
  );
}

BoxDecoration clayGlow({
  Color color = AppColors.accent,
  double radius = AppRadius.pill,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.45), offset: const Offset(0, 6), blurRadius: 24, spreadRadius: 1),
    ],
  );
}