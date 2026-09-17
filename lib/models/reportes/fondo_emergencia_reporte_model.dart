import 'reporte_json_utils.dart';

/// GET /reportes/fondo-emergencia (dentro de un rango de fechas).
/// Ojo: el backend responde 404 si el usuario no tiene fondo creado -
/// eso lo maneja el service (paso 3) devolviendo null, no este modelo.
class ReporteFondoEmergencia {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double aportes;
  final double retiros;
  final double movimientoNeto;
  final double meta;

  ReporteFondoEmergencia({
    this.fechaInicio,
    this.fechaFin,
    required this.aportes,
    required this.retiros,
    required this.movimientoNeto,
    required this.meta,
  });

  factory ReporteFondoEmergencia.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};

    return ReporteFondoEmergencia(
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      aportes: parseDouble(resumen['aportes']),
      retiros: parseDouble(resumen['retiros']),
      movimientoNeto: parseDouble(resumen['movimiento_neto']),
      meta: parseDouble(resumen['meta']),
    );
  }
}

/// GET /reportes/fondo-emergencia/estado (estado actual, sin fechas)
class EstadoFondoEmergencia {
  final int idFondo;
  final double meta;
  final double aportes;
  final double retiros;
  final double saldoActual;
  final double porcentajeMeta;
  final DateTime? fechaCreacion;

  EstadoFondoEmergencia({
    required this.idFondo,
    required this.meta,
    required this.aportes,
    required this.retiros,
    required this.saldoActual,
    required this.porcentajeMeta,
    this.fechaCreacion,
  });

  factory EstadoFondoEmergencia.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return EstadoFondoEmergencia(
      idFondo: parseInt(data['id_fondo']),
      meta: parseDouble(data['meta']),
      aportes: parseDouble(data['aportes']),
      retiros: parseDouble(data['retiros']),
      saldoActual: parseDouble(data['saldo_actual']),
      porcentajeMeta: parseDouble(data['porcentaje_meta']),
      fechaCreacion: parseFecha(data['fecha_creacion']),
    );
  }
}