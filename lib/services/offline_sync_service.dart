import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../core/storage/offline_database.dart';
import 'auth_service.dart';
import 'offline_query_service.dart';
import 'offline_download_service.dart';

class SyncStatus {
  const SyncStatus(
      {this.owner,
      this.pending = 0,
      this.errors = 0,
      this.sending = false,
      this.connection = 'unknown',
      this.lastSuccess,
      this.message});
  final int? owner;
  final int pending;
  final int errors;
  final bool sending;
  final String connection;
  final DateTime? lastSuccess;
  final String? message;
}

/// Una sola cola por cuenta. Un envío incierto conserva el UUID y el payload.
class OfflineSyncService {
  OfflineSyncService(
      {OfflineDatabase? database,
      ApiClient? client,
      Connectivity? connectivity,
      this.autoSend = true})
      : _database = database,
        client = client ?? const ApiClient(),
        _connectivity = connectivity ?? Connectivity() {
    AuthService.sessionChanges.addListener(_sessionChanged);
  }

  static OfflineSyncService instance = OfflineSyncService();
  final OfflineDatabase? _database;
  OfflineDatabase get database =>
      _database ?? OfflineQueryService.instance.database;
  final ApiClient client;
  final Connectivity _connectivity;
  final bool autoSend;
  final status = ValueNotifier<SyncStatus>(const SyncStatus());
  final changes = ValueNotifier<int>(0);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  Future<void>? _running;
  bool _rerun = false;
  bool _started = false;
  bool _disposed = false;
  String _connection = 'unknown';
  String? _message;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _subscription =
          _connectivity.onConnectivityChanged.listen(_networkChanged);
      _networkChanged(await _connectivity.checkConnectivity());
    } catch (_) {
      // La API, no el indicador Wi-Fi, confirma que hay acceso al servidor.
      await sync();
    }
  }

  void _networkChanged(List<ConnectivityResult> result) {
    if (_disposed) return;
    if (result.every((entry) => entry == ConnectivityResult.none)) {
      _connection = 'offline';
      _message = 'Sin conexión. Los pendientes permanecen en este teléfono.';
      refreshStatus();
    } else {
      _connection = 'unknown';
      _message = null;
      sync();
    }
  }

  void _sessionChanged() {
    if (_disposed) return;
    _retryTimer?.cancel();
    _connection = 'unknown';
    _message = null;
    status.value = const SyncStatus();
    changes.value++;
    if (_started) sync();
  }

  Future<void> dispose() async {
    _disposed = true;
    _started = false;
    AuthService.sessionChanges.removeListener(_sessionChanged);
    _retryTimer?.cancel();
    await _subscription?.cancel();
    // Una respuesta en curso puede confirmar su propietario, pero no notificar
    // a pantallas destruidas. No se inicia otro envío después de dispose.
    status.dispose();
    changes.dispose();
  }

  Future<(AuthService, int, Usuario)> _owner() async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final owner = await auth.getCurrentUser();
    final token = await auth.getToken();
    if (owner == null ||
        token == null ||
        token.isEmpty ||
        !identical(auth, AuthService.instance) ||
        version != auth.sessionVersion) {
      throw ApiException('Inicia sesión antes de registrar movimientos.');
    }
    return (auth, version, owner);
  }

  Future<Map<String, dynamic>> _row(
      int owner, Map<String, dynamic> body) async {
    final data = Map<String, dynamic>.from(body['datos'] as Map);
    final categories = await database.read(owner, '/categorias');
    final dependents = await database.read(owner, '/dependientes');
    final category =
        categories?.rows.where((row) => row['id'] == data['id_categoria']);
    final dependent = dependents?.rows
        .where((row) => row['id_dependientes'] == data['id_dependientes']);
    return {
      ...data,
      'fecha': data['fecha_registro'],
      'categoria': category != null && category.isNotEmpty
          ? category.first['nombre']
          : null,
      'dependiente': dependent != null && dependent.isNotEmpty
          ? dependent.first['Nombre']
          : null,
      if (body['subtipo_modulo'] == 'Ahorro') ...{
        'monto_acumulado': 0,
        'estado': 'Activo'
      },
    };
  }

  Future<int> create(String resource, Map<String, dynamic> body) async {
    final (auth, version, owner) = await _owner();
    final data = body['datos'] as Map<String, dynamic>;
    final amount = data['monto'];
    if (amount is! num || !amount.isFinite || amount <= 0) {
      throw ApiException('El monto debe ser mayor que cero.');
    }
    if (![
      '/movimientos/gastos',
      '/movimientos/ingresos',
      '/movimientos/ahorros'
    ].contains(resource)) {
      throw ApiException('Este módulo no admite registro sin conexión.');
    }
    try {
      final row = await _row(owner.id, body);
      if (version != auth.sessionVersion ||
          !identical(auth, AuthService.instance)) {
        throw ApiException('La sesión cambió antes de guardar.');
      }
      final id = await database.enqueue(
          owner.id, const Uuid().v4(), resource, body, row);
      _notify();
      await refreshStatus();
      if (autoSend && !_disposed) {
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(milliseconds: 100), () => sync());
      }
      return id;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'No se pudo guardar en el teléfono. El registro no fue creado.');
    }
  }

  Future<void> refreshStatus() async {
    if (_disposed) return;
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    try {
      final owner = await auth.getCurrentUser();
      if (owner == null) return;
      final rows = await database.operations(owner.id, all: true);
      final last = await database.lastSuccess(owner.id);
      if (_disposed ||
          !identical(auth, AuthService.instance) ||
          version != auth.sessionVersion) {
        return;
      }
      status.value = SyncStatus(
          owner: owner.id,
          pending: rows.length,
          errors: rows.where((row) => row['state'] == 'error').length,
          sending: _running != null,
          connection: _connection,
          lastSuccess: last,
          message: _message);
    } catch (_) {
      if (!_disposed &&
          identical(auth, AuthService.instance) &&
          version == auth.sessionVersion) {
        status.value = const SyncStatus(
            message: 'No se pudo consultar el almacenamiento local.');
      }
    }
  }

  void _notify() {
    if (!_disposed) changes.value++;
  }

  Future<void> sync({bool force = false}) {
    if (_disposed) return Future.value();
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    _retryTimer?.cancel();
    final running = _run(force);
    _running = running;
    return running;
  }

  Future<void> _run(bool force) async {
    try {
      do {
        _rerun = false;
        await _execute(force);
        force = false;
      } while (_rerun && !_disposed);
    } catch (error) {
      _message = error is ApiException
          ? error.message
          : 'No se pudo completar la sincronización. Los datos siguen guardados.';
    } finally {
      _running = null;
      await refreshStatus();
    }
  }

  Future<void> _capabilities(String token) async {
    final capabilities =
        await client.get('/movimientos/sincronizacion', token: token);
    if (capabilities['protocolo'] != 1 ||
        capabilities['idempotencia'] != true) {
      throw ApiException(
          'El servidor aún no admite sincronización segura. Los pendientes se conservan.');
    }
  }

  Future<void> _execute(bool force) async {
    final (auth, version, owner) = await _owner();
    bool current() =>
        !_disposed &&
        identical(auth, AuthService.instance) &&
        version == auth.sessionVersion;
    final operations = await database.operations(owner.id);
    if (!current()) return;
    final token = await auth.getToken();
    if (!current() || token == null) return;
    try {
      // Nunca se envía a un backend antiguo que pueda ignorar el UUID.
      await _capabilities(token);
      if (!current()) return;
      _connection = 'online';
      _message = null;
    } on ApiException catch (error) {
      if (!current()) return;
      _connection = error.statusCode == 401 || error.statusCode == 403
          ? 'session'
          : error.isNetworkError
              ? 'offline'
              : 'server';
      _message = _connection == 'session'
          ? 'Inicia sesión de nuevo para enviar los pendientes.'
          : 'No se pudo verificar la sincronización del servidor. Los pendientes se conservan. ${error.message}';
      if (_connection == 'session') {
        for (final operation in operations) {
          await database.setOperationState(
              owner.id, operation['operation_id'] as String, 'session_required',
              error: _message);
        }
        _notify();
      }
      if (current()) _scheduleRetry(const Duration(seconds: 30));
      return;
    }
    for (final operation in operations) {
      if (!current()) break;
      final nextText = operation['next_attempt_at'] as String?;
      final next = nextText == null ? null : DateTime.parse(nextText);
      if (!force && next != null && next.isAfter(DateTime.now())) {
        _scheduleRetry(next.difference(DateTime.now()));
        continue;
      }
      final uuid = operation['operation_id'] as String;
      final attempts = (operation['attempts'] as int) + 1;
      await database.setOperationState(owner.id, uuid, 'sending',
          attempts: attempts);
      if (!current()) {
        await database.setOperationState(owner.id, uuid, 'pending');
        break;
      }
      _notify();
      await refreshStatus();
      try {
        final body = Map<String, dynamic>.from(
            jsonDecode(operation['payload'] as String) as Map);
        final result =
            await client.post('/movimientos', token: token, body: body);
        final id = result['ID_detalle'];
        if (result['operation_id'] != uuid || id is! int || id <= 0) {
          throw ApiException(
              'El servidor no confirmó el identificador de la operación.');
        }
        await database.acknowledge(owner.id, uuid, id);
        _notify();
      } on ApiException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await database.setOperationState(owner.id, uuid, 'session_required',
              error: error.message);
          if (current()) {
            _connection = 'session';
            _message =
                'Inicia sesión de nuevo. Los pendientes se conservan en este teléfono.';
          }
          _notify();
          break;
        }
        final code = error.statusCode;
        final permanent = code != null &&
            code >= 400 &&
            code < 500 &&
            code != 408 &&
            code != 429;
        final wait = Duration(seconds: min(60, 2 << min(attempts, 5)));
        await database.setOperationState(
            owner.id, uuid, permanent ? 'error' : 'pending',
            error: error.message,
            nextAttempt: permanent ? null : DateTime.now().add(wait));
        if (current()) {
          _message = permanent
              ? 'Hay registros que requieren corrección con conexión.'
              : 'Envío interrumpido. Los registros siguen guardados y se reintentará.';
          if (!permanent) {
            _connection = error.isNetworkError ? 'offline' : 'server';
            _scheduleRetry(wait);
          }
        }
        _notify();
        if (!permanent) break;
      } catch (_) {
        // Incluye fallos al guardar una confirmación: el siguiente envío utiliza
        // el mismo UUID y recupera la respuesta original del servidor.
        await database.setOperationState(owner.id, uuid, 'pending',
            error: 'No se pudo confirmar el resultado.');
        if (current()) _scheduleRetry(const Duration(seconds: 30));
        break;
      }
    }
    if (current() && _started && autoSend) {
      await OfflineDownloadService.refresh();
      if (current()) _notify();
    }
    if (current() && (await database.operations(owner.id, all: true)).isEmpty) {
      await database.markSyncSuccess(owner.id);
      _message = null;
    }
    await refreshStatus();
  }

  void _scheduleRetry(Duration wait) {
    if (!autoSend || _disposed || _connection == 'session') return;
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(
        wait < const Duration(seconds: 1) ? const Duration(seconds: 1) : wait,
        () => sync());
  }

  Future<void> correctRejected(
      int negativeId, String resource, Map<String, dynamic> body) async {
    final (auth, version, owner) = await _owner();
    final old = await database.localMovement(owner.id, -negativeId);
    if (old == null || old['state'] != 'error') {
      throw ApiException(
          'Solo se pueden corregir registros rechazados, con conexión.');
    }
    final token = (await auth.getToken())!;
    await _capabilities(token);
    final stored = await client.get(
        '/movimientos/sincronizacion/operaciones/${old['operation_id']}',
        token: token);
    if (stored['encontrado'] != false) {
      throw ApiException(
          'La operación ya fue registrada o no se pudo comprobar su estado. Sincroniza antes de corregir.');
    }
    final amount = (body['datos'] as Map)['monto'];
    if (amount is! num || !amount.isFinite || amount <= 0) {
      throw ApiException('Monto inválido.');
    }
    final row = await _row(owner.id, body);
    if (!identical(auth, AuthService.instance) ||
        auth.sessionVersion != version) {
      throw ApiException('La sesión cambió.');
    }
    await database.replaceRejected(
        owner.id, -negativeId, const Uuid().v4(), resource, body, row);
    _notify();
    await refreshStatus();
    if (autoSend) sync(force: true);
  }
}
