// Modelo PROVISIONAL: representa una categoría ya combinada con el
// total de movimientos de las 5 fuentes (gastos, ingresos, ahorros,
// imprevistos, deudas), tal como hace tu `useEffect` en React.
//// PRUEBA TODAVIA SE SIGUE TESTEANDO 
// Cuando me pases la tabla real de `categorias`, este archivo es el
// que vamos a reemplazar/ajustar — probablemente separando "columnas
// de la tabla" (id, nombre, descripcion, activa, es_global) de "datos
// calculados" (total_movimientos), igual que hicimos con Dependiente
// vs. el DTO de PanelDependientes.

class CategoriaData {
  final int id;
  final String nombre;
  final String? descripcion;
  // En JS comparabas con `== 1 || === true` porque el backend a veces
  // manda 1/0 (típico de MySQL) y a veces true/false. En Dart preferí
  // resolver esa ambigüedad UNA sola vez en `fromJson` (ver abajo) y
  // que el resto del código siempre reciba un `bool` limpio.
  final bool activa;
  final bool esGlobal;
  final bool sistema;
  final num totalMovimientos;

  const CategoriaData({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activa,
    required this.esGlobal,
    required this.sistema,
    this.totalMovimientos = 0,
  });

  // Función auxiliar reusable: convierte cualquier valor "verdadero
  // ambiguo" (1, "1", true) en un bool real. La marco como `static`
  // porque no depende de una instancia particular de CategoriaData.
  static bool _aBooleano(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    return false;
  }

  factory CategoriaData.fromJson(Map<String, dynamic> json) {
    return CategoriaData(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activa: _aBooleano(json['activa']),
      esGlobal: _aBooleano(json['es_global']),
      sistema: _aBooleano(json['sistema']),
      // `?? 0` cubre el caso en que el campo ni siquiera venga en el
      // JSON (null), igual que tu `Number(cat.total_gastos || 0)`.
      totalMovimientos: (json['total_movimientos'] as num?) ?? 0,
    );
  }

  // `copyWith` para las actualizaciones optimistas de UI (cuando
  // deshabilitas/habilitas y quieres reflejar el cambio en pantalla
  // sin esperar a recargar toda la lista), igual que tu
  // `prev.map(c => c.id === id ? { ...c, activa: false } : c)`.
  CategoriaData copyWith({
    String? nombre,
    String? descripcion,
    bool? activa,
    num? totalMovimientos,
  }) {
    return CategoriaData(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activa: activa ?? this.activa,
      esGlobal: esGlobal,
      sistema: sistema,
      totalMovimientos: totalMovimientos ?? this.totalMovimientos,
    );
  }

  // Traducción directa de tu función suelta `esSistema(cat)`.
  // Como es una propiedad derivada del objeto mismo, en Dart tiene
  // más sentido como `getter` (`bool get esSistema`) que como función
  // aparte: se lee como `categoria.esSistema`, sin paréntesis.
  bool get esSistemaOGlobal => esGlobal || sistema;
}