import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/network/api_client.dart';

class NotificacionesService {
  final FirebaseMessaging _mensajeria = FirebaseMessaging.instance;
  final ApiClient _api = const ApiClient();

  Future<void> inicializar(String token) async {
    NotificationSettings configuracion = await _mensajeria.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (configuracion.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken = await _mensajeria.getToken();
      if (fcmToken != null) {
        await _registrarToken(fcmToken, token);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage mensaje) {
      print('Notificación recibida en foreground: ${mensaje.notification?.title}');
    });
  }

  Future<void> _registrarToken(String fcmToken, String jwtToken) async {
    try {
      await _api.post(
        '/push-tokens',
        body: {
          'fcm_token': fcmToken,
          'plataforma': 'android',
        },
        token: jwtToken,
      );
    } catch (e) {
      print('Error al registrar push token: $e');
    }
  }
}