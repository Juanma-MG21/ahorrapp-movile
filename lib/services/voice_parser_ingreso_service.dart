import '../models/ingreso_model.dart';

class VoiceParserIngresoService {
  static final Map<String, String> _mapeoCategorias = {
    // SALARIO / HONORARIOS
    'salario': 'Salario', 'sueldo': 'Salario', 'nomina': 'Salario', 'pago': 'Salario',
    'honorarios': 'Honorarios', 'trabajo': 'Salario', 'quincena': 'Salario', 'mesada': 'Salario',

    // VENTAS
    'venta': 'Venta', 'vendi': 'Venta', 'vendido': 'Venta', 'negocio': 'Venta',

    // REGALOS
    'regalo': 'Regalo', 'obsequio': 'Regalo', 'donacion': 'Regalo',

    // INVERSIONES
    'inversion': 'Inversión', 'rendimientos': 'Inversión', 'ganancia': 'Inversión',
    'dividendos': 'Inversión', 'intereses': 'Inversión',

    // OTROS
    'reembolso': 'Reembolso', 'devolucion': 'Reembolso', 'arriendo': 'Arriendo',
    'bono': 'Bonificación', 'premio': 'Bonificación',
  };

  static final Map<String, double> _mapeoNumeros = {
    'un': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, 'seis': 6,
    'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11, 'doce': 12,
    'trece': 13, 'catorce': 14, 'quince': 15, 'dieciseis': 16, 'diecisiete': 17,
    'dieciocho': 18, 'diecinueve': 19, 'veinte': 20, 'veintiun': 21, 'veintidos': 22,
    'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25, 'veintiseis': 26,
    'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29, 'treinta': 30,
    'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60, 'setenta': 70, 'ochenta': 80,
    'noventa': 90, 'cien': 100, 'ciento': 100, 'doscientos': 200, 'trescientos': 300,
    'cuatrocientos': 400, 'quinientos': 500, 'seiscientos': 600, 'setecientos': 700,
    'ochocientos': 800, 'novecientos': 900,
  };

  static final Set<String> _ruido = {
    'me', 'mi', 'mis', 'recibi', 'recibí', 'gano', 'gané', 'entro', 'entró',
    'ingreso', 'ingresó', 'tengo', 'tuve', 'que', 'un', 'una', 'el', 'la',
    'los', 'las', 'de', 'del', 'por', 'en', 'con', 'y', 'a', 'valor', 'monto',
    'precio', 'pesos', 'luca', 'lucas', 'barra', 'barras', 'palo', 'palos',
    'mil', 'millon', 'millones', 'fueron', 'valieron', 'quedo'
  };

  static String _quitarAcentos(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');
  }

  static IngresoModel parse(String text) {
    String normalizedText = text.replaceAll('\$', '').replaceAll(',', '');
    final textNorm = _quitarAcentos(normalizedText);

    double monto = _extractAmount(textNorm);
    String categoria = 'Otros';
    for (var entry in _mapeoCategorias.entries) {
      if (textNorm.contains(entry.key)) {
        categoria = entry.value;
        break;
      }
    }

    final originalWords = normalizedText.split(RegExp(r'\s+'));
    List<String> cleanWords = [];

    for (var word in originalWords) {
      String wordNorm = _quitarAcentos(word).replaceAll(RegExp(r'[^\w]'), '');
      if (!_ruido.contains(wordNorm) &&
          !_mapeoNumeros.containsKey(wordNorm) &&
          !RegExp(r'^\d+$').hasMatch(wordNorm) &&
          wordNorm.isNotEmpty) {
        cleanWords.add(word);
      }
    }

    String descriptionFinal = cleanWords.join(' ').trim();
    if (descriptionFinal.isEmpty || descriptionFinal.length < 2) {
      descriptionFinal = (categoria != 'Otros') ? categoria : 'Ingreso manual';
    }

    if (descriptionFinal.isNotEmpty) {
      descriptionFinal = descriptionFinal[0].toUpperCase() + descriptionFinal.substring(1);
    }

    return IngresoModel(
      descripcion: descriptionFinal,
      monto: monto,
      fechaRegistro: DateTime.now(),
      categoriaNombre: categoria,
      fuente: categoria == 'Salario' ? 'Nómina' : 'Ingreso extra',
    );
  }

  static double _extractAmount(String text) {
    String t = text
        .replaceAll('mil', ' mil ')
        .replaceAll('lucas', ' mil ')
        .replaceAll('barras', ' mil ')
        .replaceAll('millon', ' millon ')
        .replaceAll('millones', ' millon ')
        .replaceAll('palos', ' millon ')
        .replaceAll(' y ', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final palabras = t.split(' ');
    double totalGlobal = 0;
    double acumuladoParcial = 0;

    for (var p in palabras) {
      final digitMatch = RegExp(r'^\d+([.,]\d+)?$').firstMatch(p);
      if (digitMatch != null) {
        acumuladoParcial += double.tryParse(digitMatch.group(0)!.replaceAll(',', '.')) ?? 0;
        continue;
      }
      if (_mapeoNumeros.containsKey(p)) {
        acumuladoParcial += _mapeoNumeros[p]!;
        continue;
      }
      if (p == 'mil') {
        if (acumuladoParcial == 0) acumuladoParcial = 1;
        totalGlobal += (acumuladoParcial * 1000);
        acumuladoParcial = 0;
      } else if (p == 'millon') {
        if (acumuladoParcial == 0) acumuladoParcial = 1;
        totalGlobal += (acumuladoParcial * 1000000);
        acumuladoParcial = 0;
      }
    }
    return totalGlobal + acumuladoParcial;
  }
}