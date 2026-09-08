import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/ingresos/modulo_ingresos.dart';
import 'package:ahorrapp_movil/screens/ingresos/agregar_ingreso_screen.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockApiClient mockClient;
  late MockAuthService mockAuth;

  setUp(() {
    mockClient = MockApiClient();
    mockAuth = MockAuthService();
    
    IngresosService.client = mockClient;
    GastosService.client = mockClient;
    AuthService.instance = mockAuth;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
    when(() => mockClient.getList(any(), token: any(named: 'token')))
        .thenAnswer((_) async => []);
    when(() => mockClient.get(any(), token: any(named: 'token')))
        .thenAnswer((_) async => {'ok': true, 'categorias': []});
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('ModuloIngresos Widget Tests (Voice Presence)', () {
    testWidgets('Debe mostrar la opcion de registro por voz en el menu expandido', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const ModuloIngresos()));
      await tester.pumpAndSettle();

      // Abrir menú FAB
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verificar que el ícono de micrófono está presente
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Registro por voz'), findsOneWidget);
    });
  });

  group('AgregarIngresoScreen Widget Tests', () {
    testWidgets('Debe mostrar campos obligatorios', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AgregarIngresoScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsAtLeast(2)); 
    });
  });
}
