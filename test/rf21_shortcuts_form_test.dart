import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/core/storage/offline_database.dart';
import 'package:ahorrapp_movil/screens/gastos/agregar_gasto_screen.dart';
import 'package:ahorrapp_movil/screens/ingresos/agregar_ingreso_screen.dart';
import 'package:ahorrapp_movil/screens/auth/login_screen.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/offline_query_service.dart';
import 'package:ahorrapp_movil/services/offline_sync_service.dart';
import 'package:ahorrapp_movil/services/local_parser_service.dart';
import 'package:ahorrapp_movil/services/quick_actions_service.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

class _Api extends Mock implements ApiClient {}

class _Actions extends Mock implements QuickActions {}

class _Local extends OfflineDatabase {
  Map<String, dynamic>? saved;
  @override
  Future<LocalSnapshot?> read(int owner, String resource) async => null;
  @override
  Future<int> enqueue(int owner, String operationId, String resource,
      Map<String, dynamic> body, Map<String, dynamic> row) async {
    saved = body;
    return -1;
  }

  @override
  Future<List<Map<String, Object?>>> operations(int owner,
          {bool all = false}) async =>
      [];
  @override
  Future<DateTime?> lastSuccess(int owner) async => null;
}

class _Queries extends OfflineQueryService {
  _Queries(super.database);
  @override
  Future<List<T>> query<T>(String resource, ApiClient client,
          T Function(Map<String, dynamic>) decode,
          {String? listKey}) async =>
      resource == '/categorias'
          ? [
              {'id': 1, 'nombre': 'Transporte', 'activa': true},
              {'id': 2, 'nombre': 'Salario', 'activa': true},
              {'id': 3, 'nombre': 'Alimentación', 'activa': false},
            ].map(decode).toList()
          : [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue((String _) {});
  late AuthService oldAuth;
  late OfflineQueryService oldQueries;
  late OfflineSyncService oldSync;
  late QuickActions oldActions;
  late _Storage storage;
  late _Api api;
  late _Local local;
  late _Queries queries;
  late OfflineSyncService sync;
  late _Actions actions;
  late Map<String, String> values;
  void authenticate() {
    values['auth_token'] = 'test-token';
    values['auth_user'] = jsonEncode({'id': 7, 'nombre': 'Prueba'});
    AuthService.instance =
        AuthService.test(api, storage, googleSignOut: () async {});
  }

  setUp(() {
    oldAuth = AuthService.instance;
    oldQueries = OfflineQueryService.instance;
    oldSync = OfflineSyncService.instance;
    oldActions = QuickActionsService.actions;
    QuickActionsService.reset();
    SharedPreferences.setMockInitialValues({});
    values = {};
    storage = _Storage();
    api = _Api();
    actions = _Actions();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((call) async {
      values.remove(call.namedArguments[#key]);
    });
    AuthService.instance =
        AuthService.test(api, storage, googleSignOut: () async {});
    local = _Local();
    queries = _Queries(local);
    OfflineQueryService.instance = queries;
    sync = OfflineSyncService(database: local, autoSend: false);
    OfflineSyncService.instance = sync;
    QuickActionsService.actions = actions;
    when(() => actions.initialize(any())).thenAnswer((_) async {});
    when(() => actions.setShortcutItems(any())).thenAnswer((_) async {});
  });
  tearDown(() async {
    QuickActionsService.reset();
    queries.dispose();
    await sync.dispose();
    AuthService.instance = oldAuth;
    OfflineQueryService.instance = oldQueries;
    OfflineSyncService.instance = oldSync;
    QuickActionsService.actions = oldActions;
  });
  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const Scaffold(body: Text('Inicio'));
    })));
    return context;
  }

  test('registra dos accesos con recursos de ícono propios una sola vez',
      () async {
    await QuickActionsService.initialize();
    await QuickActionsService.initialize();
    final items = verify(() => actions.setShortcutItems(captureAny()))
        .captured
        .single as List<ShortcutItem>;
    expect(items.map((item) => item.type), ['action_gasto', 'action_ingreso']);
    expect(items.map((item) => item.icon),
        ['ic_shortcut_gasto', 'ic_shortcut_ingreso']);
    verify(() => actions.initialize(any())).called(1);
  });
  test('sistema sin shortcuts no impide iniciar la app', () async {
    when(() => actions.initialize(any()))
        .thenThrow(UnsupportedError('Sin soporte'));
    await QuickActionsService.initialize();
    verifyNever(() => actions.setShortcutItems(any()));
  });
  testWidgets(
      'arranque frío conserva gasto hasta que haya sesión y pantalla lista',
      (tester) async {
    when(() => actions.initialize(any())).thenAnswer((call) async {
      (call.positionalArguments.single as void Function(
          String))('action_gasto');
    });
    await QuickActionsService.initialize();
    final context = await host(tester);
    QuickActionsService.attach(context);
    await tester.pumpAndSettle();
    expect(find.byType(AgregarGastoScreen), findsNothing);
    authenticate();
    QuickActionsService.attach(context);
    await tester.pumpAndSettle();
    expect(find.byType(AgregarGastoScreen), findsOneWidget);
    expect(local.saved, isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });
  testWidgets('acceso ingreso no se duplica y descarta acciones desconocidas',
      (tester) async {
    authenticate();
    final context = await host(tester);
    QuickActionsService.attach(context);
    QuickActionsService.receive('desconocido');
    await tester.pumpAndSettle();
    expect(find.byType(AgregarIngresoScreen), findsNothing);
    QuickActionsService.receive('action_ingreso');
    QuickActionsService.receive('action_ingreso');
    await tester.pumpAndSettle();
    expect(find.byType(AgregarIngresoScreen), findsOneWidget);
    expect(local.saved, isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
  });
  testWidgets(
      'un contexto descartado no abre rutas y el siguiente retoma el acceso',
      (tester) async {
    authenticate();
    final context = await host(tester);
    QuickActionsService.attach(context);
    QuickActionsService.detach(context);
    QuickActionsService.receive('action_gasto');
    await tester.pumpAndSettle();
    expect(find.byType(AgregarGastoScreen), findsNothing);
    QuickActionsService.attach(context);
    await tester.pumpAndSettle();
    expect(find.byType(AgregarGastoScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });
  testWidgets('logout protege el formulario abierto por shortcut',
      (tester) async {
    authenticate();
    final context = await host(tester);
    QuickActionsService.attach(context);
    QuickActionsService.receive('action_ingreso');
    await tester.pumpAndSettle();
    await AuthService.instance.logout();
    await tester.pumpAndSettle();
    expect(find.byType(AgregarIngresoScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(local.saved, isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });
  testWidgets(
      'dictado de ingreso precarga un registro nuevo y guarda solo las correcciones',
      (tester) async {
    authenticate();
    await tester.pumpWidget(MaterialApp(
        home: AgregarIngresoScreen(
            ingresoParaEditar: LocalParserService.parseIngreso(
                'Recibí 500,50 pesos de salario'))));
    await tester.pumpAndSettle();
    expect(find.text('Agregar ingreso'), findsOneWidget);
    expect(find.text('500,50'), findsOneWidget);
    expect(local.saved, isNull);
    await tester.enterText(find.byType(TextField).at(0), '700,25');
    await tester.enterText(find.byType(TextField).at(1), 'Ingreso corregido');
    await tester.ensureVisible(find.text('Guardar ingreso'));
    await tester.tap(find.text('Guardar ingreso'));
    await tester.pumpAndSettle();
    expect(local.saved!['subtipo_modulo'], 'Ingreso');
    expect(local.saved!['datos']['monto'], 700.25);
    expect(local.saved!['datos']['descripcion'], 'Ingreso corregido');
    expect(local.saved!['datos']['id_categoria'], 2);
  });
  testWidgets(
      'dictado de gasto conserva revisión y no elige categoría inactiva',
      (tester) async {
    authenticate();
    await tester.pumpWidget(MaterialApp(
        home: AgregarGastoScreen(
            gastoParaEditar:
                LocalParserService.parseGasto('Gasté 1000 pesos en comida'))));
    await tester.pumpAndSettle();
    expect(find.text('Crear gasto'), findsOneWidget);
    expect(local.saved, isNull);
    await tester.enterText(find.byType(TextField).at(0), '1200');
    await tester.ensureVisible(find.text('Crear gasto'));
    await tester.tap(find.text('Crear gasto'));
    await tester.pumpAndSettle();
    expect(local.saved!['datos']['monto'], 1200);
    expect(local.saved!['datos']['id_categoria'], isNull);
  });
}
