import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/deuda_model.dart';
import 'auth_service.dart';

/// Rutas reales confirmadas contra movimientosRoutes.js:
///   POST   /movimientos                     -> crearMovimiento (genérico)
///   GET    /movimientos/deudas               -> getDeudas
///   PUT    /movimientos/deudas/:id           -> updateDeudas
///   DELETE /movimientos/deudas/:id           -> deleteDeudas
///   PATCH  /movimientos/deudas/:id/abonar    -> abonarDeuda
///
/// No existe (y nunca existió) un endpoint `/deudas` a secas: los fallbacks
/// que había antes a esa ruta apuntaban a nada, así que cualquier error real
/// del endpoint correcto quedaba enmascarado por un 404 del endpoint falso.
class DeudasService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<List<DeudaModel>> obtenerDeudas() async {
    final token = await AuthService.instance.getToken();
    final data = await client.getList('/movimientos/deudas', token: token);
    return data
        .map((json) => DeudaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<int> crearDeuda(DeudaModel deuda) async {
    final token = await AuthService.instance.getToken();
    final respuesta = await client.post('/movimientos', token: token, body: {
      'tipo_flujo': 'Salida',
      'subtipo_modulo': 'Deuda',
      'datos': deuda.toRequestBody(),
    });
    return respuesta['ID_detalle'] as int;
  }

  static Future<void> actualizarDeuda(int id, DeudaModel deuda) async {
    final token = await AuthService.instance.getToken();
    await client.put('/movimientos/deudas/$id', token: token, body: deuda.toRequestBody());
  }

  static Future<bool> eliminarDeuda(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.delete('/movimientos/deudas/$id', token: token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Registra el pago de una o más cuotas usando el endpoint dedicado del
  /// backend (PATCH /movimientos/deudas/:id/abonar), que calcula
  /// internamente `cuotas_pagadas` y el nuevo `estado` de forma atómica.
  ///
  /// Antes esto se hacía reconstruyendo manualmente todo el DeudaModel con
  /// cuotasPagadas + 1 y mandando un PUT completo (actualizarDeuda), lo cual
  /// duplicaba lógica que el backend ya resuelve mejor y sin condiciones de
  /// carrera.
  static Future<void> pagarCuota(DeudaModel deuda, {int cuotas = 1}) async {
    if (deuda.id == null) {
      throw ApiException('No se puede abonar una deuda sin id.');
    }
    if (deuda.cuotasTotal != null &&
        deuda.cuotasPagadas + cuotas > deuda.cuotasTotal!) {
      throw ApiException(
        'Quedan ${deuda.cuotasTotal! - deuda.cuotasPagadas} cuota(s) por pagar.',
      );
    }

    final token = await AuthService.instance.getToken();
    await client.patch(
      '/movimientos/deudas/${deuda.id}/abonar',
      token: token,
      body: {'cuotas': cuotas},
    );
  }
}
