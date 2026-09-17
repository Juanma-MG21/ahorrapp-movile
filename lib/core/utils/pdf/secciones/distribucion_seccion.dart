import 'package:pdf/widgets.dart' as pw;

import '../../../utils/presupuestos_parsing.dart';
import '../../../../models/reportes/distribucion_item.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaDistribucion({
  required String titulo,
  required String subtitulo,
  required int numeroPagina,
  required List<(String, List<DistribucionItem>)> bloques,
}) {
  // final formatoMoneda = NumberFormat.currency(
  //   locale: 'es_CO',
  //   symbol: r'$',
  //   decimalDigits: 0,
  // );

  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(titulo, subtitulo),
          for (final bloque in bloques) ...[
            pw.Text(
              bloque.$1,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: bloque.$2.isEmpty
                  ? pw.Text(
                      'Sin registros en este período.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: ReportePdfColors.textMuted,
                      ),
                    )
                  : tablaClay(
                      columnas: const ['Nombre', 'Total'],
                      filas: bloque.$2
                          .map((item) => [
                                item.nombre,
                                formatMonto(item.total),
                              ])
                          .toList(),
                    ),
            ),
          ],
        ],
      );
    },
  );
}