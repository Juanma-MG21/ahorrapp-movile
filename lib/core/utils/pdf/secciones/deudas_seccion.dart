import 'package:pdf/widgets.dart' as pw;


import '../../../../models/reportes/deudas_reporte_model.dart';
import '../../../../core/utils/presupuestos_parsing.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaDeudas({
  required ReporteDeudas? historial,
  required EstadoDeudas? estado,
  required int numeroPagina,
}) {
  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(
            'Deudas',
            'Abonos del período y estado actual de las deudas',
          ),
          if (historial == null && estado == null)
            pw.Text(
              'No hay información de deudas disponible.',
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
                  titulo: 'Deudas activas',
                  valor: '${estado.cantidadDeudas}',
                  color: ReportePdfColors.error,
                ),
                tarjetaMetrica(
                  titulo: 'Monto total',
                  valor: formatMonto(estado.montoTotal),
                  color: ReportePdfColors.error,
                ),
                tarjetaMetrica(
                  titulo: 'Pagado',
                  valor: formatMonto(estado.montoPagado),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Pendiente',
                  valor: formatMonto(estado.montoPendiente),
                  color: ReportePdfColors.error,
                ),
                tarjetaMetrica(
                  titulo: '% pagado',
                  valor: '${estado.porcentajePagado.toStringAsFixed(1)}%',
                  color: ReportePdfColors.success,
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          if (historial != null) ...[
            pw.Text(
              'Abonos en el período '
              '(total pagado: ${formatMonto(historial.totalPagado)}, '
              'cuotas pagadas: ${historial.cuotasPagadas})',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            historial.datos.isEmpty
                ? pw.Text(
                    'Sin abonos en este período.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: ReportePdfColors.textMuted,
                    ),
                  )
                : tablaClay(
                    columnas: const [
                      'Fecha',
                      'Fuente',
                      'Descripción',
                      'Cuotas',
                      'Monto',
                    ],
                    filas: historial.datos
                        .map((a) => [
                              a.fechaRegistro != null
                                  ? formatFechaCorta(a.fechaRegistro!)
                                  : '—',
                              a.fuente ?? '—',
                              a.descripcion ?? '—',
                              '${a.cuotas}',
                              formatMonto(a.monto),
                            ])
                        .toList(),
                  ),
            pw.SizedBox(height: 12),
          ],
          if (estado != null && estado.datos.isNotEmpty) ...[
            pw.Text(
              'Estado de las deudas',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            tablaClay(
              columnas: const [
                'Fuente',
                'Total',
                'Pagado',
                'Pendiente',
                '% pagado',
                'Estado',
              ],
              filas: estado.datos
                  .map((d) => [
                        d.fuente ?? '—',
                        formatMonto(d.montoTotal),
                        formatMonto(d.montoPagado),
                        formatMonto(d.montoPendiente),
                        '${d.porcentajePagado.toStringAsFixed(1)}%',
                        d.estado ?? '—',
                      ])
                  .toList(),
            ),
          ],
        ],
      );
    },
  );
}