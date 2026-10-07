import 'dart:async';
import 'dart:convert';

import 'package:ahorrapp_movil/app.dart';
import 'package:ahorrapp_movil/core/network/api_client.dart';
import 'package:ahorrapp_movil/screens/auth/auth_gate.dart';
import 'package:ahorrapp_movil/screens/auth/login_screen.dart';
import 'package:ahorrapp_movil/screens/main_screen.dart';
import 'package:ahorrapp_movil/screens/gastos/modulo_gastos.dart';
import 'package:ahorrapp_movil/screens/reportes/reportes_screen.dart';
import 'package:ahorrapp_movil/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageMock extends Mock implements FlutterSecureStorage {}

class ApiMock extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageMock storage;
  late ApiMock api;
  late AuthService service;
  late Map<String, String> values;
  late int googleCalls;
  const user = {'id': 7, 'nombre': 'Prueba', 'email': 'test@example.test'};

  setUp(() {
    values = {};
    googleCalls = 0;
    storage = StorageMock();
    api = ApiMock();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
        (invocation) async => values[invocation.namedArguments[#key]]);
    when(() =>
            storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((invocation) async {
      values[invocation.namedArguments[#key] as String] =
          invocation.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((invocation) async {
      values.remove(invocation.namedArguments[#key]);
    });
    when(() => api.post('/auth/login', body: any(named: 'body')))
        .thenAnswer((_) async => {'token': 'test-token', 'usuario': user});
    service = AuthService.test(api, storage, googleSignOut: () async {
      googleCalls++;
    });
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> login({bool remember = true}) => service.login(
      email: 'test@example.test', password: 'test', rememberSession: remember);

  test(
      'Logout elimina token, usuario, PIN y biometría de memoria y almacenamiento',
      () async {
    await login();
    await service.savePin('1234');
    values['biometric_enabled'] = 'true';
    expect(await service.hasSession(), isTrue);
    await service.logout();
    expect(await service.hasSession(), isFalse);
    expect(await service.getToken(), isNull);
    expect(await service.getCurrentUser(), isNull);
    expect(await service.hasPinSet(), isFalse);
    expect(await service.isBiometricEnabled(), isFalse);
    expect(values, isEmpty);
    expect(googleCalls, 1);
  });

  test('Reabrir después de logout no recupera una sesión recordada', () async {
    await login();
    await service.logout();
    final reopened = AuthService.test(api, storage);
    expect(await reopened.hasSession(), isFalse);
    expect(await reopened.getCurrentUser(), isNull);
  });

  test('Logout también elimina una sesión solo en memoria', () async {
    await login(remember: false);
    expect(values, isEmpty);
    expect(await service.hasSession(), isTrue);
    await service.logout();
    expect(await service.hasSession(), isFalse);
  });

  test('Un fallo de Google no mantiene la sesión local', () async {
    service = AuthService.test(api, storage, googleSignOut: () async {
      throw Exception('Google no disponible');
    });
    await login();
    await service.logout();
    expect(values, isEmpty);
    expect(await service.hasSession(), isFalse);
  });

  test('Las credenciales locales se eliminan antes de esperar a Google',
      () async {
    final google = Completer<void>();
    service =
        AuthService.test(api, storage, googleSignOut: () => google.future);
    await login();
    final logout = service.logout();
    await Future<void>.delayed(Duration.zero);
    expect(values, isEmpty);
    google.complete();
    await logout;
    expect(await service.hasSession(), isFalse);
  });

  test('Una lectura anterior al logout no restaura el token', () async {
    final pendingRead = Completer<String?>();
    when(() => storage.read(key: 'auth_token'))
        .thenAnswer((_) => pendingRead.future);
    final read = service.getToken();
    await Future<void>.delayed(Duration.zero);
    await service.logout();
    pendingRead.complete('old-token');
    expect(await read, isNull);
    when(() => storage.read(key: 'auth_token')).thenAnswer((_) async => null);
    expect(await service.hasSession(), isFalse);
  });

  test('Una lectura anterior al logout no restaura el usuario', () async {
    final pendingRead = Completer<String?>();
    when(() => storage.read(key: 'auth_user'))
        .thenAnswer((_) => pendingRead.future);
    final read = service.getCurrentUser();
    await Future<void>.delayed(Duration.zero);
    await service.logout();
    pendingRead.complete(jsonEncode(user));
    expect(await read, isNull);
  });

  test('Dos cierres simultáneos comparten la limpieza', () async {
    await login();
    await Future.wait([service.logout(), service.logout()]);
    expect(googleCalls, 1);
    expect(await service.hasSession(), isFalse);
  });

  test('Una sesión recordada válida se recupera antes de cerrar', () async {
    await login();
    final reopened = AuthService.test(api, storage);
    expect(await reopened.hasSession(), isTrue);
    expect((await reopened.getCurrentUser())?.id, 7);
  });

  for (final route in ['/home', '/gastos', '/reportes']) {
    testWidgets('Acceso directo sin sesión a $route muestra login',
        (tester) async {
      final previous = AuthService.instance;
      AuthService.instance = service;
      addTearDown(() => AuthService.instance = previous);
      await tester.pumpWidget(const AhorrApp());
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsWidgets);
      expect(find.byType(MainScreen), findsNothing);
      expect(find.byType(ModuloGastos), findsNothing);
      expect(find.byType(ReportesScreen), findsNothing);
    });
  }

  testWidgets('Cerrar sesión borra historial y reabrir la ruta pide login',
      (tester) async {
    final previous = AuthService.instance;
    AuthService.instance = service;
    addTearDown(() => AuthService.instance = previous);
    await login();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, initialRoute: '/private', routes: {
      '/': (_) => const SizedBox(),
      '/private': (_) => const AuthGate(child: Scaffold(body: Text('PRIVADO'))),
      '/login': (_) => const LoginScreen(),
    }));
    await tester.pumpAndSettle();
    expect(find.text('PRIVADO'), findsOneWidget);
    await service.logout();
    navigator.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    navigator.currentState!.pushNamed('/private');
    await tester.pumpAndSettle();
    expect(find.text('PRIVADO'), findsNothing);
    expect(find.byType(LoginScreen), findsWidgets);
  });
}
