/// Representa una categoría de gasto o ingreso.
class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activa;
  final bool sistema;
  final bool esGlobal; // Si es true, la ven todos los usuarios.
  final int? idUsuario;

  CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activa = true,
    this.sistema = false,
    this.esGlobal = false,
    this.idUsuario,
  });

  /// Mapea los datos que devuelve el backend (GET /api/categorias).
  /// El backend responde con claves en minúscula (no confundir con el
  /// patrón ID_/Monto en mayúscula que usan otros módulos).
  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      activa: json['activa'] ?? true,
      sistema: json['sistema'] ?? false,
      esGlobal: json['es_global'] ?? false,
      idUsuario: json['id_usuario'],
    );
  }
}