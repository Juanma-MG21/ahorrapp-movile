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
    final categoria = _extractCategory(cleanText, _keywordsToGastoCategory, 'Otros');
    
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
    final categoria = _extractCategory(cleanText, _keywordsToIngresoCategory, 'Otros');
    
    return IngresoModel(
      monto: monto,
      fechaRegistro: DateTime.now(),
      descripcion: text,
      categoriaNombre: categoria,
      fuente: categoria == 'Salario' ? 'Nómina' : 'Otros',
    );
  }

  static double _extractAmount(String text) {
    text = text.replaceAllMapped(RegExp(r'(\d+)\.(\d{3})'), (Match m) => '${m[1]}${m[2]}');
    text = text.replaceAll(',', '');

    final rawWords = text.toLowerCase().split(RegExp(r'[\s]+'));
    final words = rawWords.map((w) => w.replaceAll(RegExp(r'[^\w\d]'), '')).toList();
    
    double grandTotal = 0;
    double currentSegment = 0;

    final Map<String, double> values = {
      'cero': 0, 'un': 1, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
      'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10,
      'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
      'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
      'veinte': 20, 'veintiuno': 21, 'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25,
      'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
      'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90,
      'cien': 100, 'ciento': 100, 'doscientos': 200, 'doscientas': 200,
      'trescientos': 300, 'trescientas': 300, 'cuatrocientos': 400, 'cuatrocientas': 400,
      'quinientos': 500, 'quinientas': 500, 'seiscientos': 600, 'seiscientas': 600,
      'setecientos': 700, 'setecientas': 700, 'ochocientos': 800, 'ochocientas': 800,
      'novecientos': 900, 'novecientas': 900,
    };

    final multipliers = {
      'mil': 1000.0, 'luca': 1000.0, 'lucas': 1000.0,
      'millon': 1000000.0, 'millones': 1000000.0, 'palo': 1000000.0, 'palos': 1000000.0,
    };

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isEmpty) continue;

      if (RegExp(r'^\d+$').hasMatch(word)) {
        currentSegment += double.parse(word);
        continue;
      }

      if (values.containsKey(word)) {
        if (word == 'un' || word == 'una') {
          bool isNumber = false;
          if (i > 0) {
            String prev = words[i-1];
            if (prev == 'y' || prev.endsWith('cientos') || prev == 'ciento' || prev == 'cien') {
              isNumber = true;
            }
          }
          if (i + 1 < words.length) {
            String next = words[i+1];
            if (multipliers.containsKey(next)) isNumber = true;
          }
          if (words.length == 1) isNumber = true;
          if (currentSegment == 0 && grandTotal == 0) isNumber = true;
          if (i > 0 && (values.containsKey(words[i-1]) || multipliers.containsKey(words[i-1]))) isNumber = true;
          if (!isNumber) continue;
        }
        currentSegment += values[word]!;
        continue;
      }

      if (multipliers.containsKey(word)) {
        double m = multipliers[word]!;
        if (currentSegment == 0) currentSegment = 1;
        if (m >= 1000000) {
          grandTotal += currentSegment * m;
          currentSegment = 0;
        } else {
          currentSegment *= m;
          grandTotal += currentSegment;
          currentSegment = 0;
        }
        continue;
      }

      if (word == 'medio' || word == 'media') {
        if (i > 0) {
          String prev = words[i - 1] == 'y' && i > 1 ? words[i - 2] : words[i - 1];
          if (multipliers.containsKey(prev)) {
            grandTotal += multipliers[prev]! * 0.5;
          } else {
            currentSegment += 0.5;
          }
        }
        continue;
      }
    }

    return grandTotal + currentSegment;
  }

  static String _extractCategory(String text, Map<String, String> dictionary, String fallback) {
    final normalizedText = _normalize(text);
    for (var entry in dictionary.entries) {
      if (normalizedText.contains(entry.key)) {
        return entry.value;
      }
    }
    return fallback;
  }
}
