import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/ingresos_service.dart';
import 'package:ahorrapp_movil/models/ingreso_model.dart';

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
  });

  group('IngresosService', () {
    final tIngreso = IngresoModel(
      monto: 500.0,
      fechaRegistro: DateTime(2023, 1, 1),
    );

    test('crearIngreso debe llamar al endpoint correcto', () async {
      when(() => mockClient.post(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true, 'ID_detalle': 999});

      final id = await IngresosService.crearIngreso(tIngreso);

      expect(id, 999);
      verify(() => mockClient.post('/movimientos', 
        token: 'fake_token',
        body: any(named: 'body'),
      )).called(1);
    });

    test('obtenerIngresos debe manejar errores devolviendo lista vacía', () async {
      when(() => mockClient.getList(any(), token: any(named: 'token')))
          .thenThrow(Exception('Error de red'));

      final resultado = await IngresosService.obtenerIngresos();

      expect(resultado, isEmpty);
    });

    test('eliminarIngreso debe devolver false si falla', () async {
      when(() => mockClient.delete(any(), token: any(named: 'token')))
          .thenThrow(Exception());

      final exito = await IngresosService.eliminarIngreso(1);

      expect(exito, false);
    });
  });
}
