import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/ingreso_model.dart';

class IngresosService {

  static Future<void> crearIngreso(IngresoModel ingreso) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/movimientos');

    late final http.Response respuesta;
    try {
      respuesta = await http.post(
        uri,
        headers: ApiConfig.authHeaders,
        body: jsonEncode(ingreso.toRequestBody()),
      );
    } catch (_) {
      throw Exception('No se pudo conectar con el servidor');
    }

    final ok = respuesta.statusCode >= 200 && respuesta.statusCode < 300;
    if (!ok) {
      String mensaje = 'Error al guardar el ingreso';
      try {
        final data = jsonDecode(respuesta.body);
        if (data is Map && data['mensaje'] != null) {
          mensaje = data['mensaje'];
        }
      } catch (_) {}
      throw Exception(mensaje);
    }
  }

  /// Trae las categorías disponibles (GET /categorias),
  static Future<List<CategoriaModel>> obtenerCategorias() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/categorias');
    try {
      final respuesta = await http.get(uri, headers: ApiConfig.authHeaders);
      if (respuesta.statusCode != 200) return [];
      final List data = jsonDecode(respuesta.body);
      return data
          .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Si falla, la pantalla simplemente no muestra categorías y el
      // usuario puede guardar el ingreso sin categoría.
      return [];
    }
  }
}