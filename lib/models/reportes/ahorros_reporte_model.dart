import 'reporte_json_utils.dart';

/// Una fila del historial de abonos a ahorros (GET /reportes/ahorros)
class AbonoAhorro {
  final int idAbono;
  final int idAhorro;
  final double monto;
  final DateTime? fechaRegistro;
  final double metaMonto;
  final double montoAcumulado;
  final String? descripcion;
  final double meta;

  AbonoAhorro({
    required this.idAbono,
    required this.idAhorro,
    required this.monto,
    this.fechaRegistro,
    required this.metaMonto,
    required this.montoAcumulado,
    this.descripcion,
    required this.meta,
  });

  factory AbonoAhorro.fromJson(Map<String, dynamic> json) {
    return AbonoAhorro(
      idAbono: parseInt(json['id_abono']),
      idAhorro: parseInt(json['id_ahorros']),
      monto: parseDouble(json['monto']),
      fechaRegistro: parseFecha(json['fecha_registro']),
      metaMonto: parseDouble(json['meta_monto']),
      montoAcumulado: parseDouble(json['monto_acumulado']),
      descripcion: json['descripcion'] as String?,
      meta: parseDouble(json['meta']),
    );
  }
}

/// GET /reportes/ahorros (historial dentro de un rango de fechas)
class ReporteAhorros {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double totalAhorrado;
  final List<AbonoAhorro> datos;

  ReporteAhorros({
    this.fechaInicio,
    this.fechaFin,
    required this.totalAhorrado,
    required this.datos,
  });

  factory ReporteAhorros.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final datos = (json['datos'] as List<dynamic>? ?? [])
        .map((e) => AbonoAhorro.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReporteAhorros(
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      totalAhorrado: parseDouble(json['total_ahorrado']),
      datos: datos,
    );
  }
}

/// Una fila de GET /reportes/ahorros/estado (una meta de ahorro y su avance)
class MetaAhorroEstado {
  final int idAhorro;
  final double meta;
  final double montoAcumulado;
  final double porcentajeCumplimiento;
  final double totalAbonado;
  final DateTime? fechaRegistro;
  final DateTime? fechaMeta;
  final String? descripcion;

  MetaAhorroEstado({
    required this.idAhorro,
    required this.meta,
    required this.montoAcumulado,
    required this.porcentajeCumplimiento,
    required this.totalAbonado,
    this.fechaRegistro,
    this.fechaMeta,
    this.descripcion,
  });

  factory MetaAhorroEstado.fromJson(Map<String, dynamic> json) {
    return MetaAhorroEstado(
      idAhorro: parseInt(json['id_ahorro']),
      meta: parseDouble(json['meta']),
      montoAcumulado: parseDouble(json['monto_acumulado']),
      porcentajeCumplimiento: parseDouble(json['porcentaje_cumplimiento']),
      totalAbonado: parseDouble(json['total_abonado']),
      fechaRegistro: parseFecha(json['fecha_registro']),
      fechaMeta: parseFecha(json['fecha_meta']),
      descripcion: json['descripcion'] as String?,
    );
  }
}

/// GET /reportes/ahorros/estado (estado actual, sin rango de fechas)
class EstadoAhorros {
  final int cantidadMetas;
  final double metaTotal;
  final double acumuladoTotal;
  final double porcentajeCumplimiento;
  final List<MetaAhorroEstado> datos;

  EstadoAhorros({
    required this.cantidadMetas,
    required this.metaTotal,
    required this.acumuladoTotal,
    required this.porcentajeCumplimiento,
    required this.datos,
  });

  factory EstadoAhorros.fromJson(Map<String, dynamic> json) {
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};
    final datos = (json['datos'] as List<dynamic>? ?? [])
        .map((e) => MetaAhorroEstado.fromJson(e as Map<String, dynamic>))
        .toList();

    return EstadoAhorros(
      cantidadMetas: parseInt(resumen['cantidad_metas']),
      metaTotal: parseDouble(resumen['meta_total']),
      acumuladoTotal: parseDouble(resumen['acumulado_total']),
      porcentajeCumplimiento: parseDouble(resumen['porcentaje_cumplimiento']),
      datos: datos,
    );
  }
}