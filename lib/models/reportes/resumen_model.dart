import 'reporte_json_utils.dart';

class FondoEmergenciaResumen {
  final double aportes;
  final double retiros;
  final double neto;

  FondoEmergenciaResumen({
    required this.aportes,
    required this.retiros,
    required this.neto,
  });

  factory FondoEmergenciaResumen.fromJson(Map<String, dynamic> json) {
    return FondoEmergenciaResumen(
      aportes: parseDouble(json['aportes']),
      retiros: parseDouble(json['retiros']),
      neto: parseDouble(json['neto']),
    );
  }
}

/// GET /reportes/resumen
class ReporteResumen {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  final double ingresos;
  final double gastos;
  final double imprevistos;
  final double ahorros;
  final double pagosDeudas;
  final FondoEmergenciaResumen fondoEmergencia;
  final double balance;

  final double deudasMontoPagado;
  final int deudasCuotasPagadas;

  ReporteResumen({
    this.fechaInicio,
    this.fechaFin,
    required this.ingresos,
    required this.gastos,
    required this.imprevistos,
    required this.ahorros,
    required this.pagosDeudas,
    required this.fondoEmergencia,
    required this.balance,
    required this.deudasMontoPagado,
    required this.deudasCuotasPagadas,
  });

  factory ReporteResumen.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final deudas = json['deudas'] as Map<String, dynamic>? ?? {};

    return ReporteResumen(
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      ingresos: parseDouble(resumen['ingresos']),
      gastos: parseDouble(resumen['gastos']),
      imprevistos: parseDouble(resumen['imprevistos']),
      ahorros: parseDouble(resumen['ahorros']),
      pagosDeudas: parseDouble(resumen['pagos_deudas']),
      fondoEmergencia: FondoEmergenciaResumen.fromJson(
        resumen['fondo_emergencia'] as Map<String, dynamic>? ?? {},
      ),
      balance: parseDouble(resumen['balance']),
      deudasMontoPagado: parseDouble(deudas['monto_pagado']),
      deudasCuotasPagadas: parseInt(deudas['cuotas_pagadas']),
    );
  }
}