import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/presupuestos_parsing.dart';
import '../../../../models/reportes/ahorros_reporte_model.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaAhorros({
  required ReporteAhorros? historial,
  required EstadoAhorros? estado,
  required int numeroPagina,
}) {
  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(
            'Ahorros',
            'Movimientos del período y estado actual de las metas',
          ),
          if (historial == null && estado == null)
            pw.Text(
              'No hay información de ahorros disponible.',
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportePdfColors.textMuted,
              ),
            ),
          if (estado != null) ...[
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                tarjetaMetrica(
                  titulo: 'Metas activas',
                  valor: '${estado.cantidadMetas}',
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Meta total',
                  valor: formatMonto(estado.metaTotal),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Acumulado total',
                  valor: formatMonto(estado.acumuladoTotal),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: '% cumplimiento',
                  valor: '${estado.porcentajeCumplimiento.toStringAsFixed(1)}%',
                  color: ReportePdfColors.success,
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          if (historial != null) ...[
            pw.Text(
              'Movimientos en el período '
              '(total ahorrado: ${formatMonto(historial.totalAhorrado)})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            historial.datos.isEmpty
                ? pw.Text(
                    'Sin movimientos en este período.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: ReportePdfColors.textMuted,
                    ),
                  )
                : tablaClay(
                    columnas: const [
                      'Fecha',
                      'Descripción',
                      'Monto',
                      'Acumulado',
                    ],
                    filas: historial.datos
                        .map((a) => [
                              a.fechaRegistro != null
                                  ? formatFechaCorta(a.fechaRegistro!)
                                  : '—',
                              a.descripcion ?? '—',
                              formatMonto(a.monto),
                              formatMonto(a.montoAcumulado),
                            ])
                        .toList(),
                  ),
            pw.SizedBox(height: 12),
          ],
          if (estado != null && estado.datos.isNotEmpty) ...[
            pw.Text(
              'Estado de las metas',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            tablaClay(
              columnas: const [
                'Descripción',
                'Meta',
                'Acumulado',
                '% cumplido',
              ],
              filas: estado.datos
                  .map((m) => [
                        m.descripcion ?? '—',
                        formatMonto(m.meta),
                        formatMonto(m.montoAcumulado),
                        '${m.porcentajeCumplimiento.toStringAsFixed(1)}%',
                      ])
                  .toList(),
            ),
          ],
        ],
      );
    },
  );
}