/// Dependiente tal como lo devuelve GET /auth/PanelDependientes
/// (todos los dependientes del sistema, de todos los usuarios).
class DependienteAdmin {
  DependienteAdmin({
    required this.id,
    required this.nombre,
    required this.relacion,
    required this.ocupacion,
    required this.fechaNacimiento,
    required this.idUsuario,
    required this.usuarioNombre,
  });

  final int id;
  final String nombre;
  final String? relacion;
  final String? ocupacion;
  final DateTime? fechaNacimiento;
  final int idUsuario;
  final String usuarioNombre;

  String get inicial => nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

  factory DependienteAdmin.fromJson(Map<String, dynamic> json) {
    DateTime? fecha;
    final fechaRaw = json['Fecha_nacimiento']?.toString();
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      fecha = DateTime.tryParse(fechaRaw);
    }

    return DependienteAdmin(
      id: json['id_dependientes'] is int
          ? json['id_dependientes'] as int
          : int.tryParse('${json['id_dependientes']}') ?? 0,
      nombre: json['Nombre']?.toString() ?? '',
      relacion: json['Relacion']?.toString(),
      ocupacion: json['Ocupacion']?.toString(),
      fechaNacimiento: fecha,
      idUsuario: json['ID_usuario'] is int
          ? json['ID_usuario'] as int
          : int.tryParse('${json['ID_usuario']}') ?? 0,
      usuarioNombre: json['usuario_nombre']?.toString() ?? '',
    );
  }
}
