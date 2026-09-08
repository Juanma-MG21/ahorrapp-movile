import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/imprevistos/modulo_imprevistos.dart';
import 'package:ahorrapp_movil/screens/imprevistos/agregar_imprevisto_screen.dart';
import 'package:ahorrapp_movil/services/imprevistos_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
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
    
    ImprevistosService.client = mockClient;
    GastosService.client = mockClient;
    IngresosService.client = mockClient;
    AuthService.instance = mockAuth;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
    when(() => mockClient.getList(any(), token: any(named: 'token')))
        .thenAnswer((_) async => []);
    when(() => mockClient.get(any(), token: any(named: 'token')))
        .thenAnswer((_) async => {'ok': true, 'categorias': []});
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('ModuloImprevistos Widget Tests', () {
    testWidgets('Debe mostrar el título y la tarjeta de resumen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const ModuloImprevistos()));
      await tester.pump();

      expect(find.text('Imprevistos del mes'), findsOneWidget);
      expect(find.text('GASTO POR IMPREVISTOS'), findsOneWidget);
    });

    testWidgets('Debe abrir el menú FAB al tocarlo', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const ModuloImprevistos()));
      await tester.pump();

      final fab = find.byType(InkWell).last;
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Agregar manualmente'), findsOneWidget);
    });
  });

  group('AgregarImprevistoScreen Widget Tests', () {
    testWidgets('Debe mostrar campos obligatorios', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AgregarImprevistoScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsAtLeast(2)); 
    });

    testWidgets('Debe validar monto positivo al guardar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const AgregarImprevistoScreen()));
      await tester.pumpAndSettle();

      final saveBtn = find.text('Registrar imprevisto').last;
      await tester.tap(saveBtn);
      await tester.pump(); // Pump for SnackBar
      await tester.pump(const Duration(seconds: 1)); // SnackBar duration

      expect(find.text('Por favor, ingresa un monto positivo'), findsOneWidget);
    });
  });
}
