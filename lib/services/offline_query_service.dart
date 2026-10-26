import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/offline_database.dart';
import 'auth_service.dart';

enum QuerySource { server, local, unavailable }

class QueryStatus {
  const QueryStatus(this.source, {this.downloadedAt, this.message});
  final QuerySource source;
  final DateTime? downloadedAt;
  final String? message;
}

/// Copia por propietario ante desconexión o sesión vencida. Los permisos,
/// errores de formato y errores del servidor se presentan explícitamente.
class OfflineQueryService {
  OfflineQueryService(this.database) {
    AuthService.sessionChanges.addListener(_clearVisibleState);
  }

  static OfflineQueryService instance = OfflineQueryService(OfflineDatabase());
  final OfflineDatabase database;
  final statuses = ValueNotifier<Map<String, QueryStatus>>({});
  final Map<String, Future<List<Map<String, dynamic>>>> _requests = {};
  final Map<String, int> _revisions = {};
  final Set<String> _blockedSnapshots = {};

  void _clearVisibleState() {
    statuses.value = {};
  }

  void dispose() {
    AuthService.sessionChanges.removeListener(_clearVisibleState);
    statuses.dispose();
  }

  Future<List<T>> query<T>(String resource, ApiClient client,
      T Function(Map<String, dynamic>) decode,
      {String? listKey}) async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final user = await auth.getCurrentUser();
    final token = await auth.getToken();
    bool isCurrent() =>
        identical(auth, AuthService.instance) && version == auth.sessionVersion;
    if (!isCurrent()) throw ApiException('La sesión cambió.');
    if (user == null || token == null || token.isEmpty) {
      _set(
          resource,
          const QueryStatus(QuerySource.unavailable,
              message: 'Inicia sesión para consultar los datos de tu cuenta.'));
      throw ApiException(
          'Inicia sesión para consultar los datos de tu cuenta.');
    }

