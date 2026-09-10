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
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _pinKey = 'user_pin_code';

  String? _memoryToken;

  Future<bool> hasSession() async {
    if (_memoryToken != null) return true;
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      _memoryToken = stored;
      return true;
    }
    return false;
  }

  // --- LÓGICA DE PIN ---

  Future<bool> hasPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    return savedPin == pin;
  }

  // --- LÓGICA DE AUTH ---

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

    _memoryToken = token;

    if (rememberSession) {
      await _storage.write(key: _tokenKey, value: token);
    } else {
      await _storage.delete(key: _tokenKey);
    }

    return Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
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

  Future<void> logout() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}
