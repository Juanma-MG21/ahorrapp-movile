import 'reporte_json_utils.dart';

/// Una fila del historial de abonos a deudas (GET /reportes/deudas)
class AbonoDeuda {
  final int idAbonoDeuda;
  final int idDeuda;
  final int cuotas;
  final double monto;
  final DateTime? fechaRegistro;
  final String? descripcion;
  final String? fuente;
  final double montoTotalDeuda;
  final int cuotasTotal;
  final int cuotasPagadas;
  final String? estado;

  AbonoDeuda({
    required this.idAbonoDeuda,
    required this.idDeuda,
    required this.cuotas,
    required this.monto,
    this.fechaRegistro,
    this.descripcion,
    this.fuente,
    required this.montoTotalDeuda,
    required this.cuotasTotal,
    required this.cuotasPagadas,
    this.estado,
  });

  factory AbonoDeuda.fromJson(Map<String, dynamic> json) {
    return AbonoDeuda(
      idAbonoDeuda: parseInt(json['id_abono_deuda']),
      idDeuda: parseInt(json['id_deudas']),
      cuotas: parseInt(json['cuotas']),
      monto: parseDouble(json['monto']),
      fechaRegistro: parseFecha(json['fecha_registro']),
      descripcion: json['descripcion'] as String?,
      fuente: json['fuente'] as String?,
      montoTotalDeuda: parseDouble(json['monto_total_deuda']),
      cuotasTotal: parseInt(json['cuotas_total']),
      cuotasPagadas: parseInt(json['cuotas_pagadas']),
      estado: json['estado'] as String?,
    );
  }
}

/// GET /reportes/deudas (historial dentro de un rango de fechas)
class ReporteDeudas {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double totalPagado;
  final int cuotasPagadas;
  final List<AbonoDeuda> datos;

  ReporteDeudas({
    this.fechaInicio,
    this.fechaFin,
    required this.totalPagado,
    required this.cuotasPagadas,
    required this.datos,
  });

  factory ReporteDeudas.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final datos = (json['datos'] as List<dynamic>? ?? [])
        .map((e) => AbonoDeuda.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReporteDeudas(
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      totalPagado: parseDouble(resumen['total_pagado']),
      cuotasPagadas: parseInt(resumen['cuotas_pagadas']),
      datos: datos,
    );
  }
}

/// Una fila de GET /reportes/deudas/estado (una deuda y su avance)
class DeudaEstado {
  final int idDeuda;
  final String? fuente;
  final String? descripcion;
  final DateTime? fechaInicio;
  final double montoTotal;
  final double montoPagado;
  final double montoPendiente;
  final int cuotasTotal;
  final int cuotasPagadas;
  final int cuotasPendientes;
  final double porcentajePagado;
  final String? estado;

  DeudaEstado({
    required this.idDeuda,
    this.fuente,
    this.descripcion,
    this.fechaInicio,
    required this.montoTotal,
    required this.montoPagado,
    required this.montoPendiente,
    required this.cuotasTotal,
    required this.cuotasPagadas,
    required this.cuotasPendientes,
    required this.porcentajePagado,
    this.estado,
  });

  factory DeudaEstado.fromJson(Map<String, dynamic> json) {
    return DeudaEstado(
      idDeuda: parseInt(json['id_deuda']),
      fuente: json['fuente'] as String?,
      descripcion: json['descripcion'] as String?,
      fechaInicio: parseFecha(json['fecha_inicio']),
      montoTotal: parseDouble(json['monto_total']),
      montoPagado: parseDouble(json['monto_pagado']),
      montoPendiente: parseDouble(json['monto_pendiente']),
      cuotasTotal: parseInt(json['cuotas_total']),
      cuotasPagadas: parseInt(json['cuotas_pagadas']),
      cuotasPendientes: parseInt(json['cuotas_pendientes']),
      porcentajePagado: parseDouble(json['porcentaje_pagado']),
      estado: json['estado'] as String?,
    );
  }
}

/// GET /reportes/deudas/estado (estado actual, sin rango de fechas)
class EstadoDeudas {
  final int cantidadDeudas;
  final double montoTotal;
  final double montoPagado;
  final double montoPendiente;
  final int cuotasTotal;
  final int cuotasPagadas;
  final int cuotasPendientes;
  final double porcentajePagado;
  final List<DeudaEstado> datos;

  EstadoDeudas({
    required this.cantidadDeudas,
    required this.montoTotal,
    required this.montoPagado,
    required this.montoPendiente,
    required this.cuotasTotal,
    required this.cuotasPagadas,
    required this.cuotasPendientes,
    required this.porcentajePagado,
    required this.datos,
  });

  factory EstadoDeudas.fromJson(Map<String, dynamic> json) {
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final datos = (json['datos'] as List<dynamic>? ?? [])
        .map((e) => DeudaEstado.fromJson(e as Map<String, dynamic>))
        .toList();

    return EstadoDeudas(
      cantidadDeudas: parseInt(resumen['cantidad_deudas']),
      montoTotal: parseDouble(resumen['monto_total']),
      montoPagado: parseDouble(resumen['monto_pagado']),
      montoPendiente: parseDouble(resumen['monto_pendiente']),
      cuotasTotal: parseInt(resumen['cuotas_total']),
      cuotasPagadas: parseInt(resumen['cuotas_pagadas']),
      cuotasPendientes: parseInt(resumen['cuotas_pendientes']),
      porcentajePagado: parseDouble(resumen['porcentaje_pagado']),
      datos: datos,
    );
  }
}