import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/emergencia_model.dart';
import 'auth_service.dart';

/// Rutas reales confirmadas contra fondoemergenciaRoutes.js (montado en
/// /fondo-emergencia dentro de /api):
///   GET    /fondo-emergencia              -> getFondoEmergencia
///   POST   /fondo-emergencia              -> crearFondoEmergencia
///   PUT    /fondo-emergencia/meta         -> actualizarMetaFondoEmergencia
///   POST   /fondo-emergencia/aporte       -> registrarAporte
///   POST   /fondo-emergencia/retiro       -> registrarRetiro
///   GET    /fondo-emergencia/movimientos  -> getMovimientosFondoEmergencia
///
/// Nota: a diferencia de GET /movimientos/ahorros (que responde un
/// array plano), estos 6 endpoints SIEMPRE responden el sobre
/// { ok, mensaje?, datos }, incluido el listado de movimientos. Por
/// eso este servicio usa client.get()/post()/put() (no getList).
class EmergenciaService {
  @visibleForTesting
  static ApiClient client = ApiClient();

  static Future<String?> get _token => AuthService.instance.getToken();

  /// Devuelve null si el usuario todavía no tiene un fondo configurado
  /// (404 del backend), para que la pantalla muestre el estado "crear
  /// meta" en vez de un error.
  static Future<FondoEmergenciaModel?> obtenerFondo() async {
    try {
      final data = await client.get('/fondo-emergencia', token: await _token);
      return FondoEmergenciaModel.fromJson(data['datos'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<FondoEmergenciaModel> crearFondo(double meta) async {
    final data = await client.post(
      '/fondo-emergencia',
      token: await _token,
      body: {'meta': meta},
    );
    return FondoEmergenciaModel.fromJson(data['datos'] as Map<String, dynamic>);
  }

  static Future<FondoEmergenciaModel> actualizarMeta(double meta) async {
    final data = await client.put(
      '/fondo-emergencia/meta',
      token: await _token,
      body: {'meta': meta},
    );
    return FondoEmergenciaModel.fromJson(data['datos'] as Map<String, dynamic>);
  }

  static Future<MovimientoEmergenciaModel> registrarAporte(
    double monto, {
    String? descripcion,
  }) async {
    final data = await client.post(
      '/fondo-emergencia/aporte',
      token: await _token,
      body: {'monto': monto, if (descripcion != null) 'descripcion': descripcion},
    );
    return MovimientoEmergenciaModel.fromJson(data['datos'] as Map<String, dynamic>);
  }

  static Future<MovimientoEmergenciaModel> registrarRetiro(
    double monto, {
    String? descripcion,
  }) async {
    final data = await client.post(
      '/fondo-emergencia/retiro',
      token: await _token,
      body: {'monto': monto, if (descripcion != null) 'descripcion': descripcion},
    );
    return MovimientoEmergenciaModel.fromJson(data['datos'] as Map<String, dynamic>);
  }

  static Future<List<MovimientoEmergenciaModel>> obtenerMovimientos() async {
    try {
      final data = await client.get('/fondo-emergencia/movimientos', token: await _token);
      final lista = data['datos'] as List<dynamic>? ?? [];
      return lista
          .map((json) => MovimientoEmergenciaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
