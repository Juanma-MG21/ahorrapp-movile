import 'offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/ingreso_model.dart';
import '../models/categoria_model.dart';
import 'offline_query_service.dart';

class IngresosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  /// Crea un ingreso nuevo (POST /movimientos).
  /// Devuelve el id generado (id_ingresos) para que la pantalla pueda
  /// armar el IngresoModel completo localmente.
  static Future<int> crearIngreso(IngresoModel ingreso) async {
    return OfflineSyncService.instance.create('/movimientos/ingresos', {
      'tipo_flujo': 'Entrada', 'subtipo_modulo': 'Ingreso',
      'datos': ingreso.toRequestBody(),
    });
  }

  /// Actualiza un ingreso existente (PUT /movimientos/ingresos/:id).
  static Future<void> actualizarIngreso(int id, IngresoModel ingreso) async {
    if (id <= 0) {
      await OfflineSyncService.instance.correctRejected(id, '/movimientos/ingresos', {
        'tipo_flujo': 'Entrada', 'subtipo_modulo': 'Ingreso', 'datos': ingreso.toRequestBody(),
      });
      return;
    }
    await OfflineQueryService.instance.onlineMutation(
        '/movimientos/ingresos',
        (token) => client.put('/movimientos/ingresos/$id',
            token: token, body: ingreso.toRequestBody()));
  }

  /// Trae la lista de ingresos del usuario (GET /movimientos/ingresos).
  static Future<List<IngresoModel>> obtenerIngresos() async {
    return OfflineQueryService.instance
        .query('/movimientos/ingresos', client, IngresoModel.fromJson);
  }

  /// Elimina un ingreso (DELETE /movimientos/ingresos/:id).
  /// Devuelve true si se eliminó correctamente.
  static Future<bool> eliminarIngreso(int id) async {
    if (id <= 0) throw ApiException('No se puede eliminar un registro pendiente de sincronizar.');
    await OfflineQueryService.instance.onlineMutation('/movimientos/ingresos',
        (token) => client.delete('/movimientos/ingresos/$id', token: token));
    return true;
  }

  /// Trae las categorías disponibles (GET /categorias).
  static Future<List<CategoriaModel>> obtenerCategorias() async {
    return OfflineQueryService.instance.query(
        '/categorias', client, CategoriaModel.fromJson,
        listKey: 'categorias');
  }
}
