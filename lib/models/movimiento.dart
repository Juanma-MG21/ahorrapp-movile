import 'package:flutter/material.dart';

/// Info visual (color, icono, etiqueta) para cada tipo de movimiento.
/// Refleja los mismos tipos que ya existen en el backend / web
/// (subtipo_modulo_enum: Ahorro, Ingreso, Gasto, Deuda, Imprevisto).
class TipoMovimientoInfo {
  const TipoMovimientoInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.esEntrada,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool esEntrada; // true = suma (verde), false = resta
}

const Map<String, TipoMovimientoInfo> kTiposMovimiento = {
  'ahorro': TipoMovimientoInfo(
    label: 'Ahorro',
    color: Color(0xFFE0B855),
    icon: Icons.savings_outlined,
    esEntrada: true,
  ),
  'ingreso': TipoMovimientoInfo(
    label: 'Ingreso',
    color: Color(0xFF97C459),
    icon: Icons.arrow_downward_rounded,
    esEntrada: true,
  ),
  'gasto': TipoMovimientoInfo(
    label: 'Gasto',
    color: Color(0xFF85B7EB),
    icon: Icons.shopping_bag_outlined,
    esEntrada: false,
  ),
  'deuda': TipoMovimientoInfo(
    label: 'Deuda',
    color: Color(0xFFE24B4A),
    icon: Icons.credit_card,
    esEntrada: false,
  ),
  'imprevisto': TipoMovimientoInfo(
    label: 'Imprevisto',
    color: Color(0xFFE8935B),
    icon: Icons.bolt_outlined,
    esEntrada: false,
  ),
};

const TipoMovimientoInfo kTipoMovimientoDefault = TipoMovimientoInfo(
  label: 'Movimiento',
  color: Color(0xFF9AA6C4),
  icon: Icons.swap_horiz,
  esEntrada: true,
);

/// Representa una fila del historial de "Mis movimientos".
/// El backend (GET /movimientos) devuelve un arreglo mezclando
/// ahorros, ingresos, gastos, deudas e imprevistos; cada uno trae al
/// menos: tipo, monto, fecha y descripcion/causa según el caso.
class Movimiento {
  Movimiento({
    required this.tipoKey,
    required this.monto,
    required this.fecha,
    this.descripcion,
  });

  final String tipoKey; // 'ahorro' | 'ingreso' | 'gasto' | 'deuda' | 'imprevisto' | otro
  final double monto;
  final DateTime? fecha;
  final String? descripcion;

  TipoMovimientoInfo get info => kTiposMovimiento[tipoKey] ?? kTipoMovimientoDefault;

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    final tipoRaw = (json['tipo'] ?? json['tipo_movimiento'] ?? '').toString();
    final montoRaw = json['monto'];
    double monto;
    if (montoRaw is num) {
      monto = montoRaw.toDouble();
    } else {
      monto = double.tryParse(montoRaw?.toString() ?? '') ?? 0;
    }

    DateTime? fecha;
    final fechaRaw = json['fecha']?.toString();
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      fecha = DateTime.tryParse(fechaRaw);
    }

    final descripcion = (json['descripcion'] ?? json['causa'])?.toString();

    return Movimiento(
      tipoKey: tipoRaw.toLowerCase(),
      monto: monto,
      fecha: fecha,
      descripcion: (descripcion == null || descripcion.trim().isEmpty)
          ? null
          : descripcion.trim(),
    );
  }
}
