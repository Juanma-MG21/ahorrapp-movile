import '../core/utils/presupuestos_parsing.dart';

/// Un "perfil de presupuesto" (tabla `presupuestos`).
/// Ej: Normal, Ahorro, Ajustado — cada uno define cómo se reparte
/// el ingreso de un período entre las 5 categorías.
class Presupuesto {
  Presupuesto({
    required this.idPresupuesto,
    required this.nombre,
    this.descripcion,
    required this.activo,
    required this.diaCorte,
    required this.porcentajeGastos,
    required this.porcentajeDeudas,
    required this.porcentajeImprevistos,
    required this.porcentajeAhorros,
    required this.porcentajeEmergencia,
    this.fechaActualizacion,
  });

  final int idPresupuesto;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final int diaCorte;
  final double porcentajeGastos;
  final double porcentajeDeudas;
  final double porcentajeImprevistos;
  final double porcentajeAhorros;
  final double porcentajeEmergencia;
  final DateTime? fechaActualizacion;

  double get sumaPorcentajes =>
      porcentajeGastos +
      porcentajeDeudas +
      porcentajeImprevistos +
      porcentajeAhorros +
      porcentajeEmergencia;

  factory Presupuesto.fromJson(Map<String, dynamic> json) {
    return Presupuesto(
      idPresupuesto: parseIntFlexible(json['ID_presupuesto']) ?? 0,
      nombre: json['Nombre'] as String? ?? 'Mi presupuesto',
      descripcion: json['Descripcion'] as String?,
      activo: parseBoolFlexible(json['Activo']),
      diaCorte: parseIntFlexible(json['Dia_corte']) ?? 1,
      porcentajeGastos: parseDoubleFlexible(json['Porcentaje_gastos']) ?? 0,
      porcentajeDeudas: parseDoubleFlexible(json['Porcentaje_deudas']) ?? 0,
      porcentajeImprevistos:
          parseDoubleFlexible(json['Porcentaje_imprevistos']) ?? 0,
      porcentajeAhorros: parseDoubleFlexible(json['Porcentaje_ahorros']) ?? 0,
      porcentajeEmergencia:
          parseDoubleFlexible(json['Porcentaje_emergencia']) ?? 0,
      fechaActualizacion: parseDateFlexible(json['Fecha_actualizacion']),
    );
  }

  /// Body para POST /presupuestos y PUT /presupuestos/:id.
  Map<String, dynamic> toJson() {
    return {
      'Nombre': nombre,
      'Descripcion': descripcion,
      'Dia_corte': diaCorte,
      'Porcentaje_gastos': porcentajeGastos,
      'Porcentaje_deudas': porcentajeDeudas,
      'Porcentaje_imprevistos': porcentajeImprevistos,
      'Porcentaje_ahorros': porcentajeAhorros,
      'Porcentaje_emergencia': porcentajeEmergencia,
    };
  }
}