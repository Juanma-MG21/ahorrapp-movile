// Modelo de categoría: combina las columnas reales de la tabla
// `categorias` (id, nombre, descripcion, activa, es_global, sistema)
// con un dato calculado (total_movimientos) que probablemente viene
// de un JOIN en el backend — igual que el patrón que ya usamos en
// DependienteModel para separar "datos crudos" de "datos derivados".

class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activa;
  final bool esGlobal;
  final bool sistema;
  final num totalMovimientos;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activa,
    required this.esGlobal,
    required this.sistema,
    this.totalMovimientos = 0,
  });

  static bool _aBooleano(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    return false;
  }

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activa: _aBooleano(json['activa']),
      esGlobal: _aBooleano(json['es_global']),
      sistema: _aBooleano(json['sistema']),
      totalMovimientos: (json['total_movimientos'] as num?) ?? 0,
    );
  }

  CategoriaModel copyWith({
    String? nombre,
    String? descripcion,
    bool? activa,
    num? totalMovimientos,
  }) {
    return CategoriaModel(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activa: activa ?? this.activa,
      esGlobal: esGlobal,
      sistema: sistema,
      totalMovimientos: totalMovimientos ?? this.totalMovimientos,
    );
  }

  bool get esSistemaOGlobal => esGlobal || sistema;
}