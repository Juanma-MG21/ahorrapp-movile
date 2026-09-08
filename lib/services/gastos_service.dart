import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/gasto_model.dart';
import '../models/categoria_model.dart';
import '../models/dependiente_model.dart';
import 'auth_service.dart';

class GastosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<int> crearGasto(GastoModel gasto) async {
    final token = await AuthService.instance.getToken();
    final respuesta = await client.post('/movimientos', token: token, body: {
      'tipo_flujo': 'Salida',
      'subtipo_modulo': 'Gasto',
      'datos': gasto.toRequestBody(),
    });
    return respuesta['ID_detalle'] as int;
  }

  static Future<void> actualizarGasto(int id, GastoModel gasto) async {
    final token = await AuthService.instance.getToken();
    await client.put('/movimientos/gastos/$id', token: token, body: gasto.toRequestBody());
  }

  static Future<List<GastoModel>> obtenerGastos() async {
    try {
      final token = await AuthService.instance.getToken();
      final data = await client.getList('/movimientos/gastos', token: token);
      return data.map((json) => GastoModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> eliminarGasto(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.delete('/movimientos/gastos/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final token = await AuthService.instance.getToken();
      final respuesta = await client.get('/categorias', token: token);
      final List categorias = respuesta['categorias'] ?? [];
      return categorias.map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<DependienteModel>> obtenerDependientes() async {
    try {
      final token = await AuthService.instance.getToken();
      final data = await client.getList('/dependientes', token: token);
      return data.map((json) => DependienteModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
