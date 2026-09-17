import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/reportes/informe_completo.dart';
import 'secciones/ahorros_seccion.dart';
import 'secciones/deudas_seccion.dart';
import 'secciones/distribucion_seccion.dart';
import 'secciones/evolucion_seccion.dart';
import 'secciones/fondo_emergencia_seccion.dart';
import 'secciones/portada_y_resumen_seccion.dart';
import 'secciones/presupuesto_seccion.dart';

/// Arma el PDF del informe financiero y lo entrega vía el paquete
/// `printing` (el usuario elige si lo guarda, comparte o imprime).
///
/// El orden de páginas replica el de la web: portada + resumen,
/// ingresos, gastos, ahorros, deudas, imprevistos, fondo de
/// emergencia, presupuesto y evolución. Cada sección se salta sola si
/// no hay datos para ella.
class ReportePdfBuilder {
  const ReportePdfBuilder._();

  static Future<void> generarYCompartir(InformeCompleto informe) async {
    final doc = pw.Document();

    int numeroPagina = 1;

    doc.addPage(
      construirPaginaPortadaYResumen(
        informe: informe,
        numeroPagina: numeroPagina,
      ),
    );

    if (informe.ingresosCategoria != null ||
        informe.ingresosFuente != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaDistribucion(
          titulo: 'Ingresos',
          subtitulo: 'Distribución de ingresos por categoría y fuente',
          numeroPagina: numeroPagina,
          bloques: [
            if (informe.ingresosCategoria != null)
              ('Por categoría', informe.ingresosCategoria!),
            if (informe.ingresosFuente != null)
              ('Por fuente', informe.ingresosFuente!),
          ],
        ),
      );
    }

    if (informe.gastosCategoria != null ||
        informe.gastosDependiente != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaDistribucion(
          titulo: 'Gastos',
          subtitulo: 'Distribución de gastos por categoría y dependiente',
          numeroPagina: numeroPagina,
          bloques: [
            if (informe.gastosCategoria != null)
              ('Por categoría', informe.gastosCategoria!),
            if (informe.gastosDependiente != null)
              ('Por dependiente', informe.gastosDependiente!),
          ],
        ),
      );
    }

    if (informe.ahorros != null || informe.estadoAhorros != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaAhorros(
          historial: informe.ahorros,
          estado: informe.estadoAhorros,
          numeroPagina: numeroPagina,
        ),
      );
    }

    if (informe.deudas != null || informe.estadoDeudas != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaDeudas(
          historial: informe.deudas,
          estado: informe.estadoDeudas,
          numeroPagina: numeroPagina,
        ),
      );
    }

    if (informe.imprevistosCategoria != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaDistribucion(
          titulo: 'Imprevistos',
          subtitulo: 'Distribución de imprevistos por categoría',
          numeroPagina: numeroPagina,
          bloques: [
            ('Por categoría', informe.imprevistosCategoria!),
          ],
        ),
      );
    }

    if (informe.fondoEmergencia != null ||
        informe.estadoFondoEmergencia != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaFondoEmergencia(
          historial: informe.fondoEmergencia,
          estado: informe.estadoFondoEmergencia,
          numeroPagina: numeroPagina,
        ),
      );
    }

    if (informe.presupuesto != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaPresupuesto(
          presupuesto: informe.presupuesto,
          numeroPagina: numeroPagina,
        ),
      );
    }

    if (informe.evolucion != null) {
      numeroPagina++;
      doc.addPage(
        construirPaginaEvolucion(
          evolucion: informe.evolucion,
          numeroPagina: numeroPagina,
        ),
      );
    }

    final bytes = await doc.save();
    final fechaArchivo = DateTime.now().toIso8601String().substring(0, 10);

    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'AhorrApp_Informe_Financiero_$fechaArchivo.pdf',
    );
  }
}