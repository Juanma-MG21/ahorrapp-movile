import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/categoria_model.dart';
import 'auth_service.dart';

/// Servicio para consultar categorías (GET /categorias).
///
/// A diferencia de los endpoints de movimientos (que devuelven un array
/// plano), GET /categorias responde envuelto: { ok: true, categorias: [...] }
/// (ver categoriasController.js -> getCategorias), así que se usa
/// client.get() en vez de client.getList().
class CategoriasService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<List<CategoriaModel>> obtenerCategorias() async {
    final token = await AuthService.instance.getToken();
    final respuesta = await client.get('/categorias', token: token);
    final List datos = respuesta['categorias'] ?? [];
    return datos
        .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}