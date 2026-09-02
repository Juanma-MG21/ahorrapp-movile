// lib/services/qr_parser_service.dart
//
// Hermano de VoiceParserService, pero para texto que viene de un QR
// (recibo/comprobante) en vez de dictado por voz. La diferencia clave:
// un recibo trae el monto en DÍGITOS ("TOTAL $45.000"), no en palabras
// ("cuarenta y cinco mil"), así que la extracción de monto usa regex
// sobre números en vez del diccionario de palabras que usa el de voz.
//
// Misma filosofía que el de voz: solo prellena lo que puede inferir con
// confianza (monto, descripción, y el NOMBRE de categoría). NO fija
// idCategoria — no hay forma de saber el id real desde el texto del QR;
// el formulario intenta encontrar la categoría real por nombre, y si no
// hay match, el usuario la confirma a mano.

import '../models/gasto_model.dart';

class QrParserService {
  // Palabras clave típicas de un recibo/comprobante, mapeadas a la
  // categoría correspondiente. Se puede ampliar libremente.
  static final Map<String, String> _mapeoCategorias = {
    // Alimentación
    'supermercado': 'Alimentación', 'super': 'Alimentación', 'mercado': 'Alimentación',
    'restaurante': 'Alimentación', 'panaderia': 'Alimentación', 'panadería': 'Alimentación',
    'cafeteria': 'Alimentación', 'cafetería': 'Alimentación', 'domicilios': 'Alimentación',
    'rappi': 'Alimentación', 'ara': 'Alimentación', 'exito': 'Alimentación', 'éxito': 'Alimentación',
    'd1': 'Alimentación', 'justo y bueno': 'Alimentación', 'olimpica': 'Alimentación',

    // Ropa
    'almacen': 'Ropa', 'almacén': 'Ropa', 'boutique': 'Ropa', 'calzado': 'Ropa',
    'zara': 'Ropa', 'falabella': 'Ropa',

    // Hogar
    'arriendo': 'Hogar', 'administracion': 'Hogar', 'administración': 'Hogar',
    'ferreteria': 'Hogar', 'ferretería': 'Hogar', 'homecenter': 'Hogar',
    'acueducto': 'Hogar', 'energia': 'Hogar', 'energía': 'Hogar', 'gas natural': 'Hogar',

    // Transporte
    'combustible': 'Transporte', 'gasolina': 'Transporte', 'estacion de servicio': 'Transporte',
    'estación de servicio': 'Transporte', 'peaje': 'Transporte', 'parqueadero': 'Transporte',
    'taxi': 'Transporte', 'uber': 'Transporte', 'terminal': 'Transporte',

    // Salud
    'farmacia': 'Salud', 'droguer': 'Salud', 'clinica': 'Salud', 'clínica': 'Salud',
    'hospital': 'Salud', 'eps': 'Salud', 'laboratorio': 'Salud',

    // Entretenimiento
    'cine': 'Entretenimiento', 'cinemark': 'Entretenimiento', 'cinepolis': 'Entretenimiento',
    'netflix': 'Entretenimiento', 'spotify': 'Entretenimiento', 'teatro': 'Entretenimiento',
  };

  // Palabras que suelen anteceder al monto real (el "total a pagar")
  // en un recibo. Si aparecen, se prioriza el número que sigue.
  static final List<String> _palabrasClaveMonto = [
    'total', 'valor', 'monto', 'pagar', 'pago', 'importe',
  ];

  static String _quitarAcentos(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');
  }

  static GastoModel parse(String textoQr) {
    final textoLimpio = textoQr.trim();
    final textoNorm = _quitarAcentos(textoLimpio);

    // 1. Extraer monto
    final resultadoMonto = _extractAmount(textoLimpio, textoNorm);
    final double monto = resultadoMonto.valor;

    // 2. Detectar categoría por palabra clave (solo el NOMBRE)
    String categoria = 'General';
    for (var entry in _mapeoCategorias.entries) {
      if (textoNorm.contains(entry.key)) {
        categoria = entry.value;
        break;
      }
    }

    // 3. Armar descripción: el texto original, quitando el fragmento
    // de monto que ya identificamos (si lo encontramos), colapsando
    // espacios y saltos de línea sobrantes (los QR de recibos suelen
    // traer \n entre líneas).
    String descripcion = textoLimpio;
    if (resultadoMonto.textoOriginalEncontrado != null) {
      descripcion = descripcion.replaceFirst(resultadoMonto.textoOriginalEncontrado!, '');
    }
    descripcion = descripcion
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Límite razonable para no meter un QR gigante entero en el campo
    if (descripcion.length > 140) {
      descripcion = '${descripcion.substring(0, 140)}...';
    }

    if (descripcion.isEmpty) {
      descripcion = (categoria != 'General') ? categoria : 'Registro por QR';
    } else {
      descripcion = descripcion[0].toUpperCase() + descripcion.substring(1);
    }

    return GastoModel(
      descripcion: descripcion,
      monto: monto,
      fecha: DateTime.now(),
      categoriaNombre: categoria,
    );
  }

  /// Busca un monto en el texto. Estrategia, en orden de prioridad:
  /// 1) Un número que aparezca justo después de una palabra clave
  ///    como "total" o "valor".
  /// 2) Si no hay palabra clave, el número más grande de 4+ dígitos
  ///    encontrado (para no confundir un monto con una fecha o una
  ///    cantidad pequeña, ej: "2 unidades").
  static _ResultadoMonto _extractAmount(String textoOriginal, String textoNorm) {
    // Captura números tipo 45.000 / 45,000 / 1.500.000 / 45000
    final regexNumero = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d{4,}');

    // --- Intento 1: número después de una palabra clave de monto ---
    for (final clave in _palabrasClaveMonto) {
      final regexClave = RegExp('$clave' r'[:\s]*([\d.,]{4,})', caseSensitive: false);
      final match = regexClave.firstMatch(textoNorm);
      if (match != null && match.group(1) != null) {
        final numeroCrudo = match.group(1)!;
        final valor = _limpiarNumero(numeroCrudo);
        if (valor > 0) {
          return _ResultadoMonto(valor, numeroCrudo);
        }
      }
    }

    // --- Intento 2: el número más grande encontrado en todo el texto ---
    final matches = regexNumero.allMatches(textoOriginal).toList();
    if (matches.isEmpty) return _ResultadoMonto(0, null);

    String mejorCrudo = matches.first.group(0)!;
    double mejorValor = _limpiarNumero(mejorCrudo);

    for (final m in matches) {
      final crudo = m.group(0)!;
      final valor = _limpiarNumero(crudo);
      if (valor > mejorValor) {
        mejorValor = valor;
        mejorCrudo = crudo;
      }
    }

    return _ResultadoMonto(mejorValor, mejorCrudo);
  }

  /// Convierte "45.000", "45,000" o "45000" a 45000.0 — para montos en
  /// pesos colombianos asumimos que no hay decimales relevantes, así
  /// que simplemente se descartan los separadores y se toma el entero.
  static double _limpiarNumero(String numeroCrudo) {
    final soloDigitos = numeroCrudo.replaceAll(RegExp(r'[^\d]'), '');
    if (soloDigitos.isEmpty) return 0;
    return double.tryParse(soloDigitos) ?? 0;
  }
}

/// Pequeño contenedor interno para devolver junto el valor numérico Y
/// el texto crudo que lo originó (así _extractAmount lo puede quitar
/// de la descripción sin tener que volver a buscarlo).
class _ResultadoMonto {
  final double valor;
  final String? textoOriginalEncontrado;
  _ResultadoMonto(this.valor, this.textoOriginalEncontrado);
}