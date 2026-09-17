import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/presupuestos_parsing.dart';
import '../../../../models/reportes/evolucion_model.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaEvolucion({
  required ReporteEvolucion? evolucion,
  required int numeroPagina,
}) {
  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(
            'Evolución financiera',
            'Balance diario en el período',
          ),
          if (evolucion == null || evolucion.datos.isEmpty)
            pw.Text(
              'No hay datos de evolución disponibles para este período.',
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportePdfColors.textMuted,
              ),
            )
          else
            tablaClay(
              columnas: const [
                'Fecha',
                'Ingresos',
                'Gastos',
                'Balance',
                'Balance acum.',
              ],
              filas: evolucion.datos
                  .map((p) => [
                        p.fecha != null ? formatFechaCorta(p.fecha!) : '—',
                        formatMonto(p.ingresos),
                        formatMonto(p.gastos),
                        formatMonto(p.balance),
                        formatMonto(p.balanceAcumulado),
                      ])
                  .toList(),
            ),
        ],
      );
    },
  );
}