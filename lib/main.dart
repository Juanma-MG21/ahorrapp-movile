import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard/dashboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://vcvlcoxbxjkmvdkwnbdo.supabase.co',  // 👈 Tu URL de Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjdmxjb3hieGprbXZka3duYmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxNDkwOTUsImV4cCI6MjEwMjcyNTA5NX0.b5ygfftkTsbITCGscgJhdPhFJGUczVoP1nhENMLmddo',                  // 👈 Tu clave anónima
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahorrapp',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
      ),
      home: const DashboardScreen(),  // O HomeScreen() si existe
    );
  }
}