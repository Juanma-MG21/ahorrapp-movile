import 'reporte_json_utils.dart';

/// Una fila (un día) de la evolución financiera
class PuntoEvolucion {
  final DateTime? fecha;
  final double ingresos;
  final double gastos;
  final double imprevistos;
  final double ahorros;
  final double pagosDeudas;
  final double aportesEmergencia;
  final double retirosEmergencia;
  final double balance;
  final double balanceAcumulado;

  PuntoEvolucion({
    this.fecha,
    required this.ingresos,
    required this.gastos,
    required this.imprevistos,
    required this.ahorros,
    required this.pagosDeudas,
    required this.aportesEmergencia,
    required this.retirosEmergencia,
    required this.balance,
    required this.balanceAcumulado,
  });

  factory PuntoEvolucion.fromJson(Map<String, dynamic> json) {
    return PuntoEvolucion(
      fecha: parseFecha(json['fecha']),
      ingresos: parseDouble(json['ingresos']),
      gastos: parseDouble(json['gastos']),
      imprevistos: parseDouble(json['imprevistos']),
      ahorros: parseDouble(json['ahorros']),
      pagosDeudas: parseDouble(json['pagos_deudas']),
      aportesEmergencia: parseDouble(json['aportes_emergencia']),
      retirosEmergencia: parseDouble(json['retiros_emergencia']),
      balance: parseDouble(json['balance']),
      balanceAcumulado: parseDouble(json['balance_acumulado']),
    );
  }
}

/// GET /reportes/evolucion
class ReporteEvolucion {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<PuntoEvolucion> datos;

  ReporteEvolucion({
    this.fechaInicio,
    this.fechaFin,
    required this.datos,
  });

  factory ReporteEvolucion.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodo'] as Map<String, dynamic>? ?? {};
    final datos = (json['datos'] as List<dynamic>? ?? [])
        .map((e) => PuntoEvolucion.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReporteEvolucion(
      fechaInicio: parseFecha(periodo['fecha_inicio']),
      fechaFin: parseFecha(periodo['fecha_fin']),
      datos: datos,
    );
  }
}