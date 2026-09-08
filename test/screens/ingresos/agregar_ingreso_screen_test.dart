import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/ingresos/agregar_ingreso_screen.dart';
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
    
    IngresosService.client = mockClient;
    AuthService.instance = mockAuth;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
    when(() => mockClient.get('/categorias', token: any(named: 'token')))
        .thenAnswer((_) async => {'ok': true, 'categorias': []});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: AgregarIngresoScreen(),
    );
  }

  group('AgregarIngresoScreen', () {
    testWidgets('debe renderizar el título y campos de texto', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Agregar ingreso'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Ej: Pago de nómina'), findsOneWidget);
    });

    testWidgets('debe mostrar error si se intenta guardar sin monto', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final btn = find.text('Guardar ingreso');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      expect(find.text('Por favor, ingresa un monto válido'), findsOneWidget);
    });

    testWidgets('debe realizar el POST exitosamente', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockClient.post(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true, 'ID_detalle': 55});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Monto es el primer TextField en AgregarIngresoScreen (basado en el código leído)
      await tester.enterText(find.byType(TextField).at(0), '1000000');
      await tester.enterText(find.byType(TextField).at(1), 'Sueldo Septiembre');
      await tester.enterText(find.byType(TextField).at(2), 'Mi Empresa');

      final btn = find.text('Guardar ingreso');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      verify(() => mockClient.post('/movimientos', 
        token: any(named: 'token'),
        body: any(named: 'body'),
      )).called(1);
    });
  });
}
