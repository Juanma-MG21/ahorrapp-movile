// lib/core/app_theme.dart
//
// Aquí viven TODOS los colores y estilos "clay/neumórficos" de la app.
// La idea es que ninguna pantalla escriba un color a mano: siempre se
// referencia AppColors.xxx o se usa una de las funciones de decoración
// (claySunken, clayRaised, clayGlow) para que todo se vea consistente.

import 'package:flutter/material.dart';

class AppColors {
  // Fondo general
  static const Color background = Color(0xFF0B0E14);

  // Tarjetas / superficies "elevadas"
  static const Color surface = Color(0xFF171A24);
  static const Color surfaceAlt = Color(0xFF1E2230);

  // Acento principal
  static const Color accent = Color(0xFFFFB800);
  static const Color accentSoft = Color(0x33FFB800);

  // Verde usado en el marco del escáner y accesos de progreso positivo
  static const Color success = Color(0xFF34D399);
  static const Color successSoft = Color(0x2634D399);

  // Textos
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8B8FA3);
  static const Color textMuted = Color(0xFF5B5F70);

  // Bordes sutiles sobre las superficies oscuras
  static const Color borderLight = Color(0x14FFFFFF); // blanco 8%
}

class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double pill = 100;
}

/// Decoración "elevada" (claymorphism): la superficie parece salir del
/// fondo, con una sombra oscura abajo-derecha y un brillo tenue arriba-izq.
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
        color: Color(0x0DFFFFFF), // blanco muy tenue
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


ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.success,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary),
    ),
    fontFamily: 'Roboto',
  );
}