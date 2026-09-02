/// Representa a una persona que depende económicamente del usuario.
///
/// OJO: GET /api/dependientes devuelve las claves con Mayúscula inicial
/// ("Nombre", "Relacion", "Ocupacion", "Fecha_nacimiento", "Peso_economico"),
/// menos "id_dependientes" que va en minúscula. Es un caso mixto,
/// distinto al resto de los endpoints de la app - se respeta tal cual
/// está en el controller real.
class DependienteModel {
  final int id;
  final String nombre;
  final String? relacion;
  final String? ocupacion;
  final DateTime? fechaNacimiento;
  final int pesoEconomico;

  DependienteModel({
    required this.id,
    required this.nombre,
    this.relacion,
    this.ocupacion,
    this.fechaNacimiento,
    this.pesoEconomico = 1,
  });

  factory DependienteModel.fromJson(Map<String, dynamic> json) {
    return DependienteModel(
      id: json['id_dependientes'],
      nombre: json['Nombre'] ?? '',
      relacion: json['Relacion'],
      ocupacion: json['Ocupacion'],
      fechaNacimiento: json['Fecha_nacimiento'] != null
          ? DateTime.parse(json['Fecha_nacimiento'])
          : null,
      pesoEconomico: json['Peso_economico'] ?? 1,
    );
  }
}