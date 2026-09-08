import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/services/local_parser_service.dart';

void main() {
  group('LocalParserService - Extracción de Montos', () {
    test('debe extraer números directos', () {
      expect(LocalParserService.parseGasto("gasté 50000").monto, 50000.0);
      expect(LocalParserService.parseGasto("12500 en comida").monto, 12500.0);
    });

    test('debe extraer palabras numéricas simples', () {
      expect(LocalParserService.parseGasto("diez mil").monto, 10000.0);
      expect(LocalParserService.parseGasto("veinte mil pesos").monto, 20000.0);
      expect(LocalParserService.parseGasto("cincuenta y cinco mil").monto, 55000.0);
    });

    test('debe extraer millones y jerga (palos)', () {
      expect(LocalParserService.parseIngreso("un millón de pesos").monto, 1000000.0);
      expect(LocalParserService.parseIngreso("dos palos").monto, 2000000.0);
      expect(LocalParserService.parseIngreso("un millón quinientos mil").monto, 1500000.0);
    });

    test('debe extraer jerga de miles (lucas)', () {
      expect(LocalParserService.parseGasto("cincuenta lucas").monto, 50000.0);
      expect(LocalParserService.parseGasto("dos lucas").monto, 2000.0);
    });

    test('debe manejar combinaciones complejas', () {
      // "ciento cincuenta mil" -> 150000
      expect(LocalParserService.parseGasto("ciento cincuenta mil pesos").monto, 150000.0);
    });
  });

  group('LocalParserService - Detección de Categorías', () {
    test('debe detectar categorías de gastos por palabras clave', () {
      expect(LocalParserService.parseGasto("pizza de diez mil").categoriaNombre, 'Alimentación');
      expect(LocalParserService.parseGasto("el bus me costó tres mil").categoriaNombre, 'Transporte');
      expect(LocalParserService.parseGasto("netflix del mes").categoriaNombre, 'Entretenimiento');
      expect(LocalParserService.parseGasto("fui al doctor").categoriaNombre, 'Salud');
    });

    test('debe detectar categorías de ingresos', () {
      expect(LocalParserService.parseIngreso("me pagaron la nómina").categoriaNombre, 'Salario');
      expect(LocalParserService.parseIngreso("vendí mi celular").categoriaNombre, 'Venta');
      expect(LocalParserService.parseIngreso("fue un regalo").categoriaNombre, 'Regalo');
    });

    test('debe devolver "Otros" si no encuentra coincidencia', () {
      expect(LocalParserService.parseGasto("algo raro de 5000").categoriaNombre, 'Otros');
    });
  });

  group('LocalParserService - Normalización', () {
    test('debe ignorar acentos y mayúsculas', () {
      expect(LocalParserService.parseGasto("PÍZZA").categoriaNombre, 'Alimentación');
      expect(LocalParserService.parseGasto("NÓMINA").categoriaNombre, 'Otros'); // Nómina es para Ingreso
      expect(LocalParserService.parseIngreso("NÓMINA").categoriaNombre, 'Salario');
    });
  });
}
