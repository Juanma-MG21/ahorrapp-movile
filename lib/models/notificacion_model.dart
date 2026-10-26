import 'package:flutter/material.dart';

class NotificacionModel {
  final int id;
  final String tipo;
  final String mensaje;
  final DateTime fecha;
  final bool leida;

  const NotificacionModel({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.fecha,
    required this.leida,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: int.parse(json['id'].toString()),
      tipo: json['tipo']?.toString() ?? 'sistema',
      mensaje: json['mensaje']?.toString() ?? '',
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      leida: json['leida'] == true,
    );
  }

  NotificacionModel copyWith({bool? leida}) {
    return NotificacionModel(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      fecha: fecha,
      leida: leida ?? this.leida,
    );
  }

  IconData get icono {
    switch (tipo) {
      case 'recordatorio':
        return Icons.alarm_rounded;
      case 'sugerencia':
        return Icons.lightbulb_outline_rounded;
      case 'alerta_presupuesto':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (tipo) {
      case 'recordatorio':
        return const Color(0xFF60A5FA);
      case 'sugerencia':
        return const Color(0xFF4ADE80);
      case 'alerta_presupuesto':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF9AA6C4);
    }
  }
}