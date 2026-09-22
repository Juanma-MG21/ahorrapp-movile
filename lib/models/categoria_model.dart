/// Representa una categoría de gasto o ingreso.
///
/// Combina las columnas reales de la tabla `categorias` (id, nombre,
/// descripcion, activa, es_global, sistema, id_usuario) con un dato
/// calculado (total_movimientos) que probablemente viene de un JOIN
/// en el backend — mismo patrón que ya usamos en DependienteModel para
/// separar "datos crudos" de "datos derivados".
class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activa;
  final bool sistema;
  final bool esGlobal; // Si es true, la ven todos los usuarios.
  final int? idUsuario;
  final num totalMovimientos;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activa = true,
    this.sistema = false,
    this.esGlobal = false,
    this.idUsuario,
    this.totalMovimientos = 0,
  });

  /// Algunos backends (típicamente sobre MySQL) devuelven columnas
  /// booleanas como 0/1 en vez de true/false; este helper normaliza
  /// ambos casos para que fromJson no falle con un cast directo, y
  /// conserva un valor por defecto cuando la clave no viene en el JSON.
  static bool _aBooleano(dynamic valor, {bool defaultValue = false}) {
    if (valor == null) return defaultValue;
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    return defaultValue;
  }

  /// Mapea los datos que devuelve el backend (GET /api/categorias).
  /// El backend responde con claves en minúscula (no confundir con el
  /// patrón ID_/Monto en mayúscula que usan otros módulos).
  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      activa: _aBooleano(json['activa'], defaultValue: true),
      sistema: _aBooleano(json['sistema']),
      esGlobal: _aBooleano(json['es_global']),
      idUsuario: json['id_usuario'] as int?,
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
      sistema: sistema,
      esGlobal: esGlobal,
      idUsuario: idUsuario,
      totalMovimientos: totalMovimientos ?? this.totalMovimientos,
    );
  }

  bool get esSistemaOGlobal => esGlobal || sistema;
}