/// Fondo de emergencia del usuario. A diferencia de las metas de Ahorro
/// (que pueden ser varias), el usuario tiene UN solo fondo de
/// emergencia, acumulativo, con su propia tabla en el backend
/// (fondos_emergencia + movimientos_fondo_emergencia), no la tabla
/// genérica `movimientos`.
class FondoEmergenciaModel {
  final int idFondo;
  final int idUsuario;
  final double meta;
  final double saldoActual;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  FondoEmergenciaModel({
    required this.idFondo,
    required this.idUsuario,
    required this.meta,
    this.saldoActual = 0.0,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory FondoEmergenciaModel.fromJson(Map<String, dynamic> json) {
    return FondoEmergenciaModel(
      idFondo: json['id_fondo'] as int,
      idUsuario: json['id_usuario'] as int,
      meta: double.tryParse(json['meta'].toString()) ?? 0.0,
      saldoActual: double.tryParse((json['saldo_actual'] ?? 0).toString()) ?? 0.0,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'].toString())
          : null,
    );
  }

  double get progreso => meta > 0 ? (saldoActual / meta).clamp(0.0, 1.0) : 0.0;

  double get restante => (meta - saldoActual).clamp(0.0, double.infinity);
}

/// Movimiento del fondo de emergencia (aporte o retiro), tal como lo
/// devuelve GET /fondo-emergencia/movimientos.
class MovimientoEmergenciaModel {
  final int idMovimiento;
  final int idFondo;
  final String tipo; // 'aporte' | 'retiro'
  final double monto;
  final DateTime? fechaRegistro;
  final String? descripcion;

  MovimientoEmergenciaModel({
    required this.idMovimiento,
    required this.idFondo,
    required this.tipo,
    required this.monto,
    this.fechaRegistro,
    this.descripcion,
  });

  bool get esAporte => tipo == 'aporte';

  factory MovimientoEmergenciaModel.fromJson(Map<String, dynamic> json) {
    return MovimientoEmergenciaModel(
      idMovimiento: json['id_movimiento_fondo'] as int,
      idFondo: json['id_fondo'] as int,
      tipo: json['tipo'] as String? ?? 'aporte',
      monto: double.tryParse(json['monto'].toString()) ?? 0.0,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString())
          : null,
      descripcion: json['descripcion'] as String?,
    );
  }
}
