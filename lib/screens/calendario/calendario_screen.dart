import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/design_tokens.dart';
import '../../services/gastos_service.dart';
import '../../services/ingresos_service.dart';
import '../../services/imprevistos_service.dart';
import '../../services/ahorros_service.dart';

// ---------------------------------------------------------------------------
// Colores por tipo de movimiento financiero, ahora centralizados en
// AppMovimientoColors (core/theme/design_tokens.dart) en vez de constantes
// de Material sueltas (Colors.green/amber/red/purple) definidas acá mismo.
// ---------------------------------------------------------------------------
const Map<String, Color> colorPorTipo = {
  'ingreso': AppMovimientoColors.ingreso,
  'gasto': AppMovimientoColors.gasto,
  'imprevisto': AppMovimientoColors.imprevisto,
  'ahorro': AppMovimientoColors.ahorro,
};

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _diaFocalizado = DateTime.now();
  DateTime? _diaSeleccionado;

  bool _isLoading = true;
  // Llave: fecha "pelada" (sin horas). Valor: tipos de movimiento ese día.
  Map<DateTime, List<String>> _movimientosPorDia = {};

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  /// Trae ingresos, gastos, imprevistos y ahorros reales del backend
  /// (los mismos 4 endpoints que ya usan sus respectivos módulos) y arma
  /// el mapa fecha -> tipos para pintar los puntos del calendario.
  /// Antes esta pantalla usaba un mapa hardcodeado de ejemplo.
  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);

    // Se inician las 4 peticiones antes de esperar cualquiera (siguen
    // corriendo en paralelo), pero se esperan por separado en vez de
    // meterlas en una sola lista para Future.wait: como cada servicio
    // devuelve un tipo de lista distinto (List<IngresoModel>,
    // List<GastoModel>, etc.), Future.wait las reducía a Future<Object> y
    // se perdían los getters (fechaRegistro/fecha) de cada modelo.
    final futureIngresos = IngresosService.obtenerIngresos();
    final futureGastos = GastosService.obtenerGastos();
    final futureImprevistos = ImprevistosService.obtenerImprevistos();
    final futureAhorros = AhorrosService.obtenerAhorros();

    final ingresos = await futureIngresos;
    final gastos = await futureGastos;
    final imprevistos = await futureImprevistos;
    final ahorros = await futureAhorros;

    final Map<DateTime, List<String>> mapa = {};

    void agregar(DateTime? fecha, String tipo) {
      if (fecha == null) return;
      final clave = _fechaSinHora(fecha);
      mapa.putIfAbsent(clave, () => []).add(tipo);
    }

    for (final i in ingresos) {
      agregar(i.fechaRegistro, 'ingreso');
    }
    for (final g in gastos) {
      agregar(g.fecha, 'gasto');
    }
    for (final imp in imprevistos) {
      agregar(imp.fecha, 'imprevisto');
    }
    for (final a in ahorros) {
      agregar(a.fechaRegistro, 'ahorro');
    }

    if (!mounted) return;
    setState(() {
      _movimientosPorDia = mapa;
      _isLoading = false;
    });
  }

  static DateTime _fechaSinHora(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  List<String> _obtenerMovimientosDelDia(DateTime dia) {
    return _movimientosPorDia[_fechaSinHora(dia)] ?? [];
  }

  /// Cuenta ingresos/gastos/ahorros/imprevistos que caen dentro del mes
  /// actualmente enfocado en el calendario, para la tarjeta de resumen.
  Map<String, int> _resumenDelMes() {
    final conteo = {'ingreso': 0, 'gasto': 0, 'ahorro': 0, 'imprevisto': 0};
    _movimientosPorDia.forEach((fecha, tipos) {
      if (fecha.year == _diaFocalizado.year && fecha.month == _diaFocalizado.month) {
        for (final tipo in tipos) {
          if (conteo.containsKey(tipo)) conteo[tipo] = conteo[tipo]! + 1;
        }
      }
    });
    return conteo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Calendario',
          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                _buildTarjetaTitulo(),
                _buildCalendario(),
              ],
            ),
    );
  }

  Widget _buildTarjetaTitulo() {
    final resumen = _resumenDelMes();
    final texto = '${resumen['ingreso']} ingresos, ${resumen['gasto']} gastos, '
        '${resumen['ahorro']} ahorros, ${resumen['imprevisto']} imprevistos';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividad del mes',
            style: TextStyle(color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
          // Los datos ya están todos cargados en memoria (misma fuente que
          // el resto de módulos), así que solo hace falta refrescar qué
          // mes se está mostrando en la tarjeta de resumen — no hace falta
          // volver a pedirle nada al backend.
          setState(() => _diaFocalizado = nuevoDiaFocalizado);
        },
        eventLoader: _obtenerMovimientosDelDia,
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: TextStyle(color: AppColors.textSecondary),
          outsideTextStyle: TextStyle(color: AppColors.textMuted),
          todayDecoration: BoxDecoration(
            color: Color(0x4DFFB800), // AppColors.accent al 30% de opacidad
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(color: AppColors.textPrimary),
          selectedDecoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: Colors.black),
          markersMaxCount: 0,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.accent),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.accent),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textSecondary),
          weekendStyle: TextStyle(color: AppColors.textMuted),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, dia, movimientosDelDia) {
            if (movimientosDelDia.isEmpty) return const SizedBox.shrink();
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: movimientosDelDia.map((tipo) {
                  final colorDelPunto = colorPorTipo[tipo] ?? AppColors.textMuted;
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
