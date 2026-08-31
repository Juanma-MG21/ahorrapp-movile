import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepción lanzada cuando el backend responde { ok: false, mensaje }
/// o cuando hay un problema de red/formato de respuesta.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP genérico para hablar con el backend de AhorrApp.
/// Centraliza URL base, headers y parseo/errores comunes, para que
/// los servicios (AuthService, GastosService, etc.) no repitan lógica.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl =
      'https://ahorrapp-react.onrender.com/api';

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST genérico. [path] empieza con '/', ej: '/auth/login'.
  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        String? token,
      }) {
    return _send(
          () => http.post(
        _uri(path),
        headers: _headers(token: token),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  /// GET genérico.
  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _send(
          () => http.get(_uri(path), headers: _headers(token: token)),
    );
  }

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request,
      ) async {
    late final http.Response response;

    try {
      response = await request();
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Respuesta inesperada del servidor',
        statusCode: response.statusCode,
      );
    }

    final bool ok = decoded['ok'] == true;

    if (!ok || response.statusCode >= 400) {
      final mensaje = decoded['mensaje'] as String? ??
          'Ocurrió un error inesperado (código ${response.statusCode})';
      throw ApiException(mensaje, statusCode: response.statusCode);
    }

    return decoded;
  }
}