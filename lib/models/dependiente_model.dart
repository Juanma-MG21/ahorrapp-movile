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

  // Aportado por Santiago: lo necesita `actualizarDependiente` en el
  // servicio para convertir el objeto Dart de vuelta a un Map que
  // `jsonEncode` pueda mandar como body del PUT. Usa claves en
  // minúscula/snake_case porque así las espera el backend Express
  // al RECIBIR datos (distinto a como las ENVÍA, que es con
  // mayúscula inicial — asimetría típica si el controller no
  // normaliza el nombrado).
  //
  // OJO: esto asume que el endpoint PUT realmente espera esas claves
  // en snake_case. Falta verificarlo contra dependientes_service.dart
  // (o el controller real) cuando lo revisemos.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'relacion': relacion,
      'ocupacion': ocupacion,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'peso_economico': pesoEconomico,
    };
  }
}