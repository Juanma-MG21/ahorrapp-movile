// lib/app.dart
//
// Widget raíz: aquí se define el MaterialApp, el tema global (el que
// armamos en core/app_theme.dart) y cuál es la primera pantalla que ve
// el usuario al abrir la app.

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/qr_scanner_screen.dart';

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AhorrApp',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // TODO: cuando tengas más pantallas (login, home con navbar, etc.)
      // esta pantalla inicial cambiará. Por ahora apunta directo al
      // escáner QR para que puedas probarlo de una vez.
      home: const QrScannerScreen(),
    );
  }
}