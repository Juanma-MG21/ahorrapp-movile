import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/screens/gastos/agregar_gasto_screen.dart';
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
    
    GastosService.client = mockClient;
    AuthService.instance = mockAuth;

    // Configuración por defecto de mocks
    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
    when(() => mockClient.get('/categorias', token: any(named: 'token')))
        .thenAnswer((_) async => {'ok': true, 'categorias': []});
    when(() => mockClient.getList('/dependientes', token: any(named: 'token')))
        .thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: AgregarGastoScreen(),
    );
  }

  group('AgregarGastoScreen', () {
    testWidgets('debe renderizar los elementos básicos del formulario', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Carga de datos iniciales

      expect(find.text('Agregar gasto'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Monto')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Descripción')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Categoría')), findsOneWidget);
    });

    testWidgets('debe mostrar SnackBar si el monto es inválido', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Intentamos crear sin monto
      final btn = find.text('Crear gasto');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      expect(find.text('Por favor, ingresa un monto válido'), findsOneWidget);
    });

    testWidgets('debe llamar a crearGasto cuando se llena el monto y se da a guardar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      when(() => mockClient.post(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true, 'ID_detalle': 1});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Ingresamos monto
      await tester.enterText(find.byType(TextField).at(0), '50000');
      
      // Tap en el botón de crear
      final btn = find.text('Crear gasto');
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
