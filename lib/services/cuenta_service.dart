import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/movimiento.dart';
import 'auth_service.dart';

/// Todo lo relacionado con "Mi cuenta" del usuario común:
/// editar perfil, cambiar contraseña, desactivar cuenta y consultar
/// su propio historial de movimientos (ahorros, ingresos, gastos,
/// deudas e imprevistos).
///
/// Espejo en móvil de `Micuenta.jsx` + `Mismovimientos.jsx` de la web.
class CuentaService {
  CuentaService._internal();
  static CuentaService instance = CuentaService._internal();

  final ApiClient _api = ApiClient();

  /// GET /movimientos
  /// El backend puede responder un arreglo plano o { movimientos: [...] }
  /// (igual que en la web), así que se maneja de forma tolerante en vez
  /// de usar ApiClient.getList (que exige un arreglo estricto).
  Future<List<Movimiento>> getMovimientos() async {
    final token = await AuthService.instance.getToken();

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${_api.baseUrl}/movimientos'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      // Igual que en la web: si falla, se muestra una lista vacía en
      // vez de romper toda la pantalla de cuenta.
      return [];
    }

    if (response.statusCode >= 400) return [];

    try {
      final decoded = jsonDecode(response.body);
      List<dynamic> lista;
      if (decoded is List) {
        lista = decoded;
      } else if (decoded is Map<String, dynamic>) {
        lista = (decoded['movimientos'] as List<dynamic>?) ?? [];
      } else {
        lista = [];
      }

      final movimientos = lista
          .whereType<Map<String, dynamic>>()
          .map(Movimiento.fromJson)
          .toList();

      movimientos.sort((a, b) {
        final fa = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        final fb = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
        return fb.compareTo(fa);
      });

      return movimientos;
    } catch (_) {
      return [];
    }
  }

  /// PUT /auth/mi-perfil
  Future<String> actualizarMiPerfil({
    required String nombre,
    required String apellido,
    required String email,
  }) async {
    final token = await AuthService.instance.getToken();
    final data = await _api.put(
      '/auth/mi-perfil',
      token: token,
      body: {'Nombre': nombre, 'Apellido': apellido, 'Email': email},
    );
    return data['mensaje'] as String? ?? 'Tus datos se actualizaron correctamente';
  }

  /// PUT /auth/mi-cuenta/password
  Future<String> cambiarMiPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final token = await AuthService.instance.getToken();
    final data = await _api.put(
      '/auth/mi-cuenta/password',
      token: token,
      body: {
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      },
    );
    return data['mensaje'] as String? ?? 'Contraseña actualizada correctamente';
  }

  /// PUT /auth/mi-cuenta/desactivar
  /// Desactiva la cuenta de inmediato; el backend programa su
  /// eliminación definitiva en 30 días si no se reactiva antes
  /// (contactando soporte). Devuelve el mensaje del backend, que ya
  /// incluye la fecha límite calculada en el servidor.
  Future<String> desactivarCuentaPropia() async {
    final token = await AuthService.instance.getToken();
    final data = await _api.put('/auth/mi-cuenta/desactivar', token: token);
    return data['mensaje'] as String? ?? 'Tu cuenta ha sido desactivada';
  }
}
