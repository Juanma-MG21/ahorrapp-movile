import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/gastos/modulo_gastos.dart';
import 'screens/gastos/agregar_gasto_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleWidgetLaunch();
  }

  void _handleWidgetLaunch() {
    HomeWidget.setAppGroupId('com.example.ahorrapp'); // Opcional en Android pero buena práctica
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleUri);
    HomeWidget.widgetClicked.listen(_handleUri);
  }

  void _handleUri(Uri? uri) {
    if (uri != null && uri.scheme == 'ahorrapp') {
      if (uri.host == 'gasto') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const AgregarGastoScreen()),
        );
      }
      // Se puede añadir lógica para 'ingreso' cuando esté disponible el módulo
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AhorrApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1124),
      ),
      home: const ModuloGastos(),
    );
  }
}
