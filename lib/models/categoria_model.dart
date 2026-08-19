class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activa;
  final bool sistema;
  final bool esGlobal;
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
