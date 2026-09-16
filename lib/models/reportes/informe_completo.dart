import 'ahorros_reporte_model.dart';
import 'deudas_reporte_model.dart';
import 'distribucion_item.dart';
import 'evolucion_model.dart';
import 'fondo_emergencia_reporte_model.dart';
import 'presupuesto_reporte_model.dart';
import 'resumen_model.dart';

class InformeCompleto {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? idPeriodo;

  final ReporteResumen? resumen;
  final List<DistribucionItem>? gastosCategoria;
  final List<DistribucionItem>? gastosDependiente;
  final List<DistribucionItem>? ingresosCategoria;
  final List<DistribucionItem>? ingresosFuente;
  final List<DistribucionItem>? imprevistosCategoria;

  final ReporteAhorros? ahorros;
  final EstadoAhorros? estadoAhorros;

  final ReporteDeudas? deudas;
  final EstadoDeudas? estadoDeudas;

  final ReporteFondoEmergencia? fondoEmergencia;
  final EstadoFondoEmergencia? estadoFondoEmergencia;

  final ReporteEvolucion? evolucion;
  final ReportePresupuesto? presupuesto;

  InformeCompleto({
    this.fechaInicio,
    this.fechaFin,
    this.idPeriodo,
    this.resumen,
    this.gastosCategoria,
    this.gastosDependiente,
    this.ingresosCategoria,
    this.ingresosFuente,
    this.imprevistosCategoria,
    this.ahorros,
    this.estadoAhorros,
    this.deudas,
    this.estadoDeudas,
    this.fondoEmergencia,
    this.estadoFondoEmergencia,
    this.evolucion,
    this.presupuesto,
  });

  /// Usado por la pantalla para pintar la lista de "Información incluida"
  /// (disponible / sin datos), igual que InfoItem en la web.
  Map<String, bool> get disponibilidad => {
        'Resumen financiero': resumen != null,
        'Gastos por categoría': gastosCategoria != null,
        'Gastos por dependiente': gastosDependiente != null,
        'Ingresos por categoría': ingresosCategoria != null,
        'Ingresos por fuente': ingresosFuente != null,
        'Imprevistos por categoría': imprevistosCategoria != null,
        'Ahorros': ahorros != null,
        'Estado actual de ahorros': estadoAhorros != null,
        'Deudas': deudas != null,
        'Estado actual de deudas': estadoDeudas != null,
        'Fondo de emergencia': fondoEmergencia != null,
        'Estado actual del fondo de emergencia': estadoFondoEmergencia != null,
        'Evolución financiera': evolucion != null,
        'Presupuesto': presupuesto != null,
      };
}