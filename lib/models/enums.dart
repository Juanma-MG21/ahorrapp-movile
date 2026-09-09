// Prueba


// lib/models/enums.dart
enum TipoNotificacion {
  sistema,
  recordatorio,
  sugerencia,
  alerta,
  presupuesto,
}

extension TipoNotificacionExtension on TipoNotificacion {
  String get value {
    switch (this) {
      case TipoNotificacion.sistema:
        return 'sistema';
      case TipoNotificacion.recordatorio:
        return 'recordatorio';
      case TipoNotificacion.sugerencia:
        return 'sugerencia';
      case TipoNotificacion.alerta:
        return 'alerta';
      case TipoNotificacion.presupuesto:
        return 'presupuesto';
    }
  }
}