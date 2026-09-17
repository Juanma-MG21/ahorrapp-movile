import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/dependiente_admin.dart';
import '../models/historial_item.dart';
import '../models/usuario_admin.dart';
import 'auth_service.dart';

/// Todo lo relacionado con el Panel de administración: solo lo pueden
/// usar cuentas con rol 'admin' o 'superuser' (el backend valida esto
/// con requireRole en cada endpoint; aquí solo se habla con la API).
///
/// Espejo en móvil de PanelAdmin.jsx + PanelUsuarios.jsx +
/// PanelDependientes.jsx de la web.
class AdminService {
  AdminService._internal();
  static AdminService instance = AdminService._internal();

  final ApiClient _api = ApiClient();

  /// GET genérico para los 2 endpoints de totales, que (a diferencia
  /// del resto de la API) NO devuelven { ok, ... } sino el objeto
  /// plano directamente. Por eso no se puede usar ApiClient.get aquí.
  Future<Map<String, dynamic>> _rawGetMap(String path) async {
    final token = await AuthService.instance.getToken();

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${_api.baseUrl}$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    if (response.statusCode >= 400) {
      throw ApiException('Ocurrió un error inesperado (código ${response.statusCode})');
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Respuesta inesperada del servidor: $e');
    }
  }

  /// GET /auth/usuarios/PanelAdmin → total de usuarios registrados.
  Future<int> getTotalUsuarios() async {
    final data = await _rawGetMap('/auth/usuarios/PanelAdmin');
    final total = data['totalUsuarios'];
    return total is int ? total : int.tryParse('$total') ?? 0;
  }

  /// GET /auth/dependientes/PanelAdmin → total de dependientes registrados.
  Future<int> getTotalDependientes() async {
    final data = await _rawGetMap('/auth/dependientes/PanelAdmin');
    final total = data['totalDependientes'];
    return total is int ? total : int.tryParse('$total') ?? 0;
  }

  /// GET /historial → últimas acciones registradas en todo el sistema.
  Future<List<HistorialItem>> getHistorial({int limite = 8}) async {
    final token = await AuthService.instance.getToken();
    final data = await _api.get('/historial', token: token);
    final lista = (data['historial'] as List<dynamic>?) ?? [];
    final items = lista
        .whereType<Map<String, dynamic>>()
        .map(HistorialItem.fromJson)
        .toList();
    return items.take(limite).toList();
  }

  /// GET /auth/PanelUsuarios → lista completa de usuarios activos.
  Future<List<UsuarioAdmin>> getUsuarios() async {
    final token = await AuthService.instance.getToken();
    final data = await _api.get('/auth/PanelUsuarios', token: token);
    final lista = (data['usuarios'] as List<dynamic>?) ?? [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(UsuarioAdmin.fromJson)
        .toList();
  }

  /// PUT /auth/PanelUsuarios/:id → editar nombre/apellido/email.
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    final token = await AuthService.instance.getToken();
    await _api.put(
      '/auth/PanelUsuarios/$id',
      token: token,
      body: {'Nombre': nombre, 'Apellido': apellido, 'Email': email},
    );
  }

  /// PUT /auth/PanelUsuarios/:id/rol → SOLO superuser puede cambiar roles.
  Future<void> actualizarRolUsuario({required int id, required int idRol}) async {
    final token = await AuthService.instance.getToken();
    await _api.put(
      '/auth/PanelUsuarios/$id/rol',
      token: token,
      body: {'ID_rol': idRol},
    );
  }

  /// DELETE /auth/PanelUsuarios/:id → baja lógica (activo = false).
  Future<void> eliminarUsuario(int id) async {
    final token = await AuthService.instance.getToken();
    await _api.delete('/auth/PanelUsuarios/$id', token: token);
  }

  /// GET /auth/PanelDependientes → todos los dependientes del sistema
  /// (de todos los usuarios), para gestión global del administrador.
  Future<List<DependienteAdmin>> getDependientesGlobales() async {
    final token = await AuthService.instance.getToken();
    final data = await _api.get('/auth/PanelDependientes', token: token);
    final lista = (data['dependientes'] as List<dynamic>?) ?? [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(DependienteAdmin.fromJson)
        .toList();
  }

  /// DELETE /dependientes/admin/:id
  Future<void> eliminarDependiente(int id) async {
    final token = await AuthService.instance.getToken();
    await _api.delete('/dependientes/admin/$id', token: token);
  }
}
