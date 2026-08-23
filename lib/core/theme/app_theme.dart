import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color background = Color(0xFF07101F);
  static const Color surface = Color(0xFF0D1B34);
  static const Color surfaceAlt = Color(0xFF121826);
  static const Color amber = Color(0xFFFFC20D);
  static const Color orange = Color(0xFFFF9900);
  static const Color blue = Color(0xFF2F8BFF);
  static const Color muted = Color(0xFF7890B2);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: blue,
        surface: surface,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF52627B), fontSize: 13),
        labelStyle: const TextStyle(
          color: muted,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF24314A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: amber, width: 1.2),
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
    );
  }
}
