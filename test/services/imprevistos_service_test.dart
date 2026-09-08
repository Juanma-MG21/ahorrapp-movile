import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/imprevistos_service.dart';
import 'package:ahorrapp_movil/models/imprevisto_model.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockApiClient mockClient;
  late MockAuthService mockAuth;

  setUp(() {
    mockClient = MockApiClient();
    mockAuth = MockAuthService();
    
    ImprevistosService.client = mockClient;
    AuthService.instance = mockAuth;

    registerFallbackValue(Uri());
    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
  });

  group('ImprevistosService', () {
    final tImprevisto = ImprevistoModel(
      monto: 75000.0,
      descripcion: 'Prueba',
      fecha: DateTime.now(),
    );

    test('crearImprevisto debe enviar tipo_flujo y subtipo_modulo correctos', () async {
      when(() => mockClient.post(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true, 'ID_detalle': 123});

      final id = await ImprevistosService.crearImprevisto(tImprevisto);

      expect(id, 123);
      verify(() => mockClient.post('/movimientos', 
        token: 'fake_token',
        body: {
          'tipo_flujo': 'Salida',
          'subtipo_modulo': 'Imprevisto',
          'datos': tImprevisto.toRequestBody(),
        },
      )).called(1);
    });

    test('obtenerImprevistos debe devolver lista de modelos', () async {
      when(() => mockClient.getList(any(), token: any(named: 'token')))
          .thenAnswer((_) async => [
            {
              'id': 1,
              'monto': '50000',
              'fecha': '2023-01-01',
              'categoria': 'Salud',
              'descripcion': 'Test'
            }
          ]);

      final resultado = await ImprevistosService.obtenerImprevistos();

      expect(resultado.length, 1);
      expect(resultado.first.monto, 50000.0);
      expect(resultado.first.categoriaNombre, 'Salud');
    });

    test('actualizarImprevisto debe llamar al endpoint PUT correcto', () async {
      when(() => mockClient.put(any(), body: any(named: 'body'), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true});

      await ImprevistosService.actualizarImprevisto(10, tImprevisto);

      verify(() => mockClient.put('/movimientos/imprevistos/10', 
        token: 'fake_token',
        body: tImprevisto.toRequestBody(),
      )).called(1);
    });

    test('eliminarImprevisto debe devolver true en éxito', () async {
      when(() => mockClient.delete(any(), token: any(named: 'token')))
          .thenAnswer((_) async => {'ok': true});

      final exito = await ImprevistosService.eliminarImprevisto(1);

      expect(exito, true);
    });
  });
}
