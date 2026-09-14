// lib/services/ocr_parser_service.dart
//
// Parser de texto reconocido por OCR sobre una foto de recibo/factura
// (RF-23). Tiene lógica propia, distinta de QrParserService, porque el
// texto que devuelve un motor de OCR es multilínea y ruidoso (varias
// líneas con precios unitarios, cantidades, NIT, etc.), a diferencia
// del payload limpio y de una sola pieza que suele traer un QR:
//
//   - Monto: se prioriza la línea que contiene una palabra clave de
//     total ("TOTAL", "VALOR A PAGAR"...) y se extrae el número DE ESA
//     línea — no "el número más grande de todo el texto", porque en un
//     recibo con varios ítems el número más grande casi nunca es el
//     total real (puede ser una cantidad, un NIT, un código de barras).
//   - Fecha: no existía en QrParserService. Se busca con regex de
//     fecha (dd/mm/yyyy, dd-mm-yyyy, yyyy-mm-dd) en todo el texto.
//   - Comercio/descripción: se toma la primera línea "con contenido"
//     (letras suficientes, no solo números/símbolos) — en un recibo el
//     nombre del comercio casi siempre va en las primeras líneas.
//
// Misma filosofía de autollenado que QR y voz: nunca fija idCategoria
// (solo el nombre, que el formulario intenta matchear), y parse()
// devuelve NULL cuando no se pudo extraer un monto válido, para que
// quien llama le avise al usuario en vez de abrir el formulario vacío.

import '../models/gasto_model.dart';
import '../data/categoria_keywords.dart';

class OcrParserService {
  static final List<String> _palabrasClaveMonto = [
    'total', 'valor', 'pagar', 'monto', 'importe',
  ];

  static final RegExp _regexNumero = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d{4,}');

  static String _quitarAcentos(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');
  }

  static GastoModel? parse(String textoOcr) {
    final lineas = textoOcr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lineas.isEmpty) return null;

    final textoCompleto = lineas.join(' ');
    final textoNorm = _quitarAcentos(textoCompleto);

    final double monto = _extraerMonto(lineas);
    // Sin un monto válido, no hay nada aprovechable del recibo.
    if (monto <= 0) return null;

    final DateTime fecha = _extraerFecha(textoCompleto) ?? DateTime.now();

    String categoria = 'General';
    for (var entry in mapeoCategoriasKeywords.entries) {
      if (textoNorm.contains(entry.key)) {
        categoria = entry.value;
        break;
      }
    }

    final String comercio = _extraerComercio(lineas);

    return GastoModel(
      descripcion: comercio,
      monto: monto,
      fecha: fecha,
      categoriaNombre: categoria,
    );
  }

  /// 1) Busca la línea que contenga una palabra clave de total y extrae
  ///    el número DE ESA línea.
  /// 2) Si ninguna línea tiene palabra clave, cae al número más grande
  ///    de todo el texto (mismo fallback que QrParserService).
  static double _extraerMonto(List<String> lineas) {
    for (final linea in lineas) {
      final lineaNorm = _quitarAcentos(linea);
      final tieneClave = _palabrasClaveMonto.any((clave) => lineaNorm.contains(clave));
      if (!tieneClave) continue;

      final match = _regexNumero.firstMatch(linea);
      if (match != null) {
        final valor = _limpiarNumero(match.group(0)!);
        if (valor > 0) return valor;
      }
    }

    // Fallback: el número más grande de todo el texto.
    final matches = _regexNumero.allMatches(lineas.join(' ')).toList();
    if (matches.isEmpty) return 0;

    double mejor = 0;
    for (final m in matches) {
      final valor = _limpiarNumero(m.group(0)!);
      if (valor > mejor) mejor = valor;
    }
    return mejor;
  }

  static double _limpiarNumero(String numeroCrudo) {
    final soloDigitos = numeroCrudo.replaceAll(RegExp(r'[^\d]'), '');
    if (soloDigitos.isEmpty) return 0;
    return double.tryParse(soloDigitos) ?? 0;
  }

  /// Busca una fecha en formato dd/mm/yyyy, dd-mm-yyyy o yyyy-mm-dd.
  /// Descarta coincidencias con mes/día fuera de rango para no
  /// confundir un número cualquiera del recibo con una fecha.
  static DateTime? _extraerFecha(String texto) {
    final regexDiaMesAnio = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})');
    final matchDMA = regexDiaMesAnio.firstMatch(texto);
    if (matchDMA != null) {
      final dia = int.tryParse(matchDMA.group(1)!);
      final mes = int.tryParse(matchDMA.group(2)!);
      final anio = int.tryParse(matchDMA.group(3)!);
      if (dia != null && mes != null && anio != null && mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
        try {
          return DateTime(anio, mes, dia);
        } catch (_) {}
      }
    }

    final regexAnioMesDia = RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})');
    final matchAMD = regexAnioMesDia.firstMatch(texto);
    if (matchAMD != null) {
      final anio = int.tryParse(matchAMD.group(1)!);
      final mes = int.tryParse(matchAMD.group(2)!);
      final dia = int.tryParse(matchAMD.group(3)!);
      if (dia != null && mes != null && anio != null && mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
        try {
          return DateTime(anio, mes, dia);
        } catch (_) {}
      }
    }

    return null;
  }

  /// Primera línea con suficiente contenido textual (no solo números,
  /// símbolos o códigos de barras) — normalmente el nombre del comercio
  /// va en las primeras líneas del recibo.
  static String _extraerComercio(List<String> lineas) {
    for (final linea in lineas) {
      final soloLetras = linea.replaceAll(RegExp(r'[\d\W]'), '');
      if (soloLetras.length >= 3) {
        final recortada = linea.length > 80 ? linea.substring(0, 80) : linea;
        return recortada[0].toUpperCase() + recortada.substring(1);
      }
    }
    return 'Registro por recibo';
  }
}