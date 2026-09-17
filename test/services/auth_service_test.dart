import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';

class _FakeApiClient extends ApiClient {
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    lastBody = body;

    if (body != null &&
        (body.containsKey('email') || body.containsKey('Email'))) {
      return {'message': 'Se ha enviado un código de verificación'};
    }

    throw ApiException('email required');
  }
}

void main() {
  group('AuthService forgot password', () {
    test(
      'envía el email con el formato compatible y acepta respuesta message',
      () async {
        final api = _FakeApiClient();
        final service = AuthService.forTesting(api);

        final result = await service.forgotPassword(
          email: 'usuario@ejemplo.com',
        );

        expect(api.lastBody, {
          'email': 'usuario@ejemplo.com',
          'Email': 'usuario@ejemplo.com',
        });
        expect(result, 'Se ha enviado un código de verificación');
      },
    );
  });
}
