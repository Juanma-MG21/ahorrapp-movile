import 'package:pdf/widgets.dart' as pw;

import '../../../../models/reportes/informe_completo.dart';
import '../pdf_theme.dart';
import '../../../utils/presupuestos_parsing.dart';

pw.Page construirPaginaPortadaYResumen({
  required InformeCompleto informe,
  required int numeroPagina,
}) {
  // final formatoFecha = DateFormat('dd/MM/yyyy');
  // final formatoMoneda = NumberFormat.currency(
  //   locale: 'es_CO',
  //   symbol: r'$',
  //   decimalDigits: 0,
  // );

  final resumen = informe.resumen;

  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AhorrApp',
            style: pw.TextStyle(
              fontSize: 30,
              fontWeight: pw.FontWeight.bold,
              color: ReportePdfColors.accent,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Informe financiero',
            style: pw.TextStyle(
              fontSize: 21,
              color: ReportePdfColors.textPrimary,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Período: '
            '${informe.fechaInicio != null ? formatFechaCorta(informe.fechaInicio!) : '—'} '
            '— '
            '${informe.fechaFin != null ? formatFechaCorta(informe.fechaFin!) : '—'}',
            style:
                pw.TextStyle(fontSize: 11, color: ReportePdfColors.textMuted),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Generado: ${formatFechaCorta(DateTime.now())}',
            style:
                pw.TextStyle(fontSize: 11, color: ReportePdfColors.textMuted),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: ReportePdfColors.accent, thickness: 1),
          pw.SizedBox(height: 10),
          pw.Text(
            'Este informe presenta información financiera registrada en '
            'AhorrApp para el período seleccionado. Los valores son '
            'informativos y representan los registros almacenados en el '
            'sistema.',
            style:
                pw.TextStyle(fontSize: 10, color: ReportePdfColors.textMuted),
          ),
          pw.SizedBox(height: 20),
          seccionTitulo('Resumen financiero'),
          if (resumen == null)
            pw.Text(
              'No hay datos de resumen disponibles para este período.',
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportePdfColors.textMuted,
              ),
            )
          else
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                tarjetaMetrica(
                  titulo: 'Ingresos',
                  valor: formatMonto(resumen.ingresos),
                  color: ReportePdfColors.blue,
                ),
                tarjetaMetrica(
                  titulo: 'Gastos',
                  valor: formatMonto(resumen.gastos),
                  color: ReportePdfColors.accent,
                ),
                tarjetaMetrica(
                  titulo: 'Ahorros',
                  valor: formatMonto(resumen.ahorros),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Pagos a deudas',
                  valor: formatMonto(resumen.pagosDeudas),
                  color: ReportePdfColors.error,
                ),
                tarjetaMetrica(
                  titulo: 'Imprevistos',
                  valor: formatMonto(resumen.imprevistos),
                  color: ReportePdfColors.accent,
                ),
                tarjetaMetrica(
                  titulo: 'Balance',
                  valor: formatMonto(resumen.balance),
                  color: ReportePdfColors.success,
                ),
              ],
            ),
        ],
      );
    },
  );
}