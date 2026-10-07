import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/notificacion_model.dart';
import 'auth_service.dart';

class NotificacionesApiService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  /// Trae la lista (GET /notificaciones). Si falla, lanza el error
  /// para que la pantalla pueda mostrarlo.
  static Future<List<NotificacionModel>> obtenerNotificaciones() async {
    final token = await AuthService.instance.getToken();
    final respuesta = await client.get('/notificaciones', token: token);

    final List lista = respuesta['notificaciones'] ?? [];
    return lista
        .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /notificaciones/:id/leer
  static Future<bool> marcarLeida(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.patch('/notificaciones/$id/leer', token: token);
      return true;
    } catch (e) {
      debugPrint('Error marcarLeida: $e');
      return false;
    }
  }

  /// PATCH /notificaciones/leer-todas
  static Future<bool> marcarTodasLeidas() async {
    try {
      final token = await AuthService.instance.getToken();
      await client.patch('/notificaciones/leer-todas', token: token);
      return true;
    } catch (e) {
      debugPrint('Error marcarTodasLeidas: $e');
      return false;
    }
  }

  /// PATCH /notificaciones/:id/archivar
  static Future<bool> archivar(int id) async {
    try {
      final token = await AuthService.instance.getToken();
      await client.patch('/notificaciones/$id/archivar', token: token);
      return true;
    } catch (e) {
      debugPrint('Error archivar: $e');
      return false;
    }
  }
}