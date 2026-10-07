import '../models/gasto_model.dart';
import 'receipt_parser_service.dart';

class OcrParserService {
  static GastoModel? parse(String textoOcr) =>
      ReceiptParserService.parse(textoOcr);
}
