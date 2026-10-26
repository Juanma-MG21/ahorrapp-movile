import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../models/movimiento.dart';
import 'seccion_card.dart';

/// Fila compacta de un movimiento (ahorro/ingreso/gasto/deuda/imprevisto),
/// inspirada en el historial de "cajitas" de Nu: icono redondo de color
/// por tipo, descripción truncada a una línea, y el monto con signo
/// +/- alineado a la derecha. Pensada para verse bien tanto en la
/// vista compacta (Mi cuenta) como en la lista completa.
class MovimientoTile extends StatelessWidget {
  const MovimientoTile({super.key, required this.movimiento});

  final Movimiento movimiento;

  String _formatearMonto(double monto) {
    // Formato simple con separador de miles tipo es-CO, sin depender
    // del paquete intl (por si el proyecto no lo tiene agregado).
    final entero = monto.round();
    final texto = entero.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      final posDesdeElFinal = texto.length - i;
      buffer.write(texto[i]);
      if (posDesdeElFinal > 1 && posDesdeElFinal % 3 == 1) {
        buffer.write('.');
      }
    }
    return '\$${buffer.toString()}';
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    final hoy = DateTime.now();
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final ayer = hoy.subtract(const Duration(days: 1));
    final esAyer = fecha.year == ayer.year && fecha.month == ayer.month && fecha.day == ayer.day;

    if (esHoy) return 'Hoy';
    if (esAyer) return 'Ayer';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final info = movimiento.info;
    final signo = info.esEntrada ? '+' : '-';
    final colorMonto = info.esEntrada ? AppColors.success : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: info.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.descripcion ?? info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${info.label} · ${_formatearFecha(movimiento.fecha)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$signo${_formatearMonto(movimiento.monto)}',
            style: TextStyle(
              color: colorMonto,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
