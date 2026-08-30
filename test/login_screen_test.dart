import 'package:ahorrapp_movil/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la vista principal de login', (tester) async {
    await tester.pumpWidget(const AhorrApp());

    expect(find.text('AhorrApp'), findsOneWidget);
    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pin_rounded), findsOneWidget);
  });
}
