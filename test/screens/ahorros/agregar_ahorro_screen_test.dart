import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/screens/ahorros/agregar_ahorro_screen.dart';

void main() {
  testWidgets('AgregarAhorroScreen muestra validación si campos están vacíos', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AgregarAhorroScreen()));

    final btnGuardar = find.text('Guardar Meta');
    await tester.tap(btnGuardar);
    await tester.pump();

    // Debería mostrar el snackbar de validación
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Por favor, ingresa un nombre y monto válido (>0)'), findsOneWidget);
  });

  testWidgets('AgregarAhorroScreen permite escribir en los campos', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AgregarAhorroScreen()));

    await tester.enterText(find.byType(TextField).first, 'Ahorro Carro');
    await tester.enterText(find.byType(TextField).last, '50000');

    expect(find.text('Ahorro Carro'), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
  });
}
