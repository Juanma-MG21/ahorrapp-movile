import 'package:flutter/material.dart';
import '../../screens/dependientes/dependientes_screen.dart'; // tu archivo

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PanelDependentesScreen(), // tu pantalla
    );
  }
}