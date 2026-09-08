import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/deudas/modulo_deudas.dart';
import 'package:ahorrapp_movil/services/deudas_service.dart';
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
    DeudasService.client = mockClient;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'token');
    when(() => mockClient.getList(any(), token: any(named: 'token')))
        .thenAnswer((_) async => []);
  });

  testWidgets('ModuloDeudas muestra lista de obligaciones', (WidgetTester tester) async {
    when(() => mockClient.getList(any(), token: any(named: 'token')))
        .thenAnswer((_) async => [
          {'id_deudas': 1, 'fuente': 'Tarjeta Visa', 'monto': 5000, 'cuotas_total': 12, 'cuotas_pagadas': 2}
        ]);

    await tester.pumpWidget(const MaterialApp(home: ModuloDeudas()));
    await tester.pump(); 

    expect(find.text('Mis Deudas'), findsOneWidget);
    expect(find.text('Tarjeta Visa'), findsOneWidget);
    expect(find.text('2 de 12 cuotas'), findsOneWidget);
  });
}
