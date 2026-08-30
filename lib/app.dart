import 'package:flutter/material.dart';
import 'core/design_tokens.dart';
import 'screens/main_screen.dart';

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
      home: const MainScreen(),
    );
  }
}