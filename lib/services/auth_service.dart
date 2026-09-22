import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  // Aportados por Manuel: soporte de biometría (chequeo movido aquí por
  // decisión de equipo) y login con Google.
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _pinKey = 'auth_pin';
  static const _biometricKey = 'biometric_enabled';

  String? _memoryToken;
  Usuario? _memoryUser;
  String? _memoryPin;

  Future<bool> hasSession() async {
    if (_memoryToken != null) return true;
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      _memoryToken = stored;
      return true;
    }
    return false;
  }

  /// Decisión de equipo: el chequeo de hardware biométrico vive aquí
  /// (antes vivía en la UI, en LoginScreen). Centraliza la regla de
  /// "solo ofrecer biometría si hay sesión guardada, el usuario la
  /// activó explícitamente y el dispositivo la soporta" para que
  /// cualquier pantalla la reutilice igual.
  Future<bool> canUseBiometricAccess() async {
    if (!await hasSession() || !await isBiometricEnabled()) return false;

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

  // --- LÓGICA DE PIN ---
  // PIN local del dispositivo, usado como segunda verificación para
  // confirmar acciones sensibles (cambiar contraseña, editar datos
  // personales, etc.) sobre una sesión ya autenticada. No se envía al
  // backend: vive solo en secure storage, igual que el token.

  Future<bool> hasPinSet() async {
    if (!await hasSession()) return false;
    if (_memoryPin != null) return true;
    final stored = await _storage.read(key: _pinKey);
    if (stored != null) {
      _memoryPin = stored;
      return true;
    }
    return false;
  }

  Future<void> savePin(String pin) async {
    if (!await hasSession()) {
      throw ApiException('Debes iniciar sesión antes de configurar un PIN.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ApiException('El PIN debe tener exactamente 4 dígitos.');
    }
    _memoryPin = pin;
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    if (!await hasSession()) return false;
    final stored = _memoryPin ?? await _storage.read(key: _pinKey);
    return stored != null && stored == pin;
  }

  Future<void> clearPin() async {
    _memoryPin = null;
    await _storage.delete(key: _pinKey);
  }

  // --- LÓGICA DE BIOMETRÍA ---
  // A diferencia del PIN, la biometría requiere que el usuario la
  // active explícitamente (confirmando su identidad una vez) antes de
  // poder usarla como acceso rápido.

  Future<bool> isBiometricEnabled() async {
    if (!await hasSession()) return false;
    return await _storage.read(key: _biometricKey) == 'true';
  }

  Future<void> configureBiometrics() async {
    if (!await hasSession()) {
      throw ApiException(
        'Debes iniciar sesión antes de configurar la biometría.',
      );
    }

    try {
      final supported = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
      if (!supported) {
        throw ApiException(
          'Este dispositivo no tiene biometría disponible o configurada.',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para activar la biometría',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!authenticated) {
        throw ApiException('No se pudo confirmar tu identidad.');
      }
      await _storage.write(key: _biometricKey, value: 'true');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException('No se pudo configurar la biometría: $error');
    }
  }

  Future<bool> authenticateBiometric() async {
    if (!await hasSession() || !await isBiometricEnabled()) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
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

  // --- Aportado por Manuel: login con Google. ---
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
      serverClientId:
          googleServerClientId.isNotEmpty ? googleServerClientId : null,
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
      body: {
        'idToken': idToken,
        'provider': 'google',
      },
    );

    final token = data['token'] as String? ?? data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        'El servidor no devolvió un token válido para la sesión de Google.',
      );
    }

    final usuarioData = data['usuario'] as Map<String, dynamic>? ??
        data['user'] as Map<String, dynamic>?;

    if (usuarioData == null) {
      throw ApiException(
        'El servidor no devolvió la información del usuario autenticado.',
      );
    }

    final usuario = Usuario.fromJson(usuarioData);

    // Mismo criterio de persistencia que el login con email/contraseña:
    // guardamos token y usuario cacheado para que getCurrentUser()
    // funcione igual sin importar el método de login usado.
    _memoryToken = token;
    _memoryUser = usuario;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(usuario.toJson()));

    return usuario;
  }

  Future<String> forgotPassword({required String email}) async {
    final data = await _api.post('/auth/forgot-password', body: {
      'Email': email,
    });
    return data['mensaje'] as String? ??
        data['message'] as String? ??
        'Se ha enviado un correo';
  }

  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final data = await _api.post('/auth/verify-reset-code', body: {
      'Email': email,
      'code': code,
    });
    return data['resetToken'] as String? ?? data['token'] as String? ?? '';
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

  /// Usado por ChangePasswordScreen (con confirmación previa por PIN).
  Future<void> changePassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Debes iniciar sesión para cambiar tu contraseña.');
    }

    await _api.put(
      '/auth/mi-cuenta/password',
      token: token,
      body: {
        'passwordActual': passwordActual,
        'passwordNueva': passwordNueva,
      },
    );
  }

  /// Agregado para soportar la vista de "Mi cuenta" en móvil.
  /// Actualiza el usuario cacheado (en memoria y, si la sesión se
  /// guardó con "recordar sesión", también en secure storage) sin
  /// necesidad de volver a hacer login. Se usa después de editar el
  /// perfil (nombre/apellido/email) para que el resto de la app
  /// refleje el cambio de inmediato.
  Future<void> cacheUsuario(Usuario usuario) async {
    _memoryUser = usuario;
    final habiaSesionGuardada = await _storage.read(key: _userKey);
    if (habiaSesionGuardada != null) {
      await _storage.write(key: _userKey, value: jsonEncode(usuario.toJson()));
    }
  }

  Future<void> logout() async {
    _memoryToken = null;
    _memoryUser = null;
    _memoryPin = null;

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // El estado de sesión de Google no es crítico para cerrar la app.
    }

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);
  }
}