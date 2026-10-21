import 'dart:convert';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/core/storage/offline_database.dart';
import 'package:ahorrapp_movil/models/ahorro_model.dart';
import 'package:ahorrapp_movil/models/gasto_model.dart';
import 'package:ahorrapp_movil/models/ingreso_model.dart';
import 'package:ahorrapp_movil/services/ahorros_service.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
import 'package:ahorrapp_movil/services/offline_download_service.dart';
import 'package:ahorrapp_movil/services/offline_query_service.dart';
import 'package:ahorrapp_movil/services/offline_sync_service.dart';
import 'package:ahorrapp_movil/widgets/offline_sync_panel.dart';
import 'package:ahorrapp_movil/widgets/sync_state_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// HTTP real con interrupción de transporte controlada y respuesta perdida.
/// No pretende simular el modo avión físico ni el cierre completo del proceso.
class _Gateway extends ApiClient {
  _Gateway() : super(baseUrl: 'http://127.0.0.1:18719/api');
  bool offline = false;
  bool loseNextResponse = false;
  void connected() {
    if (offline) {
      throw ApiException('Desconexión controlada de prueba',
          isNetworkError: true);
    }
  }

  @override
  Future<Map<String, dynamic>> get(String path, {String? token}) {
    connected();
    return super.get(path, token: token);
  }

  @override
  Future<List<dynamic>> getList(String path, {String? token}) {
    connected();
    return super.getList(path, token: token);
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {String? token, Map<String, dynamic>? body}) async {
    connected();
    final result = await super.post(path, token: token, body: body);
    if (loseNextResponse) {
      loseNextResponse = false;
      throw ApiException('Respuesta perdida después del COMMIT',
          isNetworkError: true);
    }
    return result;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'RF-19: SQLite Android, consulta offline, reapertura y HTTP/PostgreSQL sin duplicados',
      (tester) async {
    final api = _Gateway();
    final location = path.join(await getDatabasesPath(),
        'rf19_native_${DateTime.now().microsecondsSinceEpoch}.db');
    var database = OfflineDatabase(databasePath: location);
    var queries = OfflineQueryService(database);
    var sync =
        OfflineSyncService(database: database, client: api, autoSend: false);
    OfflineQueryService.instance = queries;
    OfflineSyncService.instance = sync;
    GastosService.client = api;
    IngresosService.client = api;
    AhorrosService.client = api;
    AuthService.instance = AuthService.test(api, const FlutterSecureStorage(),
        googleSignOut: () async {});
    Future<void> login(int id) => AuthService.instance.login(
        email: 'account$id@test.invalid',
        password: 'fixture-only',
        rememberSession: true);
    try {
      await login(7);
      await OfflineDownloadService.refresh();
      for (final resource in [
        '/movimientos/ingresos',
        '/movimientos/gastos',
        '/movimientos/ahorros',
        '/categorias',
        '/dependientes'
      ]) {
        expect(await database.read(7, resource), isNotNull);
      }
      api.offline = true;
      await IngresosService.crearIngreso(IngresoModel(
          monto: 12000, fechaRegistro: DateTime(2026, 10, 7), idCategoria: 1));
      await GastosService.crearGasto(GastoModel(
          monto: 3000,
          fecha: DateTime(2026, 10, 7),
          idCategoria: 1,
          idDependientes: 1));
      await AhorrosService.crearAhorro(AhorroModel(
          nombre: 'Meta offline', montoObjetivo: 25000, idCategoria: 1));
      final operations = await database.operations(7);
      expect(operations.length, 3);
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: Column(children: [
        OfflineSyncPanel(),
        SyncStateBadge(state: 'pending'),
      ]))));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 pendientes'), findsOneWidget);
      expect(find.text('Pendiente de sincronizar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await sync.dispose();
      queries.dispose();
      await database.close();

      // Una nueva conexión, servicio y sesión recuperan SQLite y secure storage.
      database = OfflineDatabase(databasePath: location);
      queries = OfflineQueryService(database);
      sync =
          OfflineSyncService(database: database, client: api, autoSend: false);
      OfflineQueryService.instance = queries;
      OfflineSyncService.instance = sync;
      AuthService.instance = AuthService.test(api, const FlutterSecureStorage(),
          googleSignOut: () async {});
      expect((await AuthService.instance.getCurrentUser())!.id, 7);
      expect(
          (await IngresosService.obtenerIngresos()).single.isSynced, isFalse);
      expect((await GastosService.obtenerGastos()).single.monto, 3000);
      expect((await AhorrosService.obtenerAhorros()).single.nombre,
          'Meta offline');
      expect((await database.operations(7)).map((op) => op['payload']).toList(),
          operations.map((op) => op['payload']).toList());
      api.offline = false;
      await sync.sync(force: true);
      expect(await database.operations(7, all: true), isEmpty);
      await sync.sync(force: true);
      final token = await AuthService.instance.getToken();
      for (final operation in operations) {
        await api.post('/movimientos',
            token: token,
            body: Map<String, dynamic>.from(
                jsonDecode(operation['payload'] as String) as Map));
        final remote =
            await api.getList(operation['resource'] as String, token: token);
        expect(remote.length, 1);
        expect(
            (remote.single as Map)['operation_id'], operation['operation_id']);
      }
      expect((await IngresosService.obtenerIngresos()).single.isSynced, isTrue);
      expect((await GastosService.obtenerGastos()).single.isSynced, isTrue);
      expect((await AhorrosService.obtenerAhorros()).single.isSynced, isTrue);

      // Una respuesta que se pierde después de escribir PostgreSQL se reintenta.
      await IngresosService.crearIngreso(
          IngresoModel(monto: 9000, fechaRegistro: DateTime(2026, 10, 7)));
      api.loseNextResponse = true;
      await sync.sync(force: true);
      expect((await database.operations(7)).length, 1);
      await sync.sync(force: true);
      expect(await database.operations(7), isEmpty);
      expect(
          (await api.getList('/movimientos/ingresos', token: token)).length, 2);

      api.offline = true;
      await GastosService.crearGasto(
          GastoModel(monto: 1500, fecha: DateTime(2026, 10, 7)));
      api.offline = false;
      await login(8);
      expect(
          await queries.localList('/movimientos/gastos', GastoModel.fromJson),
          isEmpty);
      await sync.sync(force: true);
      expect((await database.operations(7)).length, 1);
      expect(await database.operations(8), isEmpty);
      await login(7);
      await sync.sync(force: true);
      expect(await database.operations(7), isEmpty);
      expect(
          (await api.getList('/movimientos/gastos',
                  token: await AuthService.instance.getToken()))
              .length,
          2);
      debugPrint(
          'RF19_NATIVE_OK: SQLite Android y secure storage persistentes; 3 módulos; HTTP/JWT/PostgreSQL; respuesta perdida; cuenta aislada; cero duplicados.');
    } finally {
      await sync.dispose();
      queries.dispose();
      await database.close();
      await deleteDatabase(location);
      await AuthService.instance.logout();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
