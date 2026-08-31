import '../models/gasto_model.dart';

class VoiceParserService {
  static final Map<String, String> _mapeoCategorias = {
    // ALIMENTACIÓN
    'hamburguesa': 'Alimentación', 'empanada': 'Alimentación', 'tinto': 'Alimentación',
    'corrientazo': 'Alimentación', 'comida': 'Alimentación', 'almuerzo': 'Alimentación',
    'restaurante': 'Alimentación', 'arepa': 'Alimentación', 'perro': 'Alimentación',
    'pizza': 'Alimentación', 'salchipapa': 'Alimentación', 'mecato': 'Alimentación',
    'desayuno': 'Alimentación', 'cena': 'Alimentación', 'café': 'Alimentación',
    'comi': 'Alimentación', 'comiendo': 'Alimentación',

    // ROPA
    'ropa': 'Ropa', 'pinta': 'Ropa', 'camisa': 'Ropa', 'camiseta': 'Ropa',
    'pantalón': 'Ropa', 'pantalon': 'Ropa', 'tenis': 'Ropa', 'zapatos': 'Ropa',
    'chaqueta': 'Ropa', 'vestido': 'Ropa', 'medias': 'Ropa',

    // HOGAR
    'arriendo': 'Hogar', 'casa': 'Hogar', 'mercado': 'Hogar', 'luz': 'Hogar',
    'agua': 'Hogar', 'gas': 'Hogar', 'internet': 'Hogar', 'aseo': 'Hogar',

    // TRANSPORTE
    'transporte': 'Transporte', 'bus': 'Transporte', 'taxi': 'Transporte',
    'uber': 'Transporte', 'pasaje': 'Transporte', 'gasolina': 'Transporte',
    'moto': 'Transporte', 'transmi': 'Transporte', 'sitp': 'Transporte',

    // SALUD
    'salud': 'Salud', 'médico': 'Salud', 'medico': 'Salud', 'droga': 'Salud',
    'farmacia': 'Salud', 'remedio': 'Salud', 'consulta': 'Salud',

    // ENTRETENIMIENTO
    'cine': 'Entretenimiento', 'rumba': 'Entretenimiento', 'farra': 'Entretenimiento',
    'polas': 'Entretenimiento', 'fiesta': 'Entretenimiento', 'cerveza': 'Entretenimiento',
    'viaje': 'Entretenimiento',
  };

  static final Map<String, double> _mapeoNumeros = {
    // Unidades
    'un': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, 'seis': 6,
    'siete': 7, 'ocho': 8, 'nueve': 9,
    // Especiales 11-19
    'diez': 10, 'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15,
    'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
    // Decenas
    'veinte': 20, 'veintiun': 21, 'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24,
    'veinticinco': 25, 'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29,
    'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, 'sesenta': 60, 'setenta': 70,
    'ochenta': 80, 'noventa': 90,
    // Centenas
    'cien': 100, 'ciento': 100, 'doscientos': 200, 'trescientos': 300,
    'cuatrocientos': 400, 'quinientos': 500, 'seiscientos': 600,
    'setecientos': 700, 'ochocientos': 800, 'novecientos': 900,
  };

  static final Set<String> _ruido = {
    'me', 'mi', 'mis', 'compre', 'compré', 'compro', 'pague', 'pagué', 'pago',
    'costo', 'costó', 'valio', 'valió', 'vale', 'gaste', 'gasté', 'gasto',
    'que', 'un', 'una', 'el', 'la', 'los', 'las', 'de', 'del', 'por', 'en',
    'con', 'y', 'a', 'valor', 'monto', 'precio', 'pesos', 'luca', 'lucas',
    'barra', 'barras', 'palo', 'palos', 'mil', 'millon', 'millones', 'fueron',
    'valieron', 'quedo'
  };

  static String _quitarAcentos(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');
  }

  static GastoModel parse(String text) {
    // Limpieza agresiva de símbolos antes de procesar
    String normalizedText = text.replaceAll('\$', '').replaceAll(',', '');

    final textNorm = _quitarAcentos(normalizedText);

    // 1. Extraer Monto
    double monto = _extractAmount(textNorm);

    // 2. Extraer Categoría (solo el NOMBRE - el formulario intenta
    // encontrar el id real haciendo match contra las categorías
    // reales del backend; si no encuentra, el usuario la elige a mano)
    String categoria = 'General';
    for (var entry in _mapeoCategorias.entries) {
      if (textNorm.contains(entry.key)) {
        categoria = entry.value;
        break;
      }
    }

    // 3. Limpiar Descripción
    final originalWords = normalizedText.split(RegExp(r'\s+'));
    List<String> cleanWords = [];

    for (var word in originalWords) {
      String wordNorm = _quitarAcentos(word).replaceAll(RegExp(r'[^\w]'), '');

      // Si la palabra es parte de un monto numérico o escrito, o es ruido, se descarta
      if (!_ruido.contains(wordNorm) &&
          !_mapeoNumeros.containsKey(wordNorm) &&
          !RegExp(r'^\d+$').hasMatch(wordNorm) &&
          wordNorm.isNotEmpty) {
        cleanWords.add(word);
      }
    }

    String descriptionFinal = cleanWords.join(' ').trim();

    // Si la descripción quedó vacía o solo contiene ruido, usamos el nombre de la categoría
    if (descriptionFinal.isEmpty || descriptionFinal.length < 2) {
      descriptionFinal = (categoria != 'General') ? categoria : 'Gasto manual';
    }

    // Capitalizar
    if (descriptionFinal.isNotEmpty) {
      descriptionFinal = descriptionFinal[0].toUpperCase() + descriptionFinal.substring(1);
    }

    return GastoModel(
      descripcion: descriptionFinal,
      monto: monto,
      fecha: DateTime.now(),
      categoriaNombre: categoria,
    );
  }

  static double _extractAmount(String text) {
    // Normalizar para que números y palabras estén bien separados
    // IMPORTANTE: Manejar "diezmil" -> "diez mil"
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
      // 1. Intentar como dígito puro
      final digitMatch = RegExp(r'^\d+([.,]\d+)?$').firstMatch(p);
      if (digitMatch != null) {
        acumuladoParcial += double.tryParse(digitMatch.group(0)!.replaceAll(',', '.')) ?? 0;
        continue;
      }

      // 2. Intentar como palabra numérica
      if (_mapeoNumeros.containsKey(p)) {
        acumuladoParcial += _mapeoNumeros[p]!;
        continue;
      }

      // 3. Manejar multiplicadores
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