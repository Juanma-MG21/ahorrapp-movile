import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/imprevisto_model.dart';
import '../models/categorias_model.dart';
import 'auth_service.dart';

class ImprevistosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  /// Crea un nuevo imprevisto (POST /movimientos).
  /// Se registra como una 'Salida' con subtipo 'Imprevisto'.
  static Future<int> crearImprevisto(ImprevistoModel imprevisto) async {
    final token = await AuthService.instance.getToken();

    final respuesta = await client.post(
      '/movimientos',
      token: token,
      body: {
        'tipo_flujo': 'Salida',
        'subtipo_modulo': 'Imprevisto',
        'datos': imprevisto.toRequestBody(),
      },
    );

    return respuesta['ID_detalle'] as int;
  }

  /// Actualiza un imprevisto existente (PUT /movimientos/imprevistos/:id).
  static Future<void> actualizarImprevisto(int id, ImprevistoModel imprevisto) async {
    final token = await AuthService.instance.getToken();

    await client.put(
      '/movimientos/imprevistos/$id',
      token: token,
      body: imprevisto.toRequestBody(),
    );
  }

  /// Trae la lista de imprevistos del usuario (GET /movimientos/imprevistos).
  static Future<List<ImprevistoModel>> obtenerImprevistos() async {
    try {
      final token = await AuthService.instance.getToken();
      final data = await client.getList('/movimientos/imprevistos', token: token);

      return data
          .map((json) => ImprevistoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Elimina un imprevisto (DELETE /movimientos/imprevistos/:id).
  static Future<bool> eliminarImprevisto(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.delete('/movimientos/imprevistos/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Trae las categorías disponibles.
  static Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final token = await AuthService.instance.getToken();
      final respuesta = await client.get('/categorias', token: token);

      final List categorias = respuesta['categorias'] ?? [];
      return categorias
          .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
