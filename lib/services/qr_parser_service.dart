import '../models/gasto_model.dart';
import 'receipt_parser_service.dart';

class QrParserService {
  // Solo interpreta texto con un monto identificado, nunca URLs de verificación.
  static GastoModel? parse(String textoQr) =>
      ReceiptParserService.parse(textoQr);
}
