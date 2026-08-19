import 'package:flutter/material.dart';
import 'core/design_tokens.dart';
// Ojo: ajusta esta ruta si en tu proyecto modulo_gastos.dart está en
// otra carpeta. Por los imports que vimos dentro de modulo_gastos.dart
// ('../../core/design_tokens.dart'), asumo que vive en:
//   lib/screens/gastos/modulo_gastos.dart
// Si está en otra ubicación, solo corrige esta línea de import.
import 'screens/gastos/modulo_gastos.dart';

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AhorrApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgColor,
        colorScheme: const ColorScheme.dark(
          primary: kAccentColor,
          surface: kSecondaryBgColor,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: kTextPrimary),
        ),
      ),
      // TODO: cuando exista pantalla de login/splash, esta línea
      // cambiará para apuntar allá en vez de directo al módulo.
      home: const ModuloGastos(),
    );
  }
}