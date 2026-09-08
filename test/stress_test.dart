import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:ahorrapp_movil/models/imprevisto_model.dart';

void main() {
  group('Stress Test: Validaciones de Datos en ImprevistoModel', () {
    final random = Random();
    
    test('1000 iteraciones de mapeo JSON con datos aleatorios', () {
      for (int i = 0; i < 1000; i++) {
        final double randomMonto = (random.nextDouble() * 10000000).roundToDouble();
        final String randomDesc = 'Descripción aleatoria ${random.nextInt(10000)}';
        final DateTime randomFecha = DateTime.now().subtract(Duration(days: random.nextInt(365)));
        
        final json = {
          'id': random.nextInt(100000),
          'id_categoria': random.nextInt(50),
          'monto': randomMonto.toString(),
          'descripcion': randomDesc,
          'fecha': randomFecha.toIso8601String(),
          'categoria': 'Categoría ${random.nextInt(10)}',
        };

        final model = ImprevistoModel.fromJson(json);

        expect(model.monto, randomMonto);
        expect(model.descripcion, randomDesc);
        expect(model.idCategoria, isNotNull);
      }
    });

    test('Prueba de valores extremos en montos', () {
      final largeJson = {
        'id': 1,
        'id_categoria': 1,
        'monto': '999999999999.99', // Valor muy alto
        'descripcion': 'Fin del mundo',
        'fecha': '2026-12-31T23:59:59.000',
        'categoria': 'Emergencia',
      };

      final model = ImprevistoModel.fromJson(largeJson);
      expect(model.monto, 999999999999.99);
    });

    test('Prueba de descripciones con caracteres especiales', () {
      const specialChars = '¡!¿?@#\$%^&*()_+-=[]{}|;:",.<>/\\';
      final json = {
        'id': 1,
        'id_categoria': 1,
        'monto': '100',
        'descripcion': specialChars,
        'fecha': '2026-01-01T00:00:00.000',
        'categoria': 'Otros',
      };

      final model = ImprevistoModel.fromJson(json);
      expect(model.descripcion, specialChars);
    });
  });
}
