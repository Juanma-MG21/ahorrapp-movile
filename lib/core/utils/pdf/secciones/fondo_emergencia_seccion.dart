import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/presupuestos_parsing.dart';
import '../../../../models/reportes/fondo_emergencia_reporte_model.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaFondoEmergencia({
  required ReporteFondoEmergencia? historial,
  required EstadoFondoEmergencia? estado,
  required int numeroPagina,
}) {
  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(
            'Fondo de emergencia',
            'Movimientos del período y estado actual',
          ),
          if (historial == null && estado == null)
            pw.Text(
              'El usuario no tiene un fondo de emergencia creado, o no '
              'hubo movimientos en este período.',
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportePdfColors.textMuted,
              ),
            ),
          if (historial != null) ...[
            pw.Text(
              'Movimientos en el período',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                tarjetaMetrica(
                  titulo: 'Aportes',
                  valor: formatMonto(historial.aportes),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Retiros',
                  valor: formatMonto(historial.retiros),
                  color: ReportePdfColors.error,
                ),
                tarjetaMetrica(
                  titulo: 'Movimiento neto',
                  valor: formatMonto(historial.movimientoNeto),
                  color: ReportePdfColors.blue,
                ),
                tarjetaMetrica(
                  titulo: 'Meta',
                  valor: formatMonto(historial.meta),
                  color: ReportePdfColors.accent,
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          if (estado != null) ...[
            pw.Text(
              'Estado actual',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: ReportePdfColors.textPrimary,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                tarjetaMetrica(
                  titulo: 'Saldo actual',
                  valor: formatMonto(estado.saldoActual),
                  color: ReportePdfColors.success,
                ),
                tarjetaMetrica(
                  titulo: 'Meta',
                  valor: formatMonto(estado.meta),
                  color: ReportePdfColors.accent,
                ),
                tarjetaMetrica(
                  titulo: '% de la meta',
                  valor: '${estado.porcentajeMeta.toStringAsFixed(1)}%',
                  color: ReportePdfColors.success,
                ),
              ],
            ),
          ],
        ],
      );
    },
  );
}