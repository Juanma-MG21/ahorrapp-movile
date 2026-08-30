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

  /// Mapea los datos desde Supabase a este modelo.
  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id_categoria'],
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      activa: map['activa'] ?? true,
      sistema: map['sistema'] ?? false,
      esGlobal: map['es_global'] ?? false,
      idUsuario: map['id_usuario'],
    );
  }
}
