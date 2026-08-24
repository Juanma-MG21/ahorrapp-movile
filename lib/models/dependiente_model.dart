class DependienteModel {
  final int id;
  final String nombre;
  final String? relacion;
  final String? ocupacion;
  final DateTime? fechaNacimiento;
  final int pesoEconomico;
  final int idUsuario;

  DependienteModel({
    required this.id,
    required this.nombre,
    this.relacion,
    this.ocupacion,
    this.fechaNacimiento,
    this.pesoEconomico = 1,
    required this.idUsuario,
  });

  factory DependienteModel.fromMap(Map<String, dynamic> map) {
    return DependienteModel(
      id: map['id_dependientes'],
      nombre: map['nombre'] ?? '',
      relacion: map['relacion'],
      ocupacion: map['ocupacion'],
      fechaNacimiento: map['fecha_nacimiento'] != null 
          ? DateTime.parse(map['fecha_nacimiento']) 
          : null,
      pesoEconomico: map['peso_economico'] ?? 1,
      idUsuario: map['id_usuario'],
    );
  }
}
