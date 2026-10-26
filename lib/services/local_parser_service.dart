import '../models/gasto_model.dart';
import '../models/ingreso_model.dart';

class LocalParserService {
  static const Map<String, String> _keywordsToGastoCategory = {
    'comi': 'Alimentación',
    'comida': 'Alimentación',
    'restaurante': 'Alimentación',
    'almuerzo': 'Alimentación',
    'cena': 'Alimentación',
    'desayuno': 'Alimentación',
    'mercado': 'Alimentación',
    'empanada': 'Alimentación',
    'hamburguesa': 'Alimentación',
    'pizza': 'Alimentación',
    'bus': 'Transporte',
    'taxi': 'Transporte',
    'uber': 'Transporte',
    'gasolina': 'Transporte',
    'pasaje': 'Transporte',
    'medico': 'Salud',
    'doctor': 'Salud',
    'farmacia': 'Salud',
    'droga': 'Salud',
    'hospital': 'Salud',
    'cine': 'Entretenimiento',
    'netflix': 'Entretenimiento',
    'rumba': 'Entretenimiento',
    'fiesta': 'Entretenimiento',
    'cerveza': 'Entretenimiento',
    'colegio': 'Educación',
    'universidad': 'Educación',
    'curso': 'Educación',
    'libro': 'Educación',
    'arriendo': 'Hogar',
    'luz': 'Servicios',
    'agua': 'Servicios',
    'gas': 'Servicios',
    'internet': 'Servicios',
    'ropa': 'Ropa',
    'camisa': 'Ropa',
    'pantalon': 'Ropa',
    'zapatos': 'Ropa',
  };

  static const Map<String, String> _keywordsToIngresoCategory = {
    'salario': 'Salario',
    'nomina': 'Salario',
    'sueldo': 'Salario',
    'pago': 'Honorarios',
    'honorarios': 'Honorarios',
    'trabajo': 'Honorarios',
    'freelance': 'Honorarios',
    'venta': 'Venta',
    'vendi': 'Venta',
    'vendio': 'Venta',
    'negocio': 'Venta',
    'regalo': 'Regalo',
    'suerte': 'Otros',
    'inversion': 'Inversión',
    'interes': 'Inversión',
  };

  static String _normalize(String text) {
    var withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
    var withoutAccents = 'aeiouunAEIOUUN';
    for (int i = 0; i < withAccents.length; i++) {
      text = text.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return text.toLowerCase();
  }

  static GastoModel parseGasto(String text) {
    final cleanText = _normalize(text);
    final monto = _extractAmount(cleanText);
    final categoria = _extractCategory(cleanText, _keywordsToGastoCategory);

    return GastoModel(
      monto: monto,
      fecha: DateTime.now(),
      descripcion: text,
      categoriaNombre: categoria,
    );
  }

  static IngresoModel parseIngreso(String text) {
    final cleanText = _normalize(text);
    final monto = _extractAmount(cleanText);
    final categoria = _extractCategory(cleanText, _keywordsToIngresoCategory);

    return IngresoModel(
      monto: monto,
      fechaRegistro: DateTime.now(),
      descripcion: text,
      fuente: categoria == 'Salario' ? 'Nómina' : null,
      categoriaNombre: categoria,
    );
  }

  // Evalúa grupos numéricos, no suma cualquier cifra de la descripción.
  // Si hay varios candidatos sin una indicación monetaria inequívoca, deja
  // el monto vacío para que el usuario lo introduzca en la revisión.
  static double _extractAmount(String text) {
    final Map<String, double> values = {
      'cero': 0,
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15,
      'dieciseis': 16,
      'diecisiete': 17,
      'dieciocho': 18,
      'diecinueve': 19,
      'veinte': 20,
      'veintiuno': 21,
      'veintiun': 21,
      'veintidos': 22,
      'veintitres': 23,
      'veinticuatro': 24,
      'veinticinco': 25,
      'veintiseis': 26,
      'veintisiete': 27,
      'veintiocho': 28,
      'veintinueve': 29,
      'treinta': 30,
      'cuarenta': 40,
      'cincuenta': 50,
      'sesenta': 60,
      'setenta': 70,
      'ochenta': 80,
      'noventa': 90,
      'cien': 100,
      'ciento': 100,
      'doscientos': 200,
      'doscientas': 200,
      'trescientos': 300,
      'trescientas': 300,
      'cuatrocientos': 400,
      'cuatrocientas': 400,
      'quinientos': 500,
      'quinientas': 500,
      'seiscientos': 600,
      'seiscientas': 600,
      'setecientos': 700,
      'setecientas': 700,
      'ochocientos': 800,
      'ochocientas': 800,
      'novecientos': 900,
      'novecientas': 900,
    };

    final multipliers = {
      'mil': 1000.0,
      'luca': 1000.0,
      'lucas': 1000.0,
      'millon': 1000000.0,
      'millones': 1000000.0,
      'palo': 1000000.0,
      'palos': 1000000.0
    };
    text = text.replaceAll(RegExp(r'\b\d{1,4}[-/]\d{1,2}[-/]\d{1,4}\b'), ' ');
    final words = RegExp(r'-?\d+(?:[.,]\d+)*|[a-z]+')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    bool digit(String w) => RegExp(r'^-?\d').hasMatch(w);
    bool number(String w) =>
        digit(w) ||
        values.containsKey(w) ||
        multipliers.containsKey(w) ||
        w == 'medio' ||
        w == 'media';
    final candidates = <({double amount, bool money})>[];
    for (var i = 0; i < words.length;) {
      if (!number(words[i])) {
        i++;
        continue;
      }
      final start = i;
      if ((words[i] == 'un' || words[i] == 'una') &&
          (i + 1 >= words.length ||
              (!number(words[i + 1]) &&
                  words[i + 1] != 'peso' &&
                  words[i + 1] != 'pesos'))) {
        i++;
        continue;
      }
      double total = 0, segment = 0;
      double? lastMultiplier;
      while (i < words.length && (number(words[i]) || words[i] == 'y')) {
        final w = words[i];
        if (w == 'y' && (i + 1 == words.length || !number(words[i + 1]))) break;
        if (digit(w)) {
          segment += _numeric(w);
        } else if (values.containsKey(w)) {
          segment += values[w]!;
        } else if (multipliers.containsKey(w)) {
          final multiplier = multipliers[w]!;
          if (segment == 0) segment = 1;
          if (multiplier >= 1000000) {
            total += segment * multiplier;
            segment = 0;
          } else {
            segment *= multiplier;
          }
          lastMultiplier = multiplier;
        } else if ((w == 'medio' || w == 'media') && lastMultiplier != null) {
          if (lastMultiplier >= 1000000) {
            total += lastMultiplier * .5;
          } else {
            segment += lastMultiplier * .5;
          }
        }
        i++;
      }
      final amount = total + segment;
      final money =
          (i < words.length && ['peso', 'pesos', 'cop'].contains(words[i])) ||
              (start > 0 &&
                  ['por', 'gaste', 'pague', 'recibi', 'monto', 'valor', 'total']
                      .contains(words[start - 1])) ||
              words.sublist(start, i).any((w) => multipliers.containsKey(w));
      if (amount.isFinite && amount > 0) {
        candidates.add((amount: amount, money: money));
      }
    }
    final monetary = candidates.where((c) => c.money).toList();
    final selected = monetary.isNotEmpty ? monetary : candidates;
    return selected.length == 1
        ? (selected.single.amount * 100).round() / 100
        : 0;
  }

  static double _numeric(String value) {
    final separator = value.lastIndexOf(RegExp(r'[.,]'));
    if (separator < 0) return double.parse(value);
    final decimals = value.length - separator - 1;
    if (decimals == 1 || decimals == 2) {
      return double.parse(
          '${value.substring(0, separator).replaceAll(RegExp(r'[.,]'), '')}.${value.substring(separator + 1)}');
    }
    return double.parse(value.replaceAll(RegExp(r'[.,]'), ''));
  }

  static String? _extractCategory(String text, Map<String, String> dictionary) {
    final normalizedText = _normalize(text);
    for (final entry in dictionary.entries) {
      if (RegExp(r'\b' + RegExp.escape(entry.key) + r'\b')
          .hasMatch(normalizedText)) {
        return entry.value;
      }
    }
    return null;
  }
}
