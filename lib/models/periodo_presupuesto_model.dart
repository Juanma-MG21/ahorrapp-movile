import '../core/utils/presupuestos_parsing.dart';

/// Ejecución real de una categoría dentro del período activo.
/// Ojo: el backend solo calcula `ejecucion` para gastos, deudas,
/// imprevistos y ahorros (obtenerPeriodoActivo en el controller no
/// trackea consumo de "emergencia"), así que `ejecucion['emergencia']`
/// normalmente no existe. Para "emergencia" usa directamente
/// [PeriodoPresupuesto.montoEmergencia] como presupuestado.
class EjecucionCategoria {
  const EjecucionCategoria({
    required this.presupuestado,
    required this.ejecutado,
    required this.disponible,
  });

  final double presupuestado;
  final double ejecutado;
  final double disponible;

  factory EjecucionCategoria.fromJson(Map<String, dynamic> json) {
    return EjecucionCategoria(
      presupuestado: parseDoubleFlexible(json['presupuestado']) ?? 0,
      ejecutado: parseDoubleFlexible(json['ejecutado']) ?? 0,
      disponible: parseDoubleFlexible(json['disponible']) ?? 0,
    );
  }

  /// 0.0 - 1.0, para pintar una barra de progreso de consumo.
  double get progreso {
    if (presupuestado <= 0) return 0;
    final p = ejecutado / presupuestado;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }
}

/// Un período de presupuesto (tabla `periodos_presupuesto`), enriquecido
/// con `Perfil_nombre` / `Dia_corte` (vienen del JOIN con `presupuestos`)
/// y `ejecucion` (calculado en el backend, solo en /periodos/activo).
///
/// Nota: las respuestas de abrirPeriodo / cerrarPeriodo / ajustarIngreso
/// devuelven solo un subconjunto de estos campos. El
/// [PresupuestoProvider] siempre vuelve a pedir /periodos/activo después
/// de cualquiera de esas acciones en vez de intentar reconstruir el
/// modelo completo a partir de esas respuestas parciales.
class PeriodoPresupuesto {
  PeriodoPresupuesto({
    required this.idPeriodo,
    this.idPresupuesto,
    this.perfilNombre,
    this.diaCorte,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.ingresoEstimado,
    required this.ingresoReal,
    required this.saldoAnterior,
    required this.montoGastos,
    required this.montoDeudas,
    required this.montoImprevistos,
    required this.montoAhorros,
    required this.montoEmergencia,
    this.ejecucion,
  });

  final int idPeriodo;
  final int? idPresupuesto;
  final String? perfilNombre;
  final int? diaCorte;
  final String estado; // 'abierto' | 'cerrado'
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double ingresoEstimado;
  final double ingresoReal;
  final double saldoAnterior;
  final double montoGastos;
  final double montoDeudas;
  final double montoImprevistos;
  final double montoAhorros;
  final double montoEmergencia;
  final Map<String, EjecucionCategoria>? ejecucion;

  bool get abierto => estado == 'abierto';

  double get totalDistribuido =>
      montoGastos + montoDeudas + montoImprevistos + montoAhorros + montoEmergencia;

  /// Porcentaje (0-100) de una categoría sobre el total distribuido,
  /// usado para la sección "Ver resumen" del mockup.
  double porcentajeDe(double monto) {
    if (totalDistribuido <= 0) return 0;
    return (monto / totalDistribuido) * 100;
  }

  factory PeriodoPresupuesto.fromJson(Map<String, dynamic> json) {
    Map<String, EjecucionCategoria>? ejecucionMap;
    final rawEjecucion = json['ejecucion'];
    if (rawEjecucion is Map) {
      ejecucionMap = rawEjecucion.map(
        (key, value) => MapEntry(
          key.toString(),
          EjecucionCategoria.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    }

    return PeriodoPresupuesto(
      idPeriodo: parseIntFlexible(json['ID_periodo']) ?? 0,
      idPresupuesto: parseIntFlexible(json['ID_presupuesto']),
      perfilNombre: json['Perfil_nombre'] as String?,
      diaCorte: parseIntFlexible(json['Dia_corte']),
      estado: json['Estado'] as String? ?? 'abierto',
      fechaInicio: parseDateFlexible(json['Fecha_inicio']),
      fechaFin: parseDateFlexible(json['Fecha_fin']),
      ingresoEstimado: parseDoubleFlexible(json['Ingreso_estimado']) ?? 0,
      ingresoReal: parseDoubleFlexible(json['Ingreso_real']) ?? 0,
      saldoAnterior: parseDoubleFlexible(json['Saldo_anterior']) ?? 0,
      montoGastos: parseDoubleFlexible(json['Monto_gastos']) ?? 0,
      montoDeudas: parseDoubleFlexible(json['Monto_deudas']) ?? 0,
      montoImprevistos: parseDoubleFlexible(json['Monto_imprevistos']) ?? 0,
      montoAhorros: parseDoubleFlexible(json['Monto_ahorros']) ?? 0,
      montoEmergencia: parseDoubleFlexible(json['Monto_emergencia']) ?? 0,
      ejecucion: ejecucionMap,
    );
  }
}