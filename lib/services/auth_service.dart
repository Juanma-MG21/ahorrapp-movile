import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_client.dart';

/// Datos básicos del usuario autenticado (campo "usuario" de la
/// respuesta de POST /api/auth/login).
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
  final dynamic roles; // el backend no documenta su forma exacta todavía

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

/// Maneja login, registro, recuperación de contraseña y la sesión
/// (token) del usuario. Singleton: toda la app comparte una instancia
/// para que el token en memoria sea consistente entre pantallas.
class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  // Token en memoria: vive mientras la app está abierta, sin importar
  // si el usuario marcó "recordar sesión".
  String? _memoryToken;

  /// true si hay un token disponible (en memoria o en disco).
  Future<bool> hasSession() async {
    if (_memoryToken != null) return true;
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      _memoryToken = stored;
      return true;
    }
    return false;
  }

  /// Token actual, o null si no hay sesión. Los demás servicios
  /// (GastosService, etc.) lo usan para el header Authorization.
  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;
    _memoryToken = await _storage.read(key: _tokenKey);
    return _memoryToken;
  }

  /// Inicia sesión contra POST /api/auth/login.
  /// Si [rememberSession] es true, además del token en memoria, lo
  /// persiste cifrado en el dispositivo. Si es false, solo vive en
  /// memoria y se pierde al cerrar la app.
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
      // Limpia cualquier sesión persistida de una vez anterior en la
      // que sí se haya marcado "recordar sesión".
      await _storage.delete(key: _tokenKey);
    }

    return Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
  }

  // --- Listos para cuando conectemos register/forgot-password ---

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

  /// Cierra sesión: borra el token de memoria y de disco.
  Future<void> logout() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }
}