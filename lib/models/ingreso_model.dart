// lib/models/ingreso_model.dart
//
// Representa un "Ingreso" tal como lo espera tu backend (movimientosController.js).
// OJO: esto NO es la tabla completa de la BD, es solo lo que el formulario
// necesita capturar y lo que se manda en el body del POST /movimientos.

class IngresoModel {
  final double monto;
  final String? descripcion;
  final String? fuente;
  final DateTime fechaRegistro;
  final int? idCategoria;

  IngresoModel({
    required this.monto,
    this.descripcion,
    this.fuente,
    required this.fechaRegistro,
    this.idCategoria,
  });

  /// Convierte el modelo al formato exacto que espera el endpoint:
  /// { tipo_flujo, subtipo_modulo, datos: {...} }
  Map<String, dynamic> toRequestBody() {
    return {
      'tipo_flujo': 'Entrada',
      'subtipo_modulo': 'Ingreso',
      'datos': {
        'monto': monto,
        'descripcion': descripcion,
        'fuente': fuente,
        // El backend espera fecha en formato YYYY-MM-DD
        'fecha_registro':
        '${fechaRegistro.year.toString().padLeft(4, '0')}-'
            '${fechaRegistro.month.toString().padLeft(2, '0')}-'
            '${fechaRegistro.day.toString().padLeft(2, '0')}',
        'id_categoria': idCategoria,
      },
    };
  }
}

/// Modelo simple para las categorías que vienen de GET /categorias.
/// Lo dejamos aquí para no crear un archivo aparte todavía; si tu app
/// crece puedes moverlo a su propio models/categoria_model.dart.
class CategoriaModel {
  final int id;
  final String nombre;

  CategoriaModel({required this.id, required this.nombre});

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] ?? json['ID_categoria'],
      nombre: json['nombre'] ?? json['Nombre'] ?? '',
    );
  }
}