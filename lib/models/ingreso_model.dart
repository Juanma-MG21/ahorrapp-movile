
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