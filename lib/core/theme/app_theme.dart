import 'package:flutter/material.dart';

// Colores y estilos de Manuel (para mantener compatibilidad con sus formularios)
class ManuelColors {
  static const Color background = Color(0xFF07101F);
  static const Color surface = Color(0xFF0D1B34);
  static const Color surfaceAlt = Color(0xFF121826);
  static const Color amber = Color(0xFFFFC20D);
  static const Color orange = Color(0xFFFF9900);
  static const Color blue = Color(0xFF2F8BFF);
  static const Color muted = Color(0xFF7890B2);
}

// Estilos de Juan (Claymorphism y Diseño Nuevo)
class AppColors {
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF171A24);
  static const Color surfaceAlt = Color(0xFF1E2230);
  static const Color accent = Color(0xFFFFB800);
  static const Color accentSoft = Color(0x33FFB800);
  static const Color success = Color(0xFF34D399);
  static const Color successSoft = Color(0x2634D399);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8B8FA3);
  static const Color textMuted = Color(0xFF5B5F70);
  static const Color borderLight = Color(0x14FFFFFF);
}

class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double pill = 100;
}

class AppTheme {
  const AppTheme._();

  // Alias para mantener compatibilidad con el código de Manuel
  static const Color background = ManuelColors.background;
  static const Color surface = ManuelColors.surface;
  static const Color surfaceAlt = ManuelColors.surfaceAlt;
  static const Color amber = ManuelColors.amber;
  static const Color orange = ManuelColors.orange;
  static const Color blue = ManuelColors.blue;
  static const Color muted = ManuelColors.muted;

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
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
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

// Funciones de decoración Claymorphism de Juan
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
      BoxShadow(
        color: Colors.black54,
        offset: Offset(6, 8),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Color(0x0DFFFFFF),
        offset: Offset(-4, -4),
        blurRadius: 12,
      ),
    ],
  );
}

BoxDecoration claySunken({
  Color color = const Color(0xFF10131B),
  double radius = AppRadius.sm,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(
        color: Colors.black87,
        offset: Offset(2, 2),
        blurRadius: 6,
        blurStyle: BlurStyle.inner,
      ),
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
      BoxShadow(
        color: color.withOpacity(0.45),
        offset: const Offset(0, 6),
        blurRadius: 24,
        spreadRadius: 1,
      ),
    ],
  );
}
