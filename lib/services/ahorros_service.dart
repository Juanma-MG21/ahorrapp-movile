import 'offline_sync_service.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/ahorro_model.dart';
import 'offline_query_service.dart';

/// Rutas reales confirmadas contra movimientosRoutes.js:
///   POST   /movimientos                    -> crearMovimiento (genérico)
///   GET    /movimientos/ahorros            -> getAhorros
///   PUT    /movimientos/ahorros/:id        -> updateAhorros
///   DELETE /movimientos/ahorros/:id        -> deleteAhorros
///   PATCH  /movimientos/ahorros/:id/abonar -> abonarAhorro
///
/// No existen (y nunca existieron) endpoints `/ahorros`, `/metas` o
/// `/metas-ahorro`: los fallbacks que había antes a esas rutas apuntaban a
/// nada, así que cualquier error real del endpoint correcto (ej. una
/// validación del backend) quedaba enmascarado por un 404 del endpoint
/// falso, y el usuario veía un mensaje de error genérico sin sentido.
class AhorrosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<List<AhorroModel>> obtenerAhorros() async {
    return OfflineQueryService.instance
        .query('/movimientos/ahorros', client, AhorroModel.fromJson);
  }

  static Future<int> crearAhorro(AhorroModel ahorro) async {
    return OfflineSyncService.instance.create('/movimientos/ahorros', {
      'tipo_flujo': 'Entrada', 'subtipo_modulo': 'Ahorro',
      'datos': ahorro.toJson(),
    });
  }

  static Future<void> actualizarAhorro(int id, AhorroModel ahorro) async {
    if (id <= 0) {
      await OfflineSyncService.instance.correctRejected(id, '/movimientos/ahorros', {
        'tipo_flujo': 'Entrada', 'subtipo_modulo': 'Ahorro', 'datos': ahorro.toJson(),
      });
      return;
    }
    await OfflineQueryService.instance.onlineMutation(
        '/movimientos/ahorros',
        (token) => client.put('/movimientos/ahorros/$id',
            token: token, body: ahorro.toJson()));
  }

  static Future<bool> eliminarAhorro(int id) async {
    if (id <= 0) throw ApiException('No se puede eliminar un registro pendiente de sincronizar.');
    await OfflineQueryService.instance.onlineMutation('/movimientos/ahorros',
        (token) => client.delete('/movimientos/ahorros/$id', token: token));
    return true;
  }

  /// Registra un abono usando el endpoint dedicado del backend
  /// (PATCH /movimientos/ahorros/:id/abonar), que valida atómicamente que
  /// el abono no exceda la meta, deja constancia en el historial
  /// (abonos_ahorro, usado por /api/reportes/ahorros) y dispara la
  /// notificación de "meta alcanzada" cuando corresponde.
  ///
  /// Antes esto se hacía calculando el nuevo monto_acumulado en el cliente
  /// y sobrescribiendo todo el registro con un PUT (actualizarAhorro), lo
  /// que se saltaba esa validación, el historial de abonos y la
  /// notificación, además de ser vulnerable a condiciones de carrera.
  static Future<void> registrarAbono(
      AhorroModel ahorro, double montoAbono) async {
    if (ahorro.id == null || ahorro.id! <= 0) {
      throw ApiException('Sincroniza el ahorro antes de registrar abonos con conexión.');
    }
    await OfflineQueryService.instance.onlineMutation(
        '/movimientos/ahorros',
        (token) => client.patch('/movimientos/ahorros/${ahorro.id}/abonar',
            token: token, body: {'monto': montoAbono}));
  }
}
