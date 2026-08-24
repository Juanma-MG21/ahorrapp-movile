import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  // Necesario porque vamos a hacer trabajo async (Supabase.initialize)
  // antes de llamar a runApp().
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Valores proporcionados por la rama de Juan-M
    url: 'https://vcvlcoxbxjkmvdkwnbdo.supabase.co',
    anonKey: 'sb_publishable_LrAk5c3leXpIAklL5GcHVA_3ICMCX_1',
  );

  runApp(const AhorrApp());
}
