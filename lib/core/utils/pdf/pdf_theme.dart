import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Traducción de los tokens de diseño de la app (design_tokens.dart) al
/// mundo del PDF: mismos colores hexadecimales que AppColors, para que
/// el informe se sienta una extensión de la app y no un documento aparte.
class ReportePdfColors {
  const ReportePdfColors._();

  static const background = PdfColor.fromInt(0xFF0E1124);
  static const surface = PdfColor.fromInt(0xFF141730);
  static const surfaceAlt = PdfColor.fromInt(0xFF1E2230);
  static const inset = PdfColor.fromInt(0xFF080A15);

  static const accent = PdfColor.fromInt(0xFFFFB800);

  static const success = PdfColor.fromInt(0xFF34D399);
  static const error = PdfColor.fromInt(0xFFFF6B6B);
  static const blue = PdfColor.fromInt(0xFF2F8BFF);

  static const textPrimary = PdfColors.white;
  static const textSecondary = PdfColor.fromInt(0xFF7A7D95);
  static const textMuted = PdfColor.fromInt(0xFF5B5F70);

  static const borderLight = PdfColor.fromInt(0x14FFFFFF);
}

const double _mm = PdfPageFormat.mm;

/// Arma una página A4 con el fondo oscuro de la app, el contenido dado
/// y el pie de página con el número. Todas las secciones pasan por aquí
/// para que se vean consistentes entre sí.
pw.Page construirPagina({
  required int numeroPagina,
  required pw.Widget Function(pw.Context) contenido,
}) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (context) {
      return pw.Container(
        width: double.infinity,
        height: double.infinity,
        color: ReportePdfColors.background,
        padding: const pw.EdgeInsets.fromLTRB(
          14 * _mm,
          18 * _mm,
          14 * _mm,
          18 * _mm,
        ),
        child: pw.Column(
          children: [
            pw.Expanded(child: contenido(context)),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'AhorrApp · Informe financiero · Página $numeroPagina',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: ReportePdfColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Título de sección con subtítulo opcional. Equivalente a
/// "tituloSeccion" en la versión web.
pw.Widget seccionTitulo(String titulo, [String? subtitulo]) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 17,
            fontWeight: pw.FontWeight.bold,
            color: ReportePdfColors.accent,
          ),
        ),
        if (subtitulo != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            subtitulo,
            style: pw.TextStyle(
              fontSize: 8.5,
              color: ReportePdfColors.textMuted,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Tarjeta de métrica: panel + borde de color + etiqueta + valor.
/// Equivalente a "tarjeta()" en la versión web.
pw.Widget tarjetaMetrica({
  required String titulo,
  required String valor,
  PdfColor color = ReportePdfColors.accent,
}) {
  return pw.Container(
    width: 130,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: ReportePdfColors.surface,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      border: pw.Border.all(color: color, width: 0.8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo.toUpperCase(),
          style: pw.TextStyle(fontSize: 7, color: ReportePdfColors.textMuted),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: ReportePdfColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

/// Tabla con encabezado resaltado y filas alternadas ("zebra"), igual
/// que "tabla()" en la versión web.
pw.Widget tablaClay({
  required List<String> columnas,
  required List<List<String>> filas,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      border: pw.Border.all(color: ReportePdfColors.borderLight),
    ),
    child: pw.TableHelper.fromTextArray(
      headers: columnas,
      data: filas,
      border: null,
      headerDecoration: const pw.BoxDecoration(
        color: ReportePdfColors.surfaceAlt,
      ),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: ReportePdfColors.textPrimary,
      ),
      cellStyle: pw.TextStyle(
        fontSize: 7,
        color: ReportePdfColors.textSecondary,
        
      ),
      oddRowDecoration: const pw.BoxDecoration(
        color: ReportePdfColors.inset,
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    ),
  );
}