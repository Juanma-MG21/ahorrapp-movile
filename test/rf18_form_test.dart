import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/screens/gastos/agregar_gasto_screen.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/qr_parser_service.dart';
import 'package:ahorrapp_movil/services/offline_sync_service.dart';
import 'package:ahorrapp_movil/core/storage/offline_database.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

class _Api extends Mock implements ApiClient {}

class _Local extends OfflineDatabase {
  Map<String, dynamic>? saved;
  @override
  Future<LocalSnapshot?> read(int owner, String resource) async => null;
  @override
  Future<int> enqueue(int owner, String operationId, String resource, Map<String, dynamic> body, Map<String, dynamic> row) async {
    saved = body;
    return -1;
  }
  @override
  Future<List<Map<String, Object?>>> operations(int owner, {bool all = false}) async => [];
  @override
  Future<DateTime?> lastSuccess(int owner) async => null;
}


void main() {
  testWidgets('corrige monto, descripción, mes y año antes de enviar el gasto',
      (tester) async {
    final previousAuth = AuthService.instance;
    final previousClient = GastosService.client;
    final previousSync = OfflineSyncService.instance;
    final local = _Local();
    final sync = OfflineSyncService(database: local, autoSend: false);
    OfflineSyncService.instance = sync;
    final api = _Api();
    final storage = _Storage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((call) async =>
        call.namedArguments[#key] == 'auth_user'
            ? jsonEncode({'id': 7, 'nombre': 'Prueba'})
            : 'test-token');
    AuthService.instance = AuthService.test(api, storage);
    GastosService.client = api;
    addTearDown(() async {
      await sync.dispose();
      OfflineSyncService.instance = previousSync;
      AuthService.instance = previousAuth;
      GastosService.client = previousClient;
    });
    when(() => api.get('/categorias', token: any(named: 'token')))
        .thenAnswer((_) async => {'categorias': []});
    when(() => api.getList('/dependientes', token: any(named: 'token')))
        .thenAnswer((_) async => []);
    await tester.pumpWidget(MaterialApp(
        home: AgregarGastoScreen(
      gastoParaEditar: QrParserService.parse('Tienda\nTotal 45000\n05/10/2025'),
    )));
    await tester.pumpAndSettle();
    expect(local.saved, isNull);
    await tester.enterText(find.byType(TextField).at(0), '500,50');
    await tester.enterText(find.byType(TextField).at(1), 'Compra corregida');
    await tester.ensureVisible(find.text('05/10/2025'));
    await tester.tap(find.text('05/10/2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '09/04/2024');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('04/09/2024'), findsOneWidget);
    expect(local.saved, isNull);
    await tester.ensureVisible(find.text('Crear gasto'));
    await tester.tap(find.text('Crear gasto'));
    await tester.pumpAndSettle();
    expect(local.saved!['datos'], containsPair('monto', 500.5));
    expect(local.saved!['datos'], containsPair('descripcion', 'Compra corregida'));
    expect(local.saved!['datos'], containsPair('fecha_registro', '2024-09-04'));
  });
}
