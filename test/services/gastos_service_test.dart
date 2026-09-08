import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/gastos_service.dart';
import 'package:ahorrapp_movil/models/gasto_model.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockApiClient mockClient;
  late MockAuthService mockAuth;

  setUp(() {
    mockClient = MockApiClient();
    mockAuth = MockAuthService();
    
    // Inyectamos los mocks
    GastosService.client = mockClient;
    AuthService.instance = mockAuth;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
  });

  group('GastosService', () {
    final tGasto = GastoModel(
      monto: 100.0,
      descripcion: 'Test',
      fecha: DateTime(2023, 1, 1),
    );

    test('crearGasto debe llamar al endpoint correcto y devolver ID', () async {
      when(() => mockClient.post(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true, 'ID_detalle': 123});

      final id = await GastosService.crearGasto(tGasto);

      expect(id, 123);
      verify(() => mockClient.post('/movimientos', 
        token: 'fake_token',
        body: any(named: 'body'),
      )).called(1);
    });

    test('obtenerGastos debe devolver lista de modelos', () async {
      when(() => mockClient.getList(any(), token: any(named: 'token')))
          .thenAnswer((_) async => [
            {
              'id': 1,
              'monto': 50.0,
              'fecha': '2023-01-01',
              'categoria': 'Comida',
            }
          ]);

      final resultado = await GastosService.obtenerGastos();

      expect(resultado.length, 1);
      expect(resultado.first.monto, 50.0);
    });

    test('eliminarGasto debe devolver true en éxito', () async {
      when(() => mockClient.delete(any(), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true});

      final exito = await GastosService.eliminarGasto(1);

      expect(exito, true);
    });

    test('obtenerCategorias debe parsear correctamente la respuesta', () async {
      when(() => mockClient.get(any(), token: any(named: 'token')))
          .thenAnswer((_) async => {
            'ok': true,
            'categorias': [{'id': 1, 'nombre': 'Salud'}]
          });

      final cats = await GastosService.obtenerCategorias();

      expect(cats.length, 1);
      expect(cats.first.nombre, 'Salud');
    });
  });
}
