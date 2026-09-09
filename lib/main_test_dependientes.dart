import 'package:flutter/material.dart';
import 'screens/dependientes/dependientes_screen.dart';
// PRUEBAS
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PanelDependientesScreen(),
    ),
  );
}