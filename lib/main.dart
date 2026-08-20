import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);
  await initializeDateFormatting('es_ES', null);
  runApp(MyApp());
}

// ---------------------------------------------------------------------------
// Colores por tipo de movimiento financiero (mismo criterio que
// TIPO_CONFIG en PanelMovimientos del frontend web)
// ---------------------------------------------------------------------------
const Map<String, Color> colorPorTipo = {
  'ingreso': Colors.green,
  'gasto': Colors.amber,
  'imprevisto': Colors.red,
  'ahorro': Colors.purple,
};

// ---------------------------------------------------------------------------
// Modelo de datos: una meta de ahorro
// ---------------------------------------------------------------------------
class MetaAhorro {
  final String nombre;
  final double montoActual;
  final double montoObjetivo;

  MetaAhorro({
    required this.nombre,
    required this.montoActual,
    required this.montoObjetivo,
  });

  double get progreso => montoActual / montoObjetivo;
}

// ---------------------------------------------------------------------------
// App raíz
// ---------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahorrapp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE0B855),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080C18),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ahorrapp'),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla principal (antes tenía el contador de ejemplo, ahora la vista
// de ahorros)
// ---------------------------------------------------------------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Color fondoOscuro = const Color(0xFF080C18);
  final Color fondoTarjeta = const Color(0xFF0D1526);
  final Color dorado = const Color(0xFFE0B855);

  DateTime _diaFocalizado = DateTime.now();
  DateTime? _diaSeleccionado;

  // Simula lo que traerías de GET /api/movements/por-fecha.
  // La llave es la fecha "pelada" (sin horas), el valor es la lista de
  // tipos de movimiento que hubo ese día.
  final Map<DateTime, List<String>> _movimientosPorDia = {
    _fechaSinHora(DateTime(2026, 8, 5)): ['ahorro'],
    _fechaSinHora(DateTime(2026, 8, 10)): ['imprevisto'],
    _fechaSinHora(DateTime(2026, 8, 14)): ['ahorro'],
    _fechaSinHora(DateTime(2026, 8, 15)): ['gasto'],
    _fechaSinHora(DateTime(2026, 8, 16)): ['ingreso'],
    _fechaSinHora(DateTime(2026, 8, 20)): ['gasto'],
    _fechaSinHora(DateTime(2026, 8, 24)): ['ahorro'],
    // Ejemplo de un día con VARIOS tipos: aparecerán varios puntitos.
    _fechaSinHora(DateTime(2026, 8, 23)): ['gasto', 'ingreso'],
  };

  static DateTime _fechaSinHora(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  List<String> _obtenerMovimientosDelDia(DateTime dia) {
    return _movimientosPorDia[_fechaSinHora(dia)] ?? [];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoOscuro,
      appBar: AppBar(
        backgroundColor: fondoOscuro,
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildTarjetaTitulo(),
          _buildCalendario(),
        ],
      ),
    );
  }

  Widget _buildTarjetaTitulo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dorado.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad del Mes: ',
            style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('2 ingresos, 3 gastos, 3 abonos, 1 imprevisto'
            ,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _diaFocalizado,
        locale: 'es_ES',
        selectedDayPredicate: (dia) => isSameDay(_diaSeleccionado, dia),
        onDaySelected: (diaSeleccionado, diaFocalizado) {
          setState(() {
            _diaSeleccionado = diaSeleccionado;
            _diaFocalizado = diaFocalizado;
          });
        },

        // Se ejecuta al cambiar de mes (con las flechas)
        onPageChanged: (nuevoDiaFocalizado) {
          _diaFocalizado = nuevoDiaFocalizado;
          // Aquí, en tu app real, dispararías el fetch al backend
          // para traer los movimientos del mes nuevo visible.
        },

        // Esta es la función clave: le dice a table_calendar
        // qué "eventos" tiene cada día, para poder dibujar marcadores.
        eventLoader: _obtenerMovimientosDelDia,

        // Estilos generales del calendario (texto, hoy, seleccionado)
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          todayDecoration: BoxDecoration(
            color: dorado.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Colors.white),
          selectedDecoration: BoxDecoration(
            color: dorado,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: fondoOscuro),
          // No queremos el punto genérico que trae table_calendar por
          // defecto: lo vamos a dibujar nosotros mismos con más control
          // en markerBuilder.
          markersMaxCount: 0,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: dorado, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: dorado),
          rightChevronIcon: Icon(Icons.chevron_right, color: dorado),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54),
          weekendStyle: TextStyle(color: Colors.white38),
        ),

        // Aquí construimos manualmente los puntitos debajo del número
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, dia, movimientosDelDia) {
            if (movimientosDelDia.isEmpty) return const SizedBox.shrink();

            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: movimientosDelDia.map((tipo) {
                  final colorDelPunto = colorPorTipo[tipo] ?? Colors.grey;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: colorDelPunto,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}