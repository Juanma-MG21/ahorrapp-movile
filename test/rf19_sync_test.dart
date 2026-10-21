import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/core/storage/offline_database.dart';
import 'package:ahorrapp_movil/models/ahorro_model.dart';
import 'package:ahorrapp_movil/models/gasto_model.dart';
import 'package:ahorrapp_movil/models/ingreso_model.dart';
import 'package:ahorrapp_movil/services/ahorros_service.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
import 'package:ahorrapp_movil/services/offline_query_service.dart';
import 'package:ahorrapp_movil/services/offline_sync_service.dart';
import 'package:ahorrapp_movil/services/reportes_service.dart';
import 'package:ahorrapp_movil/services/session_logout.dart';
import 'package:ahorrapp_movil/widgets/sync_state_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

class _Api extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late OfflineDatabase database;
  late OfflineQueryService queries;
  late OfflineSyncService sync;
  late _Api api;
  late _Storage storage;
  late Map<String, String> values;
  late AuthService previousAuth;
  late OfflineQueryService previousQueries;
  late OfflineSyncService previousSync;
  const income = '/movimientos/ingresos';
  const expense = '/movimientos/gastos';
  const savings = '/movimientos/ahorros';
  final data = {
    'monto': 1000.0,
    'fecha_registro': '2026-10-07',
    'descripcion': 'Prueba'
  };
  Map<String, dynamic> body([String module = 'Ingreso']) => {
        'tipo_flujo': module == 'Ingreso' ? 'Entrada' : 'Salida',
        'subtipo_modulo': module,
        'datos': {...data},
      };
  void authenticate(int id) {
    values['auth_token'] = 'token-$id';
    values['auth_user'] = jsonEncode({'id': id, 'nombre': 'Cuenta $id'});
    AuthService.instance =
        AuthService.test(api, storage, googleSignOut: () async {});
  }

  void capabilities() => when(() =>
          api.get('/movimientos/sincronizacion', token: any(named: 'token')))
      .thenAnswer((_) async => {'protocolo': 1, 'idempotencia': true});
  void success() => when(() => api.post('/movimientos',
          token: any(named: 'token'), body: any(named: 'body')))
      .thenAnswer((call) async => {
            'ID_detalle': 20,
            'operation_id': (call.namedArguments[#body] as Map)['operation_id']
          });
  Future<List<Map<String, dynamic>>> rows(String resource) =>
      queries.localList(resource, (row) => row);

  setUp(() async {
    previousAuth = AuthService.instance;
    previousQueries = OfflineQueryService.instance;
    previousSync = OfflineSyncService.instance;
    directory = await Directory.systemTemp.createTemp('ahorrapp_rf19_sync_');
    database = OfflineDatabase(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/offline.db');
    queries = OfflineQueryService(database);
    OfflineQueryService.instance = queries;
    api = _Api();
    storage = _Storage();
    values = {};
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((call) async {
      values.remove(call.namedArguments[#key]);
    });
    when(() =>
            storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((call) async {
      values[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String;
    });
    authenticate(7);
    sync = OfflineSyncService(database: database, client: api, autoSend: false);
    OfflineSyncService.instance = sync;
    capabilities();
    success();
  });
  tearDown(() async {
    await sync.dispose();
    queries.dispose();
    await database.close();
    AuthService.instance = previousAuth;
    OfflineSyncService.instance = previousSync;
    OfflineQueryService.instance = previousQueries;
    await directory.delete(recursive: true);
  });

  test(
      'ingreso, gasto y ahorro se guardan primero sin HTTP y sobreviven a reapertura',
      () async {
    final ids = [
      await IngresosService.crearIngreso(
          IngresoModel(monto: 1000, fechaRegistro: DateTime(2026, 10, 7))),
      await GastosService.crearGasto(
          GastoModel(monto: 2000, fecha: DateTime(2026, 10, 7))),
      await AhorrosService.crearAhorro(
          AhorroModel(nombre: 'Meta', montoObjetivo: 3000)),
    ];
    expect(ids.every((id) => id < 0), isTrue);
    verifyNever(() =>
        api.post(any(), token: any(named: 'token'), body: any(named: 'body')));
    final operations = await database.operations(7);
    expect(operations.length, 3);
    expect(operations.map((op) => op['operation_id']).toSet().length, 3);
    await database.close();
    for (final resource in [income, expense, savings]) {
      final local = await rows(resource);
      expect(local.single['_sync_state'], 'pending');
      expect(local.single['id'] as int, lessThan(0));
    }
    expect((await database.operations(7)).map((op) => op['payload']),
        operations.map((op) => op['payload']));
    expect(sync.status.value.pending, 3);
  });

  test(
      'confirmar cambia ID y estado; repetir sync y descarga no duplica la lista',
      () async {
    await sync.create(income, body());
    final uuid = (await database.operations(7)).single['operation_id'];
    await sync.sync(force: true);
    expect(await database.operations(7, all: true), isEmpty);
    expect((await rows(income)).single['id'], 20);
    expect((await rows(income)).single['_sync_state'], 'synced');
    expect(await database.lastSuccess(7), isNotNull);
    await sync.sync(force: true);
    verify(() => api.post('/movimientos',
        token: any(named: 'token'), body: any(named: 'body'))).called(1);
    final remote = [
      {'id': 20, 'monto': 1000, 'operation_id': uuid}
    ];
    expect(await database.visibleRows(7, income, remote), remote);
    expect(await database.localMovement(7, 1), isNull);
  });

  test(
      'respuesta perdida reenvía exactamente el UUID y payload original tras reinicio',
      () async {
    await sync.create(income, body());
    final operation = (await database.operations(7)).single;
    final saved = jsonDecode(operation['payload'] as String);
    Map<String, dynamic>? committed;
    when(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: any(named: 'body'))).thenAnswer((call) async {
      committed = call.namedArguments[#body] as Map<String, dynamic>;
      throw ApiException('Respuesta perdida', isNetworkError: true);
    });
    await sync.sync(force: true);
    expect(committed, saved);
    expect((await database.operations(7)).single['state'], 'pending');
    expect((await database.operations(7)).single['attempts'], 1);
    await sync.dispose();
    await database.close();
    sync = OfflineSyncService(database: database, client: api, autoSend: false);
    OfflineSyncService.instance = sync;
    when(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: any(named: 'body'))).thenAnswer((call) async {
      expect(call.namedArguments[#body], committed);
      return {'ID_detalle': 20, 'operation_id': committed!['operation_id']};
    });
    await sync.sync(force: true);
    expect(await database.operations(7), isEmpty);
    expect((await rows(income)).length, 1);
  });

  test('no se envía a servidor antiguo o sin migración', () async {
    await sync.create(income, body());
    when(() =>
            api.get('/movimientos/sincronizacion', token: any(named: 'token')))
        .thenThrow(ApiException('Migración pendiente', statusCode: 503));
    await sync.sync(force: true);
    verifyNever(() =>
        api.post(any(), token: any(named: 'token'), body: any(named: 'body')));
    expect((await database.operations(7)).single['state'], 'pending');
    expect(sync.status.value.message, contains('conservan'));
  });

  test(
      'token vencido conserva cola, permite consulta local y exige reautenticación',
      () async {
    await sync.create(income, body());
    when(() =>
            api.get('/movimientos/sincronizacion', token: any(named: 'token')))
        .thenThrow(ApiException('Token vencido', statusCode: 403));
    await sync.sync(force: true);
    expect(sync.status.value.connection, 'session');
    expect((await database.operations(7)).single['state'], 'session_required');
    when(() => api.getList(income, token: any(named: 'token')))
        .thenThrow(ApiException('Token vencido', statusCode: 403));
    expect(
        (await queries.query(income, api, IngresoModel.fromJson))
            .single
            .isSynced,
        isFalse);
    authenticate(7);
    capabilities();
    await sync.sync(force: true);
    expect(await database.operations(7, all: true), isEmpty);
  });

  test('una cuenta no consulta ni sincroniza pendientes de otra', () async {
    await sync.create(income, body());
    authenticate(8);
    expect(await rows(income), isEmpty);
    await sync.sync(force: true);
    verifyNever(() =>
        api.post(any(), token: any(named: 'token'), body: any(named: 'body')));
    expect((await database.operations(7)).length, 1);
    await sync.create(expense, body('Gasto'));
    await sync.sync(force: true);
    expect((await database.operations(7)).length, 1);
    expect(await database.operations(8), isEmpty);
    authenticate(7);
    expect((await rows(income)).length, 1);
  });

  test(
      'cambio de cuenta durante un envío confirma solo al propietario y no envía el siguiente',
      () async {
    await sync.create(income, body());
    await sync.create(income, body());
    final entered = Completer<Map>();
    final response = Completer<Map<String, dynamic>>();
    when(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: any(named: 'body'))).thenAnswer((call) {
      entered.complete(call.namedArguments[#body] as Map);
      return response.future;
    });
    final sending = sync.sync(force: true);
    final first = await entered.future;
    authenticate(8);
    response
        .complete({'ID_detalle': 20, 'operation_id': first['operation_id']});
    await sending;
    expect((await database.operations(7)).length, 1);
    expect(await database.operations(8), isEmpty);
    expect(await rows(income), isEmpty);
    verify(() => api.post('/movimientos',
        token: 'token-7', body: any(named: 'body'))).called(1);
  });

  test('dos sincronizaciones simultáneas comparten un envío', () async {
    await sync.create(income, body());
    final entered = Completer<Map>();
    final response = Completer<Map<String, dynamic>>();
    when(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: any(named: 'body'))).thenAnswer((call) {
      entered.complete(call.namedArguments[#body] as Map);
      return response.future;
    });
    final one = sync.sync(force: true);
    final sent = await entered.future;
    final two = sync.sync(force: true);
    response.complete({'ID_detalle': 20, 'operation_id': sent['operation_id']});
    await Future.wait([one, two]);
    verify(() => api.post('/movimientos',
        token: any(named: 'token'), body: any(named: 'body'))).called(1);
  });

  test(
      'rechazo requiere corrección online y nuevo UUID solo tras confirmar ausencia en servidor',
      () async {
    final id = await sync.create(income, body());
    final uuid = (await database.operations(7)).single['operation_id'];
    when(() => api.post('/movimientos',
            token: any(named: 'token'), body: any(named: 'body')))
        .thenThrow(ApiException('Categoría desactivada', statusCode: 400));
    await sync.sync(force: true);
    expect((await database.operations(7, all: true)).single['state'], 'error');
    expect(await database.operations(7), isEmpty);
    await sync.sync(force: true);
    verify(() => api.post('/movimientos',
        token: any(named: 'token'), body: any(named: 'body'))).called(1);
    when(() => api.get('/movimientos/sincronizacion/operaciones/$uuid',
            token: any(named: 'token')))
        .thenAnswer((_) async => {'encontrado': true});
    await expectLater(
        sync.correctRejected(id, income, body()), throwsA(isA<ApiException>()));
    expect(
        (await database.operations(7, all: true)).single['operation_id'], uuid);
    when(() => api.get('/movimientos/sincronizacion/operaciones/$uuid',
            token: any(named: 'token')))
        .thenAnswer((_) async => {'encontrado': false});
    await sync.correctRejected(id, income, body());
    expect((await database.operations(7)).single['operation_id'], isNot(uuid));
    expect((await rows(income)).length, 1);
    success();
    await sync.sync(force: true);
    expect(await database.operations(7, all: true), isEmpty);
  });

  test('desconexión al corregir no altera operación rechazada', () async {
    final id = await sync.create(income, body());
    final uuid = (await database.operations(7)).single['operation_id'];
    await database.setOperationState(7, uuid as String, 'error',
        error: 'Categoría');
    when(() =>
            api.get('/movimientos/sincronizacion', token: any(named: 'token')))
        .thenThrow(ApiException('Sin conexión', isNetworkError: true));
    await expectLater(
        sync.correctRejected(id, income, body()), throwsA(isA<ApiException>()));
    expect(
        (await database.operations(7, all: true)).single['operation_id'], uuid);
    expect((await database.operations(7, all: true)).single['state'], 'error');
  });

  test('un GET reconoce UUID guardado antes de perder respuesta y limpia cola',
      () async {
    await sync.create(income, body());
    final uuid = (await database.operations(7)).single['operation_id'];
    when(() => api.getList(income, token: any(named: 'token')))
        .thenAnswer((_) async => [
              {
                'id': 20,
                'monto': 1000,
                'fecha': '2026-10-07',
                'operation_id': uuid
              },
            ]);
    final list = await queries.query(income, api, IngresoModel.fromJson);
    expect(list.length, 1);
    expect(list.single.isSynced, isTrue);
    expect(await database.operations(7, all: true), isEmpty);
  });

  test('fallo en outbox revierte también movimiento local; no anuncia éxito',
      () async {
    await database.operations(7);
    final raw =
        await databaseFactoryFfi.openDatabase('${directory.path}/offline.db');
    await raw.execute(
        "CREATE TRIGGER fail_outbox BEFORE INSERT ON pending_operations BEGIN SELECT RAISE(ABORT, 'sin espacio simulado'); END");
    await expectLater(
        sync.create(income, body()), throwsA(isA<ApiException>()));
    expect(await database.operations(7, all: true), isEmpty);
    expect(await rows(income), isEmpty);
    await raw.execute('DROP TRIGGER fail_outbox');
  });

  test('migrar la base de etapa 1 conserva sus copias y habilita la cola',
      () async {
    final location = '${directory.path}/old.db';
    final old = await databaseFactoryFfi.openDatabase(location,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE snapshots (owner_id INTEGER NOT NULL, resource TEXT NOT NULL, payload TEXT NOT NULL, downloaded_at TEXT NOT NULL, PRIMARY KEY(owner_id,resource))');
              await db.execute(
                  "CREATE TABLE pending_operations (owner_id INTEGER NOT NULL, operation_id TEXT NOT NULL, resource TEXT NOT NULL, payload TEXT NOT NULL, state TEXT NOT NULL DEFAULT 'pending', attempts INTEGER NOT NULL DEFAULT 0, error TEXT, PRIMARY KEY(owner_id,operation_id))");
            }));
    await old.insert('snapshots', {
      'owner_id': 7,
      'resource': income,
      'payload': '[{"id":3,"monto":500}]',
      'downloaded_at': '2026-10-07T12:00:00Z'
    });
    await old.close();
    final upgraded =
        OfflineDatabase(factory: databaseFactoryFfi, databasePath: location);
    try {
      expect((await upgraded.read(7, income))!.rows.single['id'], 3);
      expect(await upgraded.operations(7), isEmpty);
      await upgraded.enqueue(
          7, 'f2b31e6e-676c-4a43-8cf9-77a7bd28a691', income, body(), data);
      expect((await upgraded.operations(7)).length, 1);
      expect((await upgraded.read(7, income))!.rows.single['id'], 3);
    } finally {
      await upgraded.close();
    }
  });

  test('enviando tras cierre se recupera con el mismo UUID', () async {
    await sync.create(income, body());
    final uuid = (await database.operations(7)).single['operation_id'];
    await database.setOperationState(7, uuid as String, 'sending');
    await database.close();
    await sync.sync(force: true);
    expect(await database.operations(7), isEmpty);
    final sent = verify(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: captureAny(named: 'body'))).captured.single as Map;
    expect(sent['operation_id'], uuid);
  });

  test('sin sesión y monto inválido no crean operaciones', () async {
    await expectLater(
        sync.create(income, {
          ...body(),
          'datos': {...data, 'monto': 0}
        }),
        throwsA(isA<ApiException>()));
    values.clear();
    AuthService.instance =
        AuthService.test(api, storage, googleSignOut: () async {});
    await expectLater(
        sync.create(income, body()), throwsA(isA<ApiException>()));
    expect(await database.operations(7), isEmpty);
  });

  test('pendientes no admiten edición, eliminación ni abonos offline',
      () async {
    final id = await sync.create(expense, body('Gasto'));
    final before = (await database.operations(7)).single['payload'];
    await expectLater(
        GastosService.actualizarGasto(
            id, GastoModel(id: id, monto: 2000, fecha: DateTime(2026, 10, 7))),
        throwsA(isA<ApiException>()));
    await expectLater(
        GastosService.eliminarGasto(id), throwsA(isA<ApiException>()));
    await expectLater(
        IngresosService.eliminarIngreso(id), throwsA(isA<ApiException>()));
    await expectLater(
        AhorrosService.eliminarAhorro(id), throwsA(isA<ApiException>()));
    await expectLater(
        AhorrosService.registrarAbono(
            AhorroModel(id: id, nombre: 'Meta', montoObjetivo: 5000), 100),
        throwsA(isA<ApiException>()));
    expect((await database.operations(7)).single['payload'], before);
    verifyNever(() =>
        api.post(any(), token: any(named: 'token'), body: any(named: 'body')));
  });

  test('reportes consultan solo el servidor y no suman pendientes locales',
      () async {
    await sync.create(expense, body('Gasto'));
    when(() => api.get(any(), token: any(named: 'token')))
        .thenAnswer((_) async => {'datos': []});
    final list = await ReportesService(apiClient: api).getGastosPorCategoria(
        fechaInicio: DateTime(2026, 10, 1), fechaFin: DateTime(2026, 10, 31));
    expect(list, isEmpty);
    expect((await rows(expense)).length, 1);
    verify(() => api.get(
        '/reportes/gastos/categorias?fecha_inicio=2026-10-01&fecha_fin=2026-10-31',
        token: 'token-7')).called(1);
  });

  testWidgets(
      'salir advierte, cancelar mantiene sesión y confirmar retiene pendientes',
      (tester) async {
    await tester.runAsync(() => sync.create(income, body()));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => SessionLogout.confirmAndLogout(context),
                  child: const Text('Salir'),
                )))));
    await tester.tap(find.text('Salir'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Tienes 1 registros'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await AuthService.instance.getCurrentUser(), isNotNull);
    await tester.tap(find.text('Salir'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
    expect(await AuthService.instance.getCurrentUser(), isNull);
    expect(await tester.runAsync(() => database.operations(7)), hasLength(1));
  });

  testWidgets('cada estado muestra claramente pendientes, sesión y errores',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      SyncStateBadge(state: 'pending'),
      SyncStateBadge(state: 'synced'),
      SyncStateBadge(state: 'session_required'),
      SyncStateBadge(state: 'error', error: 'Categoría desactivada'),
    ]))));
    expect(find.text('Pendiente de sincronizar'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.textContaining('inicia sesión'), findsOneWidget);
    expect(find.textContaining('Categoría desactivada'), findsOneWidget);
  });
}