    final revision = _revisions['${user.id}:$resource'] ?? 0;
    final key =
        '${identityHashCode(auth)}:$version:${user.id}:$resource:$revision';
    // Reutiliza la descarga inicial si una pantalla pide el mismo recurso.
    final request = _requests[key] ??=
        _fetch<T>(resource, client, decode, user.id, token, isCurrent, listKey);
    try {
      List<Map<String, dynamic>> rows;
      try {
        rows = await request;
      } on ApiException catch (error) {
        if (!isCurrent()) rethrow;
        if (!error.isNetworkError &&
            error.statusCode != 401 &&
            error.statusCode != 403) {
          rethrow;
        }
        final copy = await database.read(user.id, resource);
        final local =
            await database.visibleRows(user.id, resource, copy?.rows ?? []);
        if (!isCurrent()) throw ApiException('La sesión cambió.');
        if (copy == null && local.isEmpty) rethrow;
        _set(
            resource,
            QueryStatus(QuerySource.local,
                downloadedAt: copy?.downloadedAt,
                message: error.statusCode == 401 || error.statusCode == 403
                    ? 'La sesión venció. Consulta local disponible; inicia sesión para sincronizar.'
                    : copy == null
                        ? 'Solo registros del teléfono. Aún falta descargar información del servidor.'
                        : error.message));
        return local.map(decode).toList();
      }
      if (!isCurrent()) throw ApiException('La sesión cambió.');
      final combined = await database.visibleRows(user.id, resource, rows);
      if (!isCurrent()) throw ApiException('La sesión cambió.');
      return combined.map(decode).toList();
    } catch (error) {
      if (isCurrent()) {
        _set(
            resource,
            QueryStatus(QuerySource.unavailable,
                message: error is ApiException
                    ? error.message
                    : 'No se pudo consultar la información o el almacenamiento local.'));
      }
      rethrow;
    } finally {
      if (identical(_requests[key], request)) _requests.remove(key);
    }
  }

  Future<List<T>> localList<T>(
      String resource, T Function(Map<String, dynamic>) decode) async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final owner = await auth.getCurrentUser();
    if (owner == null) return [];
    final copy = await database.read(owner.id, resource);
    final rows =
        await database.visibleRows(owner.id, resource, copy?.rows ?? []);
    if (!identical(auth, AuthService.instance) ||
        version != auth.sessionVersion) {
      return [];
    }
    return rows.map(decode).toList();
  }

  Future<List<Map<String, dynamic>>> _fetch<T>(
      String resource,
      ApiClient client,
      T Function(Map<String, dynamic>) decode,
      int owner,
      String token,
      bool Function() isCurrent,
      String? listKey) async {
    final revision = _revisions['$owner:$resource'] ?? 0;
    try {
      late final List<dynamic> response;
      try {
        if (listKey == null) {
          response = await client.getList(resource, token: token);
        } else {
          final body = await client.get(resource, token: token);
          final value = body[listKey];
          if (value is! List) {
            throw ApiException('Formato de respuesta inválido.');
          }
          response = value;
        }
      } on ApiException catch (error) {
        if (!isCurrent()) throw ApiException('La sesión cambió.');
        if (!error.isNetworkError) rethrow;
        if (_blockedSnapshots.contains('$owner:$resource')) {
          throw ApiException(
              'La copia local necesita actualizarse después de los cambios online.');
        }
        final cached = await database.read(owner, resource);
        if (!isCurrent()) throw ApiException('La sesión cambió.');
        if ((_revisions['$owner:$resource'] ?? 0) != revision) {
          throw ApiException(
              'Los datos cambiaron durante la consulta. Actualiza de nuevo.');
        }
        if (cached == null) {
          throw ApiException(
              'No se pudo consultar el servidor y aún no hay una copia descargada.',
              isNetworkError: true);
        }
        cached.rows.map(decode).toList();
        _set(
            resource,
            QueryStatus(QuerySource.local,
                downloadedAt: cached.downloadedAt, message: error.message));
        return cached.rows;
      }
      if (!isCurrent()) throw ApiException('La sesión cambió.');
      final rows =
          response.map((row) => Map<String, dynamic>.from(row as Map)).toList();
      // No sustituye una copia válida con datos que los modelos no pueden leer.
      rows.map(decode).toList();
      final downloadedAt = DateTime.now().toUtc();
      String? warning;
      if ((_revisions['$owner:$resource'] ?? 0) != revision) {
        throw ApiException(
            'Los datos cambiaron durante la consulta. Actualiza de nuevo.');
      }
      try {
        await database.save(owner, resource, rows, downloadedAt);
        if ((_revisions['$owner:$resource'] ?? 0) == revision) {
          _blockedSnapshots.remove('$owner:$resource');
        }
      } catch (_) {
        warning =
            'Datos del servidor disponibles, pero no se pudo guardar la copia sin conexión.';
      }
      if (!isCurrent()) throw ApiException('La sesión cambió.');
      if ((_revisions['$owner:$resource'] ?? 0) != revision) {
        await database.discard(owner, resource, downloadedAt);
        throw ApiException(
            'Los datos cambiaron durante la consulta. Actualiza de nuevo.');
      }
      _set(
          resource,
          QueryStatus(QuerySource.server,
              downloadedAt: downloadedAt, message: warning));
      return rows;
    } catch (error) {
      if (isCurrent() && (_revisions['$owner:$resource'] ?? 0) == revision) {
        _set(
            resource,
            QueryStatus(QuerySource.unavailable,
                message: error is ApiException
                    ? error.message
                    : 'No se pudo leer la información. Intenta actualizar de nuevo.'));
      }
      rethrow;
    }
  }

  void _set(String resource, QueryStatus status) {
    statuses.value = {...statuses.value, resource: status};
  }

  /// Después de una escritura online, una copia anterior ya no es fiable.
  /// El propietario se captura antes de enviar, nunca tras una respuesta tardía.
  Future<void> invalidate(int owner, String resource) async {
    final key = '$owner:$resource';
    _revisions[key] = (_revisions[key] ?? 0) + 1;
    _blockedSnapshots.add(key);
    await database.invalidate(owner, resource);
  }

  /// Mantiene las escrituras en el servidor durante la etapa de consulta.
  Future<T> onlineMutation<T>(
      String resource, Future<T> Function(String token) send) async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final owner = await auth.getCurrentUser();
    final token = await auth.getToken();
    if (owner == null ||
        token == null ||
        token.isEmpty ||
        auth.sessionVersion != version ||
        !identical(auth, AuthService.instance)) {
      throw ApiException('Inicia sesión antes de guardar cambios.');
    }
    final result = await send(token);
    try {
      await invalidate(owner.id, resource);
    } catch (_) {
      // El servidor ya confirmó: no se afirma que la escritura falló ni se
      // permite reutilizar una copia antigua en esta sesión.
      if (identical(auth, AuthService.instance) &&
          auth.sessionVersion == version) {
        _set(
            resource,
            const QueryStatus(QuerySource.server,
                message:
                    'El cambio se guardó en el servidor. Actualiza la copia local.'));
      }
    }
    return result;
  }
}
