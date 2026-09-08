import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/ahorros/modulo_ahorros.dart';
import 'package:ahorrapp_movil/services/ahorros_service.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuth;
  late MockApiClient mockClient;

  setUp(() {
    mockAuth = MockAuthService();
    mockClient = MockApiClient();
    AuthService.instance = mockAuth;
    AhorrosService.client = mockClient;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'token');
  });

  testWidgets('ModuloAhorros muestra lista y resumen', (WidgetTester tester) async {
    when(() => mockClient.getList(any(), token: any(named: 'token')))
        .thenAnswer((_) async => [
          {'id': 1, 'nombre': 'Test Meta', 'monto_objetivo': 1000, 'monto_actual': 100}
        ]);

    await tester.pumpWidget(const MaterialApp(home: ModuloAhorros()));
    await tester.pump(); // Cargar datos

    expect(find.text('Mis Ahorros'), findsOneWidget);
    expect(find.text('Test Meta'), findsOneWidget);
    expect(find.text('\$100'), findsNWidgets(2));
  });
}
