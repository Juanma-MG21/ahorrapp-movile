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
      home: const QrScannerScreen(),
    );
  }
}