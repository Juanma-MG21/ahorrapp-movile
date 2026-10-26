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

  Map<String, dynamic> toJson() {
    return {
      'Nombre': nombre.trim(),
      if (relacion != null) 'Relacion': relacion!.trim(),
      if (ocupacion != null) 'Ocupacion': ocupacion!.trim(),
      if (fechaNacimiento != null)
        'Fecha_nacimiento':
            '${fechaNacimiento!.year.toString().padLeft(4, '0')}-${fechaNacimiento!.month.toString().padLeft(2, '0')}-${fechaNacimiento!.day.toString().padLeft(2, '0')}',
      if (pesoEconomico != null) 'Peso_economico': pesoEconomico,
    };
  }

  String? get validationError {
    if (nombre.trim().isEmpty) return 'Ingresa el nombre del dependiente';
    if (relacion == null || relacion!.trim().isEmpty) {
      return 'Ingresa la relación con el dependiente';
    }
    if (nombre.trim().length > 100 || relacion!.trim().length > 100) {
      return 'El nombre y la relación admiten hasta 100 caracteres';
    }
    if (ocupacion != null && ocupacion!.trim().length > 150) {
      return 'La ocupación admite hasta 150 caracteres';
    }
    final peso = pesoEconomico;
    if (peso == null || peso < 1 || peso > 5) {
      return 'El peso económico debe ser un número entero entre 1 y 5';
    }
    return null;
  }

  static int? parseCreatedId(Map<String, dynamic> response) {
    final nested = response['dependiente'];
    final value = response['id_dependientes'] ??
        (nested is Map ? nested['id_dependientes'] : null);
    return value is int && value > 0 ? value : null;
  }
}
