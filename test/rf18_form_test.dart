import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/screens/gastos/agregar_gasto_screen.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/qr_parser_service.dart';

class _Storage extends Mock implements FlutterSecureStorage {}

class _Api extends Mock implements ApiClient {}

void main() {
  testWidgets('corrige monto, descripción, mes y año antes de enviar el gasto',
      (tester) async {
    final previousAuth = AuthService.instance;
    final previousClient = GastosService.client;
    final api = _Api();
    final storage = _Storage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'test-token');
    AuthService.instance = AuthService.test(api, storage);
    GastosService.client = api;
    addTearDown(() {
      AuthService.instance = previousAuth;
      GastosService.client = previousClient;
    });
    when(() => api.get('/categorias', token: any(named: 'token')))
        .thenAnswer((_) async => {'categorias': []});
    when(() => api.getList('/dependientes', token: any(named: 'token')))
        .thenAnswer((_) async => []);
    Map<String, dynamic>? saved;
    when(() => api.post('/movimientos',
        token: any(named: 'token'),
        body: any(named: 'body'))).thenAnswer((call) async {
      saved = call.namedArguments[#body] as Map<String, dynamic>;
      return {'ID_detalle': 1};
    });
    await tester.pumpWidget(MaterialApp(
        home: AgregarGastoScreen(
      gastoParaEditar: QrParserService.parse('Tienda\nTotal 45000\n05/10/2025'),
    )));
    await tester.pumpAndSettle();
    expect(saved, isNull);
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
    expect(saved, isNull);
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(saved!['datos'], containsPair('monto', 500.5));
    expect(saved!['datos'], containsPair('descripcion', 'Compra corregida'));
    expect(saved!['datos'], containsPair('fecha_registro', '2024-09-04'));
  });
}
