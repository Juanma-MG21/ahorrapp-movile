import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/services/ocr_parser_service.dart';
import 'package:ahorrapp_movil/services/qr_parser_service.dart';
import 'package:ahorrapp_movil/services/receipt_parser_service.dart';

void main() {
  for (final parser
      in {'OCR': OcrParserService.parse, 'QR': QrParserService.parse}.entries) {
    group(parser.key, () {
      test('extrae total final, fecha y comercio sin confundir subtotal', () {
        final gasto = parser.value(
            'Tienda Ejemplo\nSubtotal 40.000\nIVA 5.000\nTOTAL \$45.000\nFecha 05/10/2026')!;
        expect(gasto.monto, 45000);
        expect(gasto.fecha, DateTime(2026, 10, 5));
        expect(gasto.descripcion, 'Tienda Ejemplo');
        expect(gasto.categoriaNombre, isNull);
      });
      test('reconoce ISO, monto pequeño y separadores monetarios', () {
        for (final item in {
          '500': 500,
          '45.000,00': 45000,
          '45,000.50': 45000.5,
          '45000,75': 45000.75,
          '1.500.000': 1500000
        }.entries) {
          final gasto =
              parser.value('Tienda\nTOTAL COP ${item.key}\n2026-10-05')!;
          expect(gasto.monto, item.value);
          expect(gasto.fecha, DateTime(2026, 10, 5));
        }
      });
      test('ignora referencias aun si son mayores que el total', () {
        expect(
            parser.value('Referencia 987654321\nTOTAL \$45.000')!.monto, 45000);
      });
      test('rechaza URLs y contenidos sin monto identificable', () {
        for (final text in [
          '',
          'hola',
          'Referencia 123456789',
          'Fecha 05/10/2026',
          'https://example.com/comprobante/123456789',
          'TOTAL 0'
        ]) {
          expect(parser.value(text), isNull, reason: text);
        }
      });
      test('detecta categoría por comercio sin asignar un ID', () {
        final gasto = parser.value('Panadería\nTotal 5000')!;
        expect(gasto.categoriaNombre, 'Alimentación');
        expect(gasto.idCategoria, isNull);
      });
    });
  }
  test('descarta fechas imposibles y acepta años bisiestos', () {
    expect(ReceiptParserService.date('31/02/2026'), isNull);
    expect(ReceiptParserService.date('29/02/2025'), isNull);
    expect(ReceiptParserService.date('29/02/2024'), DateTime(2024, 2, 29));
    expect(ReceiptParserService.date('2026-13-01'), isNull);
  });
}
