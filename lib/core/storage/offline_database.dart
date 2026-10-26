import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalSnapshot {
  const LocalSnapshot(this.rows, this.downloadedAt);
  final List<Map<String, dynamic>> rows;
  final DateTime downloadedAt;
}

/// Copias completas por recurso y propietario. Un vacío descargado también
/// se persiste, para distinguirlo de un recurso que nunca se descargó.
class OfflineDatabase {
  OfflineDatabase({DatabaseFactory? factory, String? databasePath})
      : _providedFactory = factory,
        _path = databasePath;

  final DatabaseFactory? _providedFactory;
  DatabaseFactory get _factory => _providedFactory ?? databaseFactory;
  final String? _path;
  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _open();

  Future<Database> _open() async {
    try {
      final location = _path ??
          path.join(await _factory.getDatabasesPath(), 'ahorrapp_offline.db');
      return await _factory.openDatabase(location,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE snapshots (
                  owner_id INTEGER NOT NULL,
                  resource TEXT NOT NULL,
                  payload TEXT NOT NULL,
                  downloaded_at TEXT NOT NULL,
                  PRIMARY KEY (owner_id, resource)
                )
              ''');
              // Outbox persistente: cada reintento conserva su UUID y payload.
              await db.execute('''
                CREATE TABLE pending_operations (
                  owner_id INTEGER NOT NULL,
                  operation_id TEXT NOT NULL,
                  resource TEXT NOT NULL,
                  payload TEXT NOT NULL,
                  state TEXT NOT NULL DEFAULT 'pending',
                  attempts INTEGER NOT NULL DEFAULT 0,
                  error TEXT,
                  PRIMARY KEY (owner_id, operation_id)
                )
              ''');
              await _upgradeQueue(db);
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < 2) await _upgradeQueue(db);
            },
          ));
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  static Future<void> _upgradeQueue(Database db) async {
    await db
        .execute('ALTER TABLE pending_operations ADD COLUMN local_id INTEGER');
    await db.execute(
        'ALTER TABLE pending_operations ADD COLUMN next_attempt_at TEXT');
    await db
        .execute('ALTER TABLE pending_operations ADD COLUMN created_at TEXT');
    await db.execute('''CREATE TABLE local_movements (
      local_id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_id INTEGER NOT NULL,
      operation_id TEXT NOT NULL,
      resource TEXT NOT NULL,
      row_json TEXT NOT NULL,
      server_id INTEGER,
      state TEXT NOT NULL DEFAULT 'pending',
      error TEXT,
      UNIQUE (owner_id, operation_id)
    )''');
    await db.execute('''CREATE TABLE sync_metadata (
      owner_id INTEGER PRIMARY KEY,
      last_success TEXT
    )''');
  }

  Future<int> enqueue(int owner, String operationId, String resource,
      Map<String, dynamic> body, Map<String, dynamic> row) async {
    final db = await _database;
    return db.transaction((txn) async {
      final localId = await txn.insert('local_movements', {
        'owner_id': owner,
        'operation_id': operationId,
        'resource': resource,
        'row_json': jsonEncode(row),
        'state': 'pending',
      });
      await txn.insert('pending_operations', {
        'owner_id': owner,
        'operation_id': operationId,
        'resource': resource,
        'local_id': localId,
        'payload': jsonEncode({...body, 'operation_id': operationId}),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'state': 'pending',
      });
      return -localId;
    });
  }

  Future<List<Map<String, Object?>>> operations(int owner,
      {bool all = false}) async {
    final db = await _database;
    return db.query('pending_operations',
        where: all
            ? 'owner_id = ?'
            : "owner_id = ? AND state IN ('pending', 'sending', 'session_required')",
        whereArgs: [owner],
        orderBy: 'local_id');
  }

  Future<Map<String, Object?>?> localMovement(int owner, int localId) async {
    final db = await _database;
    final rows = await db.query('local_movements',
        where: 'owner_id = ? AND local_id = ?', whereArgs: [owner, localId]);
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> setOperationState(int owner, String operationId, String state,
      {String? error, int? attempts, DateTime? nextAttempt}) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update(
          'pending_operations',
          {
            'state': state,
            'error': error,
            if (attempts != null) 'attempts': attempts,
            'next_attempt_at': nextAttempt?.toUtc().toIso8601String(),
          },
          where: 'owner_id = ? AND operation_id = ?',
          whereArgs: [owner, operationId]);
      await txn.update('local_movements', {'state': state, 'error': error},
          where: 'owner_id = ? AND operation_id = ?',
          whereArgs: [owner, operationId]);
    });
  }

  Future<void> acknowledge(int owner, String operationId, int serverId) async {
    if (serverId <= 0) {
      throw ArgumentError('Identificador de servidor inválido');
    }
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update('local_movements',
          {'server_id': serverId, 'state': 'synced', 'error': null},
          where: 'owner_id = ? AND operation_id = ?',
          whereArgs: [owner, operationId]);
      await txn.delete('pending_operations',
          where: 'owner_id = ? AND operation_id = ?',
          whereArgs: [owner, operationId]);
    });
  }

  /// La lista combina la copia remota y las creaciones locales sin duplicar
  /// una operación que llegó al servidor antes de perderse su respuesta.
  Future<List<Map<String, dynamic>>> visibleRows(
      int owner, String resource, List<Map<String, dynamic>> remote) async {
    final db = await _database;
    return db.transaction((txn) async {
      final local = await txn.query('local_movements',
          where: 'owner_id = ? AND resource = ?',
          whereArgs: [owner, resource],
          orderBy: 'local_id');
      final result =
          remote.map((row) => Map<String, dynamic>.from(row)).toList();
      for (final entry in local) {
        final operationId = entry['operation_id'];
        final serverId = entry['server_id'];
        final found = remote.any((row) =>
            row['operation_id'] == operationId ||
            (serverId != null && row['id'] == serverId));
        if (found) {
          await txn.delete('pending_operations',
              where: 'owner_id = ? AND operation_id = ?',
              whereArgs: [owner, operationId]);
          await txn.delete('local_movements',
              where: 'owner_id = ? AND operation_id = ?',
              whereArgs: [owner, operationId]);
          continue;
        }
        result.add({
          ...Map<String, dynamic>.from(
              jsonDecode(entry['row_json'] as String) as Map),
          'id': serverId ?? -(entry['local_id'] as int),
          '_operation_id': operationId,
          '_sync_state': entry['state'],
          '_sync_error': entry['error'],
        });
      }
      return result;
    });
  }

  Future<DateTime?> lastSuccess(int owner) async {
    final db = await _database;
    final rows = await db
        .query('sync_metadata', where: 'owner_id = ?', whereArgs: [owner]);
    final value = rows.isEmpty ? null : rows.single['last_success'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  Future<void> markSyncSuccess(int owner) async {
    final db = await _database;
    await db.insert(
        'sync_metadata',
        {
          'owner_id': owner,
          'last_success': DateTime.now().toUtc().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> replaceRejected(
      int owner,
      int localId,
      String operationId,
      String resource,
      Map<String, dynamic> body,
      Map<String, dynamic> row) async {
    final db = await _database;
    await db.transaction((txn) async {
      final previous = await txn.query('local_movements',
          where: "owner_id = ? AND local_id = ? AND state = 'error'",
          whereArgs: [owner, localId]);
      if (previous.isEmpty) {
        throw StateError('El registro ya no requiere corrección');
      }
      await txn.delete('pending_operations',
          where: 'owner_id = ? AND operation_id = ?',
          whereArgs: [owner, previous.single['operation_id']]);
      await txn.update(
          'local_movements',
          {
            'operation_id': operationId,
            'row_json': jsonEncode(row),
            'state': 'pending',
            'error': null
          },
          where: 'owner_id = ? AND local_id = ?',
          whereArgs: [owner, localId]);
      await txn.insert('pending_operations', {
        'owner_id': owner,
        'local_id': localId,
        'operation_id': operationId,
        'resource': resource,
        'payload': jsonEncode({...body, 'operation_id': operationId}),
        'state': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String()
      });
    });
  }

  Future<LocalSnapshot?> read(int ownerId, String resource) async {
    final db = await _database;
    final entries = await db.query('snapshots',
        where: 'owner_id = ? AND resource = ?', whereArgs: [ownerId, resource]);
    if (entries.isEmpty) return null;
    final entry = entries.single;
    return LocalSnapshot(
      (jsonDecode(entry['payload'] as String) as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      DateTime.parse(entry['downloaded_at'] as String),
    );
  }

  Future<void> save(int ownerId, String resource,
      List<Map<String, dynamic>> rows, DateTime downloadedAt) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(
        'snapshots',
        {
          'owner_id': ownerId,
          'resource': resource,
          'payload': jsonEncode(rows),
          'downloaded_at': downloadedAt.toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> invalidate(int ownerId, String resource) async {
    final db = await _database;
    await db.delete('snapshots',
        where: 'owner_id = ? AND resource = ?', whereArgs: [ownerId, resource]);
  }

  /// Retira solo la respuesta antigua, preservando descargas más recientes.
  Future<void> discard(
      int ownerId, String resource, DateTime downloadedAt) async {
    final db = await _database;
    await db.delete('snapshots',
        where: 'owner_id = ? AND resource = ? AND downloaded_at = ?',
        whereArgs: [ownerId, resource, downloadedAt.toUtc().toIso8601String()]);
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await (await opening).close();
    _opening = null;
  }
}
