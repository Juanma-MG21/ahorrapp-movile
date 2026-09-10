class DependienteModel {
  // Antes: `final int id;` (no admitía null). Lo cambio a `int?`
  // porque cuando CREAS un dependiente nuevo, todavía no existe un id
  // (lo genera el backend al guardar) — el objeto Dart necesita poder
  // representar "todavía no tiene id" con `null`.
  final int? id;
  final String nombre;
  final String? relacion;
  final String? ocupacion;
  final DateTime? fechaNacimiento;

  // Mismo caso: lo hago `int?` porque en la pantalla, `pesoEconomico`
  // sale de `int.tryParse(...)`, que devuelve `int?` (null si el
  // usuario no escribió nada o escribió algo inválido).
  final int? pesoEconomico;

  DependienteModel({
    this.id, // ya no lleva `required`: puede faltar al crear
    required this.nombre,
    this.relacion,
    this.ocupacion,
    this.fechaNacimiento,
    this.pesoEconomico, // sin `= 1`: si no llega, queda en null, no en 1
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
      pesoEconomico: json['Peso_economico'],
    );
  }

  // NUEVO: no existía. Lo necesita `actualizarDependiente` en el
  // servicio para convertir el objeto Dart de vuelta a un Map que
  // `jsonEncode` pueda mandar como body del PUT. Uso las claves en
  // minúscula/snake_case porque así las espera tu backend Express
  // al RECIBIR datos (distinto a como las ENVÍA, que es con
  // mayúscula inicial — asimetría típica si el controller no
  // normaliza el nombrado).
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