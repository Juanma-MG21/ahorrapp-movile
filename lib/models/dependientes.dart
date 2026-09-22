// NOTA DE REVISIÓN: este archivo define una clase `DependienteModel`
// duplicada e incompleta (sin fromJson/toJson) respecto a la versión
// real usada en todo el proyecto: lib/models/dependiente_model.dart.
// Ningún archivo importa este archivo actualmente, por lo que no rompe
// la compilación, pero se deja esta nota para evitar que alguien lo
// use por error en vez de lib/models/dependiente_model.dart, y como
// candidato a eliminar en una limpieza futura.
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
