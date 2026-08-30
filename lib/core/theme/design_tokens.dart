import 'package:flutter/material.dart';

/// Paleta y tokens de diseño únicos de AhorrApp.
/// Fuente de verdad para colores, radios y espaciados usados en toda la app.
class AppColors {
  const AppColors._();

  // Fondos
  static const Color background = Color(0xFF0E1124);
  static const Color surface = Color(0xFF141730);      // antes kSecondaryBgColor
  static const Color surfaceAlt = Color(0xFF1E2230);    // heredado de Juan, variación de superficie
  static const Color inset = Color(0xFF080A15);         // antes kInsetBg

  // Acento
  static const Color accent = Color(0xFFFFB800);
  static const Color accentSoft = Color(0x33FFB800);

  // Semánticos
  static const Color success = Color(0xFF34D399);
  static const Color successSoft = Color(0x2634D399);
  static const Color error = Color(0xFFFF6B6B);         // antes kNegativeColor
  static const Color blue = Color(0xFF2F8BFF);          // nuevo (de Manuel), para info/links

  // Texto
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF7A7D95); // antes kTextSecondary
  static const Color textMuted = Color(0xFF5B5F70);      // heredado de Juan
  static const Color muted = textSecondary;               // alias para pantallas de auth

  // Navegación
  static const Color navInactive = Color(0xFF5A5D75);   // antes kNavbarInactive

  // Bordes
  static const Color borderLight = Color(0x14FFFFFF);
}

/// Colores de íconos por categoría de gasto.
class AppCategoryColors {
  const AppCategoryColors._();

  static const Color ropa = Color(0xFF4ADE80);
  static const Color almuerzo = Color(0xFFA8A2FF);
  static const Color transporte = Color(0xFF60A5FA);
}

class AppRadius {
  const AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double pill = 100;
}