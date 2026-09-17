/// Usuario tal como lo devuelve GET /auth/PanelUsuarios (solo admin/superuser).
class UsuarioAdmin {
  UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.idRol,
    required this.cargo,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final int? idRol;
  final String? cargo; // 'user' | 'admin' | 'superuser'

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return ('$n$a').toUpperCase();
  }

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) {
    return UsuarioAdmin(
      id: json['ID_usuario'] is int
          ? json['ID_usuario'] as int
          : int.tryParse('${json['ID_usuario']}') ?? 0,
      nombre: json['Nombre']?.toString() ?? '',
      apellido: json['Apellido']?.toString() ?? '',
      email: json['Email']?.toString() ?? '',
      idRol: json['ID_rol'] == null
          ? null
          : (json['ID_rol'] is int
              ? json['ID_rol'] as int
              : int.tryParse('${json['ID_rol']}')),
      cargo: json['Cargo']?.toString(),
    );
  }

  UsuarioAdmin copyWith({
    String? nombre,
    String? apellido,
    String? email,
    int? idRol,
    String? cargo,
  }) {
    return UsuarioAdmin(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      idRol: idRol ?? this.idRol,
      cargo: cargo ?? this.cargo,
    );
  }
}

/// Los 3 roles fijos del sistema (tabla `rol`), usados en el selector
/// de rol que solo ve un superuser.
class RolOpcion {
  const RolOpcion(this.id, this.nombre);
  final int id;
  final String nombre;
}

const List<RolOpcion> kRolesDisponibles = [
  RolOpcion(1, 'user'),
  RolOpcion(2, 'admin'),
  RolOpcion(3, 'superuser'),
];
