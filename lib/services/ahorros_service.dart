import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/ahorro_model.dart';
import 'auth_service.dart';

class AhorrosService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<List<AhorroModel>> obtenerAhorros() async {
    final token = await AuthService.instance.getToken();
    
    // Lista de endpoints a probar en orden de probabilidad
    final endpoints = [
      '/movimientos/ahorros',
      '/ahorros',
      '/metas',
      '/metas-ahorro',
      '/movimientos', // Como último recurso, traer todo y filtrar
    ];

    for (final endpoint in endpoints) {
      try {
        final data = await client.getList(endpoint, token: token);
        debugPrint('AhorrosService: Datos recibidos de $endpoint: $data');
        if (data.isNotEmpty) {
          var listado = data.map((json) => AhorroModel.fromJson(json as Map<String, dynamic>)).toList();
          // Filtramos registros que no tengan el formato de una Meta real
          // (evitamos que abonos o movimientos huérfanos salgan como tarjetas)
          return listado.where((a) => a.nombre != 'Abono a meta' && a.montoObjetivo > 0).toList();
        }
      } catch (e) {
        try {
          final respuesta = await client.get(endpoint, token: token);
          debugPrint('AhorrosService: Respuesta envuelta de $endpoint: $respuesta');
          final List? dataEnvuelto = respuesta['ahorros'] ?? 
                                     respuesta['metas'] ?? 
                                     respuesta['datos'] ?? 
                                     respuesta['data'] ??
                                     respuesta['movimientos'];
          if (dataEnvuelto != null && dataEnvuelto.isNotEmpty) {
            return dataEnvuelto.map((json) => AhorroModel.fromJson(json as Map<String, dynamic>)).toList();
          }
        } catch (_) {
          continue;
        }
      }
    }
    return [];
  }

  static Future<int> crearAhorro(AhorroModel ahorro) async {
    final token = await AuthService.instance.getToken();
    try {
      // Intento 1: Patrón /movimientos (Envoltorio)
      final respuesta = await client.post('/movimientos', token: token, body: {
        'tipo_flujo': 'Entrada',
        'subtipo_modulo': 'Ahorro',
        'datos': ahorro.toJson(),
      });
      return (respuesta['id_ahorros'] ?? respuesta['ID_detalle'] ?? respuesta['id']) as int;
    } catch (e) {
      // Intento 2: POST directo a /ahorros (Plano)
      // Si el primero dio 500, probamos este como fallback
      final respuesta = await client.post('/ahorros', token: token, body: ahorro.toJson());
      return (respuesta['id_ahorros'] ?? respuesta['id']) as int;
    }
  }

  static Future<void> actualizarAhorro(int id, AhorroModel ahorro) async {
    final token = await AuthService.instance.getToken();
    try {
      await client.put('/movimientos/ahorros/$id', token: token, body: ahorro.toJson());
    } catch (_) {
      await client.put('/ahorros/$id', token: token, body: ahorro.toJson());
    }
  }

  static Future<bool> eliminarAhorro(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      try {
        await client.delete('/movimientos/ahorros/$id', token: token);
      } catch (_) {
        await client.delete('/ahorros/$id', token: token);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> registrarAbono(AhorroModel ahorro, double montoAbono) async {
    final token = await AuthService.instance.getToken();
    
    // Calculamos el nuevo monto acumulado
    final nuevoMontoAcumulado = ahorro.montoActual + montoAbono;
    
    // Creamos una copia del modelo con el saldo actualizado
    final ahorroActualizado = AhorroModel(
      id: ahorro.id,
      nombre: ahorro.nombre,
      montoObjetivo: ahorro.montoObjetivo,
      montoActual: nuevoMontoAcumulado,
      fechaLimite: ahorro.fechaLimite,
      estado: ahorro.estado,
    );

    // Intentamos actualizar la meta directamente (esto sumará el saldo en la DB)
    try {
      await actualizarAhorro(ahorro.id!, ahorroActualizado);
      debugPrint('AhorrosService: Meta actualizada con éxito tras abono');
    } catch (e) {
      debugPrint('AhorrosService: Error al actualizar meta para abono: $e');
      throw ApiException('No se pudo actualizar el saldo de la meta. Inténtalo de nuevo.');
    }
  }
}
