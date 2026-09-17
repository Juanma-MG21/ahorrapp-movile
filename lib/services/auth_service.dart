import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
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
  AuthService._internal() : _api = ApiClient();
  AuthService.forTesting([ApiClient? api]) : _api = api ?? ApiClient();
  static final AuthService instance = AuthService._internal();

  final ApiClient _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

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

  Future<bool> canUseBiometricAccess() async {
    if (!await hasSession()) return false;

    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<String?> getToken() async {
    if (_memoryToken != null) return _memoryToken;
    _memoryToken = await _storage.read(key: _tokenKey);
    return _memoryToken;
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
    final data = await _api.post(
      '/auth/login',
      body: {'Email': email, 'Password_hash': password},
    );

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
    await _api.post(
      '/auth/register',
      body: {
        'Nombre': nombre,
        'Apellido': apellido,
        'Email': email,
        'Password_hash': password,
      },
    );
  }

  bool get isGoogleAuthConfigured {
    return const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        ).isNotEmpty ||
        const String.fromEnvironment(
          'GOOGLE_SERVER_CLIENT_ID',
          defaultValue: '',
        ).isNotEmpty;
  }

  Future<Usuario> loginWithGoogle() async {
    if (!isGoogleAuthConfigured) {
      throw ApiException(
        'Google Sign-In no está configurado para este proyecto. Añade un client ID válido antes de habilitarlo.',
      );
    }

    final googleClientId = const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    final googleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );

    _googleInitialization ??= _googleSignIn.initialize(
      clientId: googleClientId.isNotEmpty ? googleClientId : null,
      serverClientId: googleServerClientId.isNotEmpty
          ? googleServerClientId
          : null,
    );
    await _googleInitialization;

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        'No se pudo obtener el token de sesión de Google. Intenta nuevamente.',
      );
    }

    final data = await _api.postRaw(
      '/auth/google',
      body: {'idToken': idToken, 'provider': 'google'},
    );

    final token = data['token'] as String? ?? data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        'El servidor no devolvió un token válido para la sesión de Google.',
      );
    }

    _memoryToken = token;
    await _storage.write(key: _tokenKey, value: token);

    final usuarioData =
        data['usuario'] as Map<String, dynamic>? ??
        data['user'] as Map<String, dynamic>?;

    if (usuarioData == null) {
      throw ApiException(
        'El servidor no devolvió la información del usuario autenticado.',
      );
    }

    return Usuario.fromJson(usuarioData);
  }

  Future<String> forgotPassword({required String email}) async {
    final data = await _api.post(
      '/auth/forgot-password',
      body: {'email': email, 'Email': email},
    );
    return data['mensaje'] as String? ??
        data['message'] as String? ??
        'Se ha enviado un correo';
  }

  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final data = await _api.post(
      '/auth/verify-reset-code',
      body: {'email': email, 'Email': email, 'code': code, 'Code': code},
    );
    return data['resetToken'] as String? ??
        data['token'] as String? ??
        data['reset_token'] as String? ??
        '';
  }

  Future<void> resetPassword({
    required String resetToken,
    required String nuevaPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      body: {
        'resetToken': resetToken,
        'token': resetToken,
        'nuevaPassword': nuevaPassword,
        'password': nuevaPassword,
        'newPassword': nuevaPassword,
      },
    );
  }

  Future<void> logout() async {
    _memoryToken = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // El estado de sesión de Google no es crítico para cerrar la app.
    }
    await _storage.delete(key: _tokenKey);
  }
}
