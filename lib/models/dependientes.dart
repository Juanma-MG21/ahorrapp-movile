class DependienteModel {
  final int? id;
  final String nombre;
  final String? relacion;
  final String? ocupacion;
  final DateTime? fechaNacimiento;
  final int? pesoEconomico;

  DependienteModel({
    this.id,
    required this.nombre,
    this.relacion,
    this.ocupacion,
    this.fechaNacimiento,
    this.pesoEconomico,
  });
}
