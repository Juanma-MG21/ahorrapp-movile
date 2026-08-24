class Producto {
  final int id;
  final String nombre;
  final String descripcion;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      nombre: json['title'] ?? 'Sin nombre',
      descripcion: json['body'] ?? 'Sin descripción',
    );
  }
}
