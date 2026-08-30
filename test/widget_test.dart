import 'package:ahorrapp_movil/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navega desde login hasta registro', (tester) async {
    await tester.pumpWidget(const AhorrApp());

    final registerLink = find.text('Registrate').first;
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('navega desde login hasta recuperar contrasena', (tester) async {
    await tester.pumpWidget(const AhorrApp());

    final forgotPasswordLink = find.text('Olvidaste tu contrasena?');
    await tester.ensureVisible(forgotPasswordLink);
    await tester.tap(forgotPasswordLink);
    await tester.pumpAndSettle();

    expect(find.text('Recuperar acceso'), findsOneWidget);
    expect(find.text('Enviar enlace de recuperacion'), findsOneWidget);
  });
}