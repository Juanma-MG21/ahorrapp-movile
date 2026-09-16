import 'reporte_json_utils.dart';

class PeriodoPresupuesto {
  final int idPeriodo;
  final int idPresupuesto;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String perfilNombre;

  PeriodoPresupuesto({
    required this.idPeriodo,
    required this.idPresupuesto,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.perfilNombre,
  });

  factory PeriodoPresupuesto.fromJson(Map<String, dynamic> json) {
    return PeriodoPresupuesto(
      idPeriodo: parseInt(json['ID_periodo']),
      idPresupuesto: parseInt(json['ID_presupuesto']),
      fechaInicio: parseFecha(json['Fecha_inicio']),
      fechaFin: parseFecha(json['Fecha_fin']),
      estado: json['Estado'] as String? ?? '',
      perfilNombre: json['Perfil_nombre'] as String? ?? '',
    );
  }
}