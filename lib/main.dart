// lib/main.dart
//
// Punto de entrada de la app. Antes de arrancar el widget principal,
// inicializamos Supabase — si no se hace esto ANTES de runApp(),
// cualquier llamada a SupabaseService (fetchGastos, insertGasto, etc.)
// fallará porque Supabase.instance.client no existiría todavía.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  // Necesario porque vamos a hacer trabajo async (Supabase.initialize)
  // antes de llamar a runApp().
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: reemplaza esto por los valores reales de tu proyecto.
    // Los encuentras en tu panel de Supabase:
    // Project Settings > API > "Project URL" y "anon public" key.
    url: 'https://vcvlcoxbxjkmvdkwnbdo.supabase.co',
    publishableKey: 'sb_publishable_LrAk5c3leXpIAklL5GcHVA_3ICMCX_1',
  );

  runApp(const AhorrApp());
}