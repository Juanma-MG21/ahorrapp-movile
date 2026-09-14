import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/ahorro_model.dart';
import 'auth_service.dart';

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
    try {
      final token = await AuthService.instance.getToken();
      final data = await client.getList('/movimientos/ahorros', token: token);
      return data
          .map((json) => AhorroModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Si falla, la pantalla simplemente muestra la lista vacía.
      return [];
    }
  }

  static Future<int> crearAhorro(AhorroModel ahorro) async {
    final token = await AuthService.instance.getToken();
    final respuesta = await client.post('/movimientos', token: token, body: {
      'tipo_flujo': 'Entrada',
      'subtipo_modulo': 'Ahorro',
      'datos': ahorro.toJson(),
    });
    return respuesta['ID_detalle'] as int;
  }

  static Future<void> actualizarAhorro(int id, AhorroModel ahorro) async {
    final token = await AuthService.instance.getToken();
    await client.put('/movimientos/ahorros/$id', token: token, body: ahorro.toJson());
  }

  static Future<bool> eliminarAhorro(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.delete('/movimientos/ahorros/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
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
  static Future<void> registrarAbono(AhorroModel ahorro, double montoAbono) async {
    if (ahorro.id == null) {
      throw ApiException('No se puede abonar un ahorro sin id.');
    }

    final token = await AuthService.instance.getToken();
    await client.patch(
      '/movimientos/ahorros/${ahorro.id}/abonar',
      token: token,
      body: {'monto': montoAbono},
    );
  }
}
