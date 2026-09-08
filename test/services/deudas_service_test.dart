import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:ahorrapp_movil/services/deudas_service.dart';
import 'package:ahorrapp_movil/models/deuda_model.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockApiClient mockClient;
  late MockAuthService mockAuth;

  setUpAll(() {
    registerFallbackValue(DeudaModel(fuente: '', monto: 0));
  });

  setUp(() {
    mockClient = MockApiClient();
    mockAuth = MockAuthService();
    
    DeudasService.client = mockClient;
    AuthService.instance = mockAuth;

    when(() => mockAuth.getToken()).thenAnswer((_) async => 'fake_token');
  });

  group('DeudasService Integration Tests', () {
    test('obtenerDeudas debe probar múltiples endpoints y manejar respuestas envueltas', () async {
      when(() => mockClient.getList('/movimientos/deudas', token: any(named: 'token')))
          .thenThrow(Exception('404'));
      
      when(() => mockClient.get('/deudas', token: any(named: 'token')))
          .thenAnswer((_) async => {
            'ok': true,
            'deudas': [
              {'id_deudas': 1, 'fuente': 'Banco', 'monto': 1000}
            ]
          });

      final resultado = await DeudasService.obtenerDeudas();

      expect(resultado.length, 1);
      expect(resultado.first.fuente, 'Banco');
      verify(() => mockClient.get('/deudas', token: 'fake_token')).called(1);
    });

    test('crearDeuda debe usar el patrón de /movimientos como flujos de Salida', () async {
      final deuda = DeudaModel(fuente: 'Prestamo', monto: 5000);
      
      when(() => mockClient.post('/movimientos', token: any(named: 'token'), body: any(named: 'body')))
          .thenAnswer((_) async => {'ok': true, 'id_deudas': 101});

      final id = await DeudasService.crearDeuda(deuda);

      expect(id, 101);
      verify(() => mockClient.post('/movimientos', 
        token: 'fake_token', 
        body: any(named: 'body', that: allOf(
          containsPair('tipo_flujo', 'Salida'),
          containsPair('subtipo_modulo', 'Deuda'),
          containsPair('datos', isA<Map>())
        ))
      )).called(1);
    });

    test('pagarCuota debe incrementar cuotas y actualizar estado', () async {
      final deuda = DeudaModel(id: 1, fuente: 'Banco', monto: 1000, cuotasTotal: 10, cuotasPagadas: 5);
      
      when(() => mockClient.put(any(), token: any(named: 'token'), body: any(named: 'body')))
          .thenAnswer((_) async => {'ok': true});

      await DeudasService.pagarCuota(deuda);

      verify(() => mockClient.put('/movimientos/deudas/1', 
        token: 'fake_token', 
        body: any(named: 'body', that: allOf(
          containsPair('cuotas_pagadas', 6),
          containsPair('estado', 'pendiente')
        ))
      )).called(1);
    });
  });
}
