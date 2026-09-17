import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/presupuestos_parsing.dart';
import '../../../../models/reportes/presupuesto_reporte_model.dart';
import '../pdf_theme.dart';

pw.Page construirPaginaPresupuesto({
  required ReportePresupuesto? presupuesto,
  required int numeroPagina,
}) {
  return construirPagina(
    numeroPagina: numeroPagina,
    contenido: (context) {
      if (presupuesto == null) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            seccionTitulo('Presupuesto'),
            pw.Text(
              'No se seleccionó un presupuesto, o no se encontró '
              'información para el período elegido.',
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportePdfColors.textMuted,
              ),
            ),
          ],
        );
      }

      final categorias = <(String, CategoriaPresupuesto)>[
        ('Gastos', presupuesto.gastos),
        ('Deudas', presupuesto.deudas),
        ('Imprevistos', presupuesto.imprevistos),
        ('Ahorros', presupuesto.ahorros),
        ('Emergencia', presupuesto.emergencia),
      ];

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          seccionTitulo(
            presupuesto.nombrePresupuesto ?? 'Presupuesto',
            (presupuesto.fechaInicio != null && presupuesto.fechaFin != null)
                ? '${formatFechaCorta(presupuesto.fechaInicio!)} → '
                    '${formatFechaCorta(presupuesto.fechaFin!)}'
                : null,
          ),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              tarjetaMetrica(
                titulo: 'Ingreso estimado',
                valor: formatMonto(presupuesto.ingresoEstimado),
                color: ReportePdfColors.blue,
              ),
              tarjetaMetrica(
                titulo: 'Ingreso real',
                valor: formatMonto(presupuesto.ingresoReal),
                color: ReportePdfColors.blue,
              ),
              tarjetaMetrica(
                titulo: 'Saldo disponible',
                valor: formatMonto(presupuesto.saldoDisponible),
                color: ReportePdfColors.success,
              ),
              tarjetaMetrica(
                titulo: 'Total ejecutado',
                valor: formatMonto(presupuesto.totalEjecutado),
                color: ReportePdfColors.accent,
              ),
              tarjetaMetrica(
                titulo: '% ejecución',
                valor: '${presupuesto.porcentajeEjecucion.toStringAsFixed(1)}%',
                color: ReportePdfColors.accent,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Ejecución por categoría',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: ReportePdfColors.textPrimary,
            ),
          ),
          pw.SizedBox(height: 4),
          tablaClay(
            columnas: const [
              'Categoría',
              'Planeado',
              'Ejecutado',
              'Diferencia',
              '% usado',
            ],
            filas: categorias
                .map((c) => [
                      c.$1,
                      formatMonto(c.$2.planeado),
                      formatMonto(c.$2.ejecutado),
                      formatMonto(c.$2.diferencia),
                      '${c.$2.porcentajeUsado.toStringAsFixed(1)}%',
                    ])
                .toList(),
          ),
        ],
      );
    },
  );
}