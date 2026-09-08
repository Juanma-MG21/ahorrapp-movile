import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/deuda_model.dart';
import 'auth_service.dart';

class DeudasService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<List<DeudaModel>> obtenerDeudas() async {
    final token = await AuthService.instance.getToken();
    final endpoints = ['/movimientos/deudas', '/deudas'];

    for (final endpoint in endpoints) {
      try {
        final data = await client.getList(endpoint, token: token);
        return data.map((json) => DeudaModel.fromJson(json as Map<String, dynamic>)).toList();
      } catch (_) {
        try {
          final respuesta = await client.get(endpoint, token: token);
          final List? dataEnvuelto = respuesta['deudas'] ?? respuesta['datos'] ?? respuesta['data'];
          if (dataEnvuelto != null) {
            return dataEnvuelto.map((json) => DeudaModel.fromJson(json as Map<String, dynamic>)).toList();
          }
        } catch (_) {
          continue;
        }
      }
    }
    return [];
  }

  static Future<int> crearDeuda(DeudaModel deuda) async {
    final token = await AuthService.instance.getToken();
    try {
      // Deuda es un flujo de Salida
      final respuesta = await client.post('/movimientos', token: token, body: {
        'tipo_flujo': 'Salida',
        'subtipo_modulo': 'Deuda',
        'datos': deuda.toRequestBody(),
      });
      return (respuesta['id_deudas'] ?? respuesta['ID_detalle'] ?? respuesta['id']) as int;
    } catch (_) {
      final respuesta = await client.post('/deudas', token: token, body: deuda.toRequestBody());
      return (respuesta['id_deudas'] ?? respuesta['id']) as int;
    }
  }

  static Future<void> actualizarDeuda(int id, DeudaModel deuda) async {
    final token = await AuthService.instance.getToken();
    try {
      await client.put('/movimientos/deudas/$id', token: token, body: deuda.toRequestBody());
    } catch (_) {
      await client.put('/deudas/$id', token: token, body: deuda.toRequestBody());
    }
  }

  static Future<bool> eliminarDeuda(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      try {
        await client.delete('/movimientos/deudas/$id', token: token);
      } catch (_) {
        await client.delete('/deudas/$id', token: token);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> pagarCuota(DeudaModel deuda) async {
    if (deuda.cuotasTotal != null && deuda.cuotasPagadas >= deuda.cuotasTotal!) {
      throw ApiException('Todas las cuotas ya han sido pagadas.');
    }

    final nuevaDeuda = DeudaModel(
      id: deuda.id,
      idSalida: deuda.idSalida,
      idCategoria: deuda.idCategoria,
      monto: deuda.monto,
      fuente: deuda.fuente,
      descripcion: deuda.descripcion,
      tasaInteres: deuda.tasaInteres,
      cuotasTotal: deuda.cuotasTotal,
      cuotasPagadas: deuda.cuotasPagadas + 1,
      fechaInicio: deuda.fechaInicio,
      fechaFin: deuda.fechaFin,
      estado: (deuda.cuotasTotal != null && deuda.cuotasPagadas + 1 >= deuda.cuotasTotal!) 
          ? 'pagada' : 'pendiente',
    );

    await actualizarDeuda(deuda.id!, nuevaDeuda);
  }
}
