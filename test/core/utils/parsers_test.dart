import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/core/utils/parsers.dart';

void main() {
  group('parseMonto', () {
    test('debe convertir un int a double', () {
      expect(parseMonto(100), 100.0);
    });

    test('debe convertir un double a double', () {
      expect(parseMonto(100.5), 100.5);
    });

    test('debe convertir un String numérico a double', () {
      expect(parseMonto("75000.50"), 75000.50);
    });

    test('debe lanzar FormatException si el String no es numérico', () {
      expect(() => parseMonto("abc"), throwsA(isA<FormatException>()));
    });

    test('debe lanzar FormatException si el valor es nulo o de tipo inválido', () {
      expect(() => parseMonto(null), throwsA(isA<FormatException>()));
      expect(() => parseMonto([]), throwsA(isA<FormatException>()));
    });
  });
}
