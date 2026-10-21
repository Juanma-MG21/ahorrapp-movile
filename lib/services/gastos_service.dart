import 'offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/gasto_model.dart';
import '../models/categoria_model.dart';
import '../models/dependiente_model.dart';
import 'offline_query_service.dart';

class GastosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<int> crearGasto(GastoModel gasto) async {
    return OfflineSyncService.instance.create('/movimientos/gastos', {
      'tipo_flujo': 'Salida', 'subtipo_modulo': 'Gasto',
      'datos': gasto.toRequestBody(),
    });
  }

  static Future<void> actualizarGasto(int id, GastoModel gasto) async {
    if (id <= 0) {
      await OfflineSyncService.instance.correctRejected(id, '/movimientos/gastos', {
        'tipo_flujo': 'Salida', 'subtipo_modulo': 'Gasto', 'datos': gasto.toRequestBody(),
      });
      return;
    }
    await OfflineQueryService.instance.onlineMutation(
        '/movimientos/gastos',
        (token) => client.put('/movimientos/gastos/$id',
            token: token, body: gasto.toRequestBody()));
  }

  static Future<List<GastoModel>> obtenerGastos() async {
    return OfflineQueryService.instance
        .query('/movimientos/gastos', client, GastoModel.fromJson);
  }

  static Future<bool> eliminarGasto(int id) async {
    if (id <= 0) throw ApiException('No se puede eliminar un registro pendiente de sincronizar.');
    await OfflineQueryService.instance.onlineMutation('/movimientos/gastos',
        (token) => client.delete('/movimientos/gastos/$id', token: token));
    return true;
  }

  static Future<List<CategoriaModel>> obtenerCategorias() async {
    return OfflineQueryService.instance.query(
        '/categorias', client, CategoriaModel.fromJson,
        listKey: 'categorias');
  }

  static Future<List<DependienteModel>> obtenerDependientes() async {
    return OfflineQueryService.instance
        .query('/dependientes', client, DependienteModel.fromJson);
  }
}
