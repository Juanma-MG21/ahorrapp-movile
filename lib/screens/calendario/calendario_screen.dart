import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// PRUEBA TODAVIA SE SIGUE TESTEANDO 
// ---------------------------------------------------------------------------
// Colores (definidos aquí para no depender de variables globales)
// ---------------------------------------------------------------------------
const Color fondoOscuro = Color(0xFF0f172a);
const Color fondoTarjeta = Color(0xFF1e293b);
const Color dorado = Color(0xFFE0B855);

// Colores por tipo de movimiento (mismo criterio que el frontend)
const Map<String, Color> colorPorTipo = {
  'ingreso': Colors.green,
  'gasto': Colors.amber,
  'imprevisto': Colors.red,
  'ahorro': Colors.purple,
};

// ---------------------------------------------------------------------------
// Modelo MetaAhorro (por si se usa después)
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
// Pantalla principal del calendario
// ---------------------------------------------------------------------------
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  // Fechas seleccionadas y enfocadas
  DateTime _diaFocalizado = DateTime.now();
  DateTime _diaSeleccionado = DateTime.now();

  // Datos de ejemplo de movimientos (esto debería venir de tu backend)
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

  // Normaliza una fecha quitando la hora (para comparar días)
  static DateTime _fechaSinHora(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  // Obtiene los movimientos de un día concreto
  List<String> _obtenerMovimientosDelDia(DateTime dia) {
    return _movimientosPorDia[_fechaSinHora(dia)] ?? [];
  }

  // -------------------------------------------------------------------------
  // build
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Tarjeta con resumen del mes (ejemplo estático)
  // -------------------------------------------------------------------------
  Widget _buildTarjetaTitulo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dorado.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad del Mes:',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '2 ingresos, 3 gastos, 3 ahorros, 1 imprevisto',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Calendario
  // -------------------------------------------------------------------------
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
          setState(() {
            _diaFocalizado = nuevoDiaFocalizado;
          });
          // TODO: aquí dispararías una llamada a tu backend para
          // obtener los movimientos del mes visible.
        },
        // Carga los eventos para cada día
        eventLoader: _obtenerMovimientosDelDia,

        // Estilos del calendario
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          todayDecoration: BoxDecoration(
            color: dorado.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: dorado,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Color(0xFF0f172a)),
          // Desactivamos los marcadores por defecto (usaremos markerBuilder)
          markersMaxCount: 0,
        ),

        // Estilo del header (mes/año y flechas)
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: dorado,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: dorado),
          rightChevronIcon: Icon(Icons.chevron_right, color: dorado),
        ),

        // Estilo de los días de la semana
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54),
          weekendStyle: TextStyle(color: Colors.white38),
        ),

        // Personalización de marcadores (puntitos debajo del día)
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, dia, movimientosDelDia) {
            // Si no hay movimientos, no mostramos nada
            if (movimientosDelDia.isEmpty) return const SizedBox.shrink();

            // Dibujamos una hilera de círculos pequeños
            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: movimientosDelDia.map((tipo) {
                  // Asignamos color según el tipo de movimiento
                  final color = colorPorTipo[tipo] ?? Colors.grey;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
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