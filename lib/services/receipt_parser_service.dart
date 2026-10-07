import '../data/categoria_keywords.dart';
import '../models/gasto_model.dart';

/// Reglas compartidas para texto de recibos. No usa IDs ni referencias como monto.
class ReceiptParserService {
  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  static double? amount(String text) {
    final normalized = normalize(text);
    final number = r'(\d+(?:[.,]\d+)*)';
    // Total tiene prioridad sobre valor/importe. Los límites excluyen subtotal.
    for (final label in [
      r'total(?:\s+a\s+pagar)?',
      r'monto',
      r'valor(?:\s+pagado)?',
      r'importe',
      r'a\s+pagar',
      r'pago'
    ]) {
      final prefix = r'\s*[:=]?\s*(?:cop\s*\$?|\$\s*(?:cop)?)?\s*';
      final matches = RegExp('\\b$label\\b$prefix$number', caseSensitive: false)
          .allMatches(normalized);
      for (final match in matches) {
        final value = money(match.group(1)!);
        if (value != null && value > 0) return value;
      }
    }
    // Sin etiqueta solo admitimos cantidades con indicador monetario explícito.
    final match = RegExp(r'(?:\$|\bcop\b)\s*' + number, caseSensitive: false)
        .firstMatch(normalized);
    return match == null ? null : money(match.group(1)!);
  }

  static double? money(String raw) {
    var value = raw;
    final comma = value.lastIndexOf(',');
    final dot = value.lastIndexOf('.');
    final last = comma > dot ? comma : dot;
    if (last >= 0 && value.length - last - 1 <= 2) {
      // Último separador con uno o dos dígitos: parte decimal.
      value =
          '${value.substring(0, last).replaceAll(RegExp(r'[.,]'), '')}.${value.substring(last + 1)}';
    } else {
      value = value.replaceAll(RegExp(r'[.,]'), '');
    }
    final amount = double.tryParse(value);
    return amount != null && amount.isFinite && amount > 0 ? amount : null;
  }

  static DateTime? date(String text) {
    final pattern = RegExp(
        r'\b(?:(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})|(\d{1,2})[/\-](\d{1,2})[/\-](\d{4}))\b');
    for (final match in pattern.allMatches(text)) {
      final iso = match.group(1) != null;
      final year = int.parse(match.group(iso ? 1 : 6)!);
      final month = int.parse(match.group(iso ? 2 : 5)!);
      final day = int.parse(match.group(iso ? 3 : 4)!);
      final candidate = DateTime(year, month, day);
      // DateTime normaliza 31/02: comparamos los componentes para descartarlo.
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
    }
    return null;
  }

  static GastoModel? parse(String text) {
    text = text.trim();
    // Un enlace de verificación no contiene los datos de un gasto.
    if (text.isEmpty ||
        RegExp(r'^(?:https?://|www\.)', caseSensitive: false).hasMatch(text)) {
      return null;
    }
    final value = amount(text);
    if (value == null) return null;
    final normalized = normalize(text);
    String? category;
    for (final entry in mapeoCategoriasKeywords.entries) {
      if (RegExp('\\b${RegExp.escape(normalize(entry.key))}\\b')
          .hasMatch(normalized)) {
        category = entry.value;
        break;
      }
    }
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    final merchant = lines.firstWhere(
      (line) =>
          RegExp(r'[a-zA-ZÁÉÍÓÚáéíóúñÑ]{3}').hasMatch(line) &&
          !RegExp(r'\b(total|subtotal|fecha|monto|valor|referencia|nit|iva)\b')
              .hasMatch(normalize(line)),
      orElse: () => 'Registro por comprobante',
    );
    return GastoModel(
      monto: value,
      fecha: date(text) ?? DateTime.now(),
      descripcion:
          merchant.length > 140 ? merchant.substring(0, 140) : merchant,
      categoriaNombre: category,
    );
  }
}
