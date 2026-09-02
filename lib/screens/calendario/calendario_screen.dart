import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// ---------------------------------------------------------------------------
// Colores por tipo de movimiento financiero (mismo criterio que
// TIPO_CONFIG en PanelMovimientos del frontend web)
// TODO(paso 2): migrar estos colores a AppColors/design_tokens.dart
// ---------------------------------------------------------------------------
const Map<String, Color> colorPorTipo = {
  'ingreso': Colors.green,
  'gasto': Colors.amber,
  'imprevisto': Colors.red,
  'ahorro': Colors.purple,
};

// ---------------------------------------------------------------------------
// Modelo de datos: una meta de ahorro
// (queda definida aquí, aunque hoy no se usa en el build — probablemente
// para una futura sección de "metas" dentro de esta misma pantalla)
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

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
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
          'Calendario',
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
        border: Border.all(color: dorado.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad del Mes: ',
            style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '2 ingresos, 3 gastos, 3 abonos, 1 imprevisto',
            style: TextStyle(color: Colors.white, fontSize: 18),
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
        onPageChanged: (nuevoDiaFocalizado) {
          _diaFocalizado = nuevoDiaFocalizado;
          // TODO(conexión backend): disparar fetch a
          // GET /api/movimientos/por-fecha del mes visible.
        },
        eventLoader: _obtenerMovimientosDelDia,
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          todayDecoration: BoxDecoration(
            color: dorado.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Colors.white),
          selectedDecoration: BoxDecoration(
            color: dorado,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: fondoOscuro),
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