// Modelo que refleja 1 a 1 la tabla `dependientes` de tu base de
// datos: mismos nombres de columna (en minúscula, snake_case) como
// llaves de JSON, mismos tipos.
// PRUEBAS
// OJO: esto es distinto al objeto que veíamos en PanelDependientes.jsx
// (que traía `usuario_nombre` en vez de `id_usuario`, y con mayúsculas).
// Ese es un DTO armado por una consulta con JOIN para mostrar en
// pantalla; ESTE modelo es la tabla cruda, más apto para crear/editar
// un dependiente. Si tu backend expone un endpoint que devuelve las
// columnas tal cual (sin alias), este modelo calza directo con eso.

class Dependiente {
  final int idDependientes; // id_dependientes · int4 · llave primaria
  final int idUsuario; // id_usuario · int4 · llave foránea al usuario dueño
  final String nombre; // nombre · varchar
  final String? relacion; // relacion · varchar (nullable en la tabla: rombo vacío en tu captura)
  final String? ocupacion; // ocupacion · varchar (nullable)
  final DateTime? fechaNacimiento; // fecha_nacimiento · date (nullable)
  final int? pesoEconomico; // peso_economico · int2 (nullable)

  // Constructor normal: todos los campos `final`, algunos `required`
  // (los que la tabla marca como NOT NULL con el rombo relleno ◆ en tu
  // captura) y otros opcionales (rombo vacío ◇ = permite NULL).
  const Dependiente({
    required this.idDependientes,
    required this.idUsuario,
    required this.nombre,
    this.relacion,
    this.ocupacion,
    this.fechaNacimiento,
    this.pesoEconomico,
  });

  // `fromJson`: construye el objeto Dart a partir del Map que sale de
  // `jsonDecode(response.body)`. Uso `as int?`/`as String?` (con `?`)
  // en los campos nullable para que, si el backend manda `null`, Dart
  // no truene — simplemente el campo queda en `null`.
  factory Dependiente.fromJson(Map<String, dynamic> json) {
    return Dependiente(
      idDependientes: json['id_dependientes'] as int,
      idUsuario: json['id_usuario'] as int,
      nombre: json['nombre'] as String,
      relacion: json['relacion'] as String?,
      ocupacion: json['ocupacion'] as String?,
      // La fecha puede llegar como string ISO ("2015-03-20" o
      // "2015-03-20T00:00:00.000Z", según cómo la serialice tu driver
      // mysql2). `DateTime.tryParse` intenta convertirla y devuelve
      // `null` si el formato no calza, en vez de lanzar una excepción
      // como haría `DateTime.parse`.
      fechaNacimiento: json['fecha_nacimiento'] != null ? DateTime.tryParse(json['fecha_nacimiento'] as String) : null,
      pesoEconomico: json['peso_economico'] as int?,
    );
  }

  // `toJson`: el camino inverso — lo necesitas para el `body` de un
  // POST/PUT cuando crees o edites un dependiente (`jsonEncode` exige
  // un Map, no un objeto Dart directamente).
  Map<String, dynamic> toJson() {
    return {
      'id_dependientes': idDependientes,
      'id_usuario': idUsuario,
      'nombre': nombre,
      'relacion': relacion,
      'ocupacion': ocupacion,
      // `toIso8601String()` formatea la fecha de vuelta a texto; si es
      // null, mando null tal cual con el operador `?.` (llama al
      // método solo si el valor no es null).
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'peso_economico': pesoEconomico,
    };
  }

  // Útil para formularios de edición: crea una COPIA del objeto
  // cambiando solo los campos que le pases. Como todos los campos son
  // `final` (inmutables), esta es la forma idiomática en Dart de
  // "actualizar" un objeto sin mutarlo directamente.
  Dependiente copyWith({
    String? nombre,
    String? relacion,
    String? ocupacion,
    DateTime? fechaNacimiento,
    int? pesoEconomico,
  }) {
    return Dependiente(
      idDependientes: idDependientes,
      idUsuario: idUsuario,
      nombre: nombre ?? this.nombre,
      relacion: relacion ?? this.relacion,
      ocupacion: ocupacion ?? this.ocupacion,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      pesoEconomico: pesoEconomico ?? this.pesoEconomico,
    );
  }
}