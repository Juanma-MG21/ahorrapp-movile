import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/core/storage/offline_database.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/offline_query_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
import 'package:ahorrapp_movil/services/ahorros_service.dart';
import 'package:ahorrapp_movil/widgets/offline_query_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Api extends Mock implements ApiClient {}

class _Storage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late OfflineDatabase database;
  late OfflineQueryService queries;
  late _Api api;
  late _Storage storage;
  late Map<String, String> values;
  late AuthService previousAuth;
  late OfflineQueryService previousQueries;
  const resource = '/movimientos/gastos';
  const rows = [
    {'id': 10, 'monto': 5000}
  ];

  Map<String, dynamic> decode(Map<String, dynamic> row) {
    if (row['monto'] is! num) throw const FormatException('monto inválido');
    return row;
  }

  void authenticate(int id) {
    values['auth_token'] = 'token-$id';
    values['auth_user'] = jsonEncode({'id': id, 'nombre': 'Cuenta $id'});
    AuthService.instance =
        AuthService.test(api, storage, googleSignOut: () async {});
  }

  setUp(() async {
    previousAuth = AuthService.instance;
    previousQueries = OfflineQueryService.instance;
    directory = await Directory.systemTemp.createTemp('ahorrapp_rf19_');
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
    authenticate(7);
  });

  tearDown(() async {
    queries.dispose();
    await database.close();
    AuthService.instance = previousAuth;
    OfflineQueryService.instance = previousQueries;
    await directory.delete(recursive: true);
  });

  Future<List<Map<String, dynamic>>> query() =>
      queries.query(resource, api, decode);

  void online(List<Map<String, dynamic>> data) {
    when(() => api.getList(resource, token: any(named: 'token')))
        .thenAnswer((_) async => data);
  }

  void offline() {
    when(() => api.getList(resource, token: any(named: 'token')))
        .thenThrow(ApiException('Sin conexión', isNetworkError: true));
  }

  test('la copia persiste al cerrar y reabrir la base y el servicio', () async {
    online(rows);
    expect(await query(), rows);
    final downloaded = queries.statuses.value[resource]!.downloadedAt;
    expect(queries.statuses.value[resource]!.source, QuerySource.server);
    queries.dispose();
    await database.close();
    database = OfflineDatabase(
        factory: databaseFactoryFfi,
        databasePath: '${directory.path}/offline.db');
    queries = OfflineQueryService(database);
    OfflineQueryService.instance = queries;
    authenticate(7);
    offline();
    expect(await query(), rows);
    expect(queries.statuses.value[resource]!.source, QuerySource.local);
    expect(queries.statuses.value[resource]!.downloadedAt, downloaded);
  });

  test('sin copia no se devuelve una lista vacía que oculte un fallo',
      () async {
    offline();
    await expectLater(query(), throwsA(isA<ApiException>()));
    expect(queries.statuses.value[resource]!.source, QuerySource.unavailable);
    expect(await database.read(7, resource), isNull);
  });

  test('un vacío descargado es una copia válida; un error no la borra',
      () async {
    online([]);
    expect(await query(), isEmpty);
    expect(await database.read(7, resource), isNotNull);
    offline();
    expect(await query(), isEmpty);
    expect(queries.statuses.value[resource]!.source, QuerySource.local);
  });

  test('otra cuenta no consulta la copia; volver a la original la recupera',
      () async {
    online(rows);
    await query();
    authenticate(8);
    offline();
    await expectLater(query(), throwsA(isA<ApiException>()));
    expect(await database.read(8, resource), isNull);
    authenticate(7);
    expect(await query(), rows);
  });

  test('sesión vencida permite consultar copia; un fallo 500 sigue explícito', () async {
    online(rows);
    await query();
    for (final code in [401, 403]) {
      when(() => api.getList(resource, token: any(named: 'token')))
          .thenThrow(ApiException('Rechazo del servidor', statusCode: code));
      expect(await query(), rows);
      expect(queries.statuses.value[resource]!.source, QuerySource.local);
      expect(queries.statuses.value[resource]!.message, contains('sesión venció'));
      expect((await database.read(7, resource))!.rows, rows);
    }
    when(() => api.getList(resource, token: any(named: 'token'))).thenThrow(ApiException('Fallo del servidor', statusCode: 500));
    await expectLater(query(), throwsA(isA<ApiException>()));
    expect(queries.statuses.value[resource]!.source, QuerySource.unavailable);
  });

  test('una respuesta inválida no reemplaza una copia válida', () async {
    online(rows);
    await query();
    online([
      {'id': 10, 'monto': 'incorrecto'}
    ]);
    await expectLater(query(), throwsA(isA<FormatException>()));
    expect((await database.read(7, resource))!.rows, rows);
  });

  test('peticiones simultáneas reutilizan una descarga', () async {
    final response = Completer<List<dynamic>>();
    when(() => api.getList(resource, token: any(named: 'token')))
        .thenAnswer((_) => response.future);
    final first = query();
    final second = query();
    await Future<void>.delayed(Duration.zero);
    response.complete(rows);
    expect(await first, rows);
    expect(await second, rows);
    verify(() => api.getList(resource, token: 'token-7')).called(1);
  });

  test('una respuesta tardía tras cambiar de cuenta no se guarda ni se muestra',
      () async {
    final response = Completer<List<dynamic>>();
    when(() => api.getList(resource, token: any(named: 'token')))
        .thenAnswer((_) => response.future);
    final request = query();
    final assertion = expectLater(request, throwsA(isA<ApiException>()));
    await Future<void>.delayed(Duration.zero);
    authenticate(8);
    response.complete(rows);
    await assertion;
    expect(await database.read(7, resource), isNull);
    expect(await database.read(8, resource), isNull);
    expect(queries.statuses.value, isEmpty);
  });

  test('logout conserva la copia y elimina el estado visible', () async {
    online(rows);
    await query();
    await AuthService.instance.logout();
    expect(queries.statuses.value, isEmpty);
    await expectLater(query(), throwsA(isA<ApiException>()));
    expect((await database.read(7, resource))!.rows, rows);
  });

  test('una escritura online invalida solo la copia del propietario', () async {
    await database.save(8, resource, rows, DateTime.now());
    online(rows);
    await query();
    final result = await queries.onlineMutation(resource, (token) async => 44);
    expect(result, 44);
    expect(await database.read(7, resource), isNull);
    expect(await database.read(8, resource), isNotNull);
    offline();
    await expectLater(query(), throwsA(isA<ApiException>()));
  });

  test('un rechazo de escritura conserva la copia anterior', () async {
    online(rows);
    await query();
    await expectLater(
        queries.onlineMutation(resource, (_) async {
          throw ApiException('Validación', statusCode: 400);
        }),
        throwsA(isA<ApiException>()));
    expect((await database.read(7, resource))!.rows, rows);
  });

  test('una consulta anterior a una escritura no puede restaurar datos viejos',
      () async {
    final response = Completer<List<dynamic>>();
    when(() => api.getList(resource, token: any(named: 'token')))
        .thenAnswer((_) => response.future);
    final request = query();
    final assertion = expectLater(request, throwsA(isA<ApiException>()));
    await Future<void>.delayed(Duration.zero);
    await queries.onlineMutation(resource, (_) async => true);
    response.complete(rows);
    await assertion;
    expect(await database.read(7, resource), isNull);
  });

  test('los tres servicios consultan los mismos modelos tras perder conexión',
      () async {
    final previousGastos = GastosService.client;
    final previousIngresos = IngresosService.client;
    final previousAhorros = AhorrosService.client;
    GastosService.client = api;
    IngresosService.client = api;
    AhorrosService.client = api;
    addTearDown(() {
      GastosService.client = previousGastos;
      IngresosService.client = previousIngresos;
      AhorrosService.client = previousAhorros;
    });
    for (final path in [
      '/movimientos/gastos',
      '/movimientos/ingresos',
      '/movimientos/ahorros'
    ]) {
      when(() => api.getList(path, token: 'token-7')).thenAnswer((_) async => [
            {'id': 21, 'monto': 8500, 'fecha': '2026-10-07', 'meta': 'Viaje'}
          ]);
    }
    expect((await GastosService.obtenerGastos()).single.monto, 8500);
    expect((await IngresosService.obtenerIngresos()).single.monto, 8500);
    expect((await AhorrosService.obtenerAhorros()).single.nombre, 'Viaje');
    when(() => api.getList(any(), token: any(named: 'token')))
        .thenThrow(ApiException('Sin conexión', isNetworkError: true));
    expect((await GastosService.obtenerGastos()).single.id, 21);
    expect((await IngresosService.obtenerIngresos()).single.id, 21);
    expect((await AhorrosService.obtenerAhorros()).single.id, 21);
  });

  test('un fallo en categorías no borra la copia de movimientos', () async {
    online(rows);
    await query();
    when(() => api.get('/categorias', token: 'token-7'))
        .thenAnswer((_) async => {
              'categorias': [
                {'id': 3, 'nombre': 'Transporte'}
              ]
            });
    Map<String, dynamic> category(Map<String, dynamic> row) => row;
    await queries.query('/categorias', api, category, listKey: 'categorias');
    when(() => api.get('/categorias', token: 'token-7'))
        .thenThrow(ApiException('Sin conexión', isNetworkError: true));
    final categories = await queries.query('/categorias', api, category,
        listKey: 'categorias');
    expect(categories.single['nombre'], 'Transporte');
    expect((await database.read(7, resource))!.rows, rows);
  });

  test('descartar una respuesta antigua no borra una descarga más reciente',
      () async {
    final oldDate = DateTime.utc(2026, 10, 7, 15);
    final newDate = oldDate.add(const Duration(seconds: 1));
    await database.save(7, resource, rows, oldDate);
    await database.save(
        7,
        resource,
        [
          {'id': 22, 'monto': 9000}
        ],
        newDate);
    await database.discard(7, resource, oldDate);
    expect((await database.read(7, resource))!.rows.single['id'], 22);
  });

  testWidgets('el aviso distingue una copia vacía del fallo sin copia',
      (tester) async {
    queries.statuses.value = {
      resource: QueryStatus(QuerySource.local,
          downloadedAt: DateTime.utc(2026, 10, 7, 15)),
    };
    var retry = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: OfflineQueryBanner(
                resource: resource, onRetry: () => retry++))));
    expect(find.textContaining('Copia local del'), findsOneWidget);
    await tester.tap(find.text('Actualizar'));
    expect(retry, 1);
    queries.statuses.value = {
      resource: const QueryStatus(QuerySource.unavailable,
          message: 'Aún no hay una copia descargada.'),
    };
    await tester.pump();
    expect(find.text('Aún no hay una copia descargada.'), findsOneWidget);
    expect(find.textContaining('Copia local del'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
