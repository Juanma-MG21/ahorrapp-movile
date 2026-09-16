import 'reporte_json_utils.dart';

/// Bloque planeado/ejecutado/diferencia/porcentaje que se repite 5 veces
/// dentro del reporte de presupuesto (gastos, deudas, imprevistos,
/// ahorros, emergencia)
class CategoriaPresupuesto {
  final double planeado;
  final double ejecutado;
  final double diferencia;
  final double porcentajeUsado;

  CategoriaPresupuesto({
    required this.planeado,
    required this.ejecutado,
    required this.diferencia,
    required this.porcentajeUsado,
  });

  factory CategoriaPresupuesto.fromJson(Map<String, dynamic> json) {
    return CategoriaPresupuesto(
      planeado: parseDouble(json['planeado']),
      ejecutado: parseDouble(json['ejecutado']),
      diferencia: parseDouble(json['diferencia']),
      porcentajeUsado: parseDouble(json['porcentaje_usado']),
    );
  }
}

/// GET /reportes/presupuesto/:id_periodo
class ReportePresupuesto {
  final int idPeriodo;
  final int idPresupuesto;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? estadoPeriodo;

  final String? nombrePresupuesto;
  final String? descripcionPresupuesto;

  final double ingresoEstimado;
  final double ingresoReal;

  final double saldoAnterior;
  final double saldoDisponible;

  final CategoriaPresupuesto gastos;
  final CategoriaPresupuesto deudas;
  final CategoriaPresupuesto imprevistos;
  final CategoriaPresupuesto ahorros;
  final CategoriaPresupuesto emergencia;

  final double totalPlaneado;
  final double totalEjecutado;
  final double diferenciaTotal;
  final double porcentajeEjecucion;

  ReportePresupuesto({
    required this.idPeriodo,
    required this.idPresupuesto,
    this.fechaInicio,
    this.fechaFin,
    this.estadoPeriodo,
    this.nombrePresupuesto,
    this.descripcionPresupuesto,
    required this.ingresoEstimado,
    required this.ingresoReal,
    required this.saldoAnterior,
    required this.saldoDisponible,
    required this.gastos,
    required this.deudas,
    required this.imprevistos,
    required this.ahorros,
    required this.emergencia,
    required this.totalPlaneado,
    required this.totalEjecutado,
    required this.diferenciaTotal,
    required this.porcentajeEjecucion,
  });

  factory ReportePresupuesto.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final presupuesto = json['presupuesto'] as Map<String, dynamic>? ?? {};
    final ingresos = json['ingresos'] as Map<String, dynamic>? ?? {};
    final saldo = json['saldo'] as Map<String, dynamic>? ?? {};
    final categorias = json['categorias'] as Map<String, dynamic>? ?? {};
    final resumen = json['resumen'] as Map<String, dynamic>? ?? {};

    CategoriaPresupuesto categoria(String llave) {
      return CategoriaPresupuesto.fromJson(
        categorias[llave] as Map<String, dynamic>? ?? {},
      );
    }

    return ReportePresupuesto(
      idPeriodo: parseInt(periodo['id_periodo']),
      idPresupuesto: parseInt(periodo['id_presupuesto']),
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      estadoPeriodo: periodo['estado'] as String?,
      nombrePresupuesto: presupuesto['nombre'] as String?,
      descripcionPresupuesto: presupuesto['descripcion'] as String?,
      ingresoEstimado: parseDouble(ingresos['estimado']),
      ingresoReal: parseDouble(ingresos['real']),
      saldoAnterior: parseDouble(saldo['anterior']),
      saldoDisponible: parseDouble(saldo['disponible']),
      gastos: categoria('gastos'),
      deudas: categoria('deudas'),
      imprevistos: categoria('imprevistos'),
      ahorros: categoria('ahorros'),
      emergencia: categoria('emergencia'),
      totalPlaneado: parseDouble(resumen['total_planeado']),
      totalEjecutado: parseDouble(resumen['total_ejecutado']),
      diferenciaTotal: parseDouble(resumen['diferencia']),
      porcentajeEjecucion: parseDouble(resumen['porcentaje_ejecucion']),
    );
  }
}