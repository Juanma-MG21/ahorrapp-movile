import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';

class Usuario {
  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.roles,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final dynamic roles;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: json['roles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'roles': roles,
    };
  }
}

class AuthService {
  AuthService._internal();

  @visibleForTesting
  AuthService.test(this._api, this._storage);

  static AuthService instance = AuthService._internal();

  ApiClient _api = ApiClient();
  FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  String? _memoryToken;
  Usuario? _memoryUser;

  Future<bool> hasSession() async {
    if (_memoryToken != null) return true;
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      _memoryToken = stored;
      return true;
    }
    return false;
  }

  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;
    _memoryToken = await _storage.read(key: _tokenKey);
    return _memoryToken;
  }

  /// Devuelve el usuario actual: primero de memoria, y si no está
  /// disponible (por ejemplo, la app se acaba de abrir), lo recupera
  /// de secure storage sin llamadas a la API. Devuelve null si no hay
  /// usuario cacheado (p. ej. la sesión se guardó sin "recordar sesión").
  Future<Usuario?> getCurrentUser() async {
    if (_memoryUser != null) return _memoryUser;

    final stored = await _storage.read(key: _userKey);
    if (stored == null) return null;

    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      _memoryUser = Usuario.fromJson(json);
      return _memoryUser;
    } catch (e) {
      // Datos corruptos o formato inesperado: no bloqueamos el flujo,
      // simplemente no hay nombre de usuario disponible para mostrar.
      debugPrint('No se pudo leer el usuario cacheado: $e');
      return null;
    }
  }

  Future<Usuario> login({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'Email': email,
      'Password_hash': password,
    });

    final token = data['token'] as String?;
    if (token == null) {
      throw ApiException('El servidor no devolvió un token de sesión');
    }

    final usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);

    _memoryToken = token;
    _memoryUser = usuario;

    if (rememberSession) {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(usuario.toJson()));
    } else {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    }

    return usuario;
  }

  Future<void> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    await _api.post('/auth/register', body: {
      'Nombre': nombre,
      'Apellido': apellido,
      'Email': email,
      'Password_hash': password,
    });
  }

  Future<String> forgotPassword({required String email}) async {
    final data = await _api.post('/auth/forgot-password', body: {
      'Email': email,
    });
    return data['mensaje'] as String;
  }

  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final data = await _api.post('/auth/verify-reset-code', body: {
      'Email': email,
      'code': code,
    });
    return data['resetToken'] as String;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String nuevaPassword,
  }) async {
    await _api.post('/auth/reset-password', body: {
      'resetToken': resetToken,
      'nuevaPassword': nuevaPassword,
    });
  }

  Future<void> logout() async {
    _memoryToken = null;
    _memoryUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}