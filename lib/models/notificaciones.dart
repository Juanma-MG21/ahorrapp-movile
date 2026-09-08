// lib/models/notificacion.dart
class Notificacion {
  final int? idNotificacion;
  final int idUsuario;
  final String tipo;
  final String entidadTipo;
  final int? entidadId;
  final String mensaje;
  final DateTime fecha;
  final bool leida;
  final bool archivada;

  Notificacion copyWith({
    int? idNotificacion,
    int? idUsuario,
    String? tipo,
    String? entidadTipo,
    int? entidadId,
    String? mensaje,
    DateTime? fecha,
    bool? leida,
    bool? archivada,
  }) {
    return Notificacion(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      idUsuario: idUsuario ?? this.idUsuario,
      tipo: tipo ?? this.tipo,
      entidadTipo: entidadTipo ?? this.entidadTipo,
      entidadId: entidadId ?? this.entidadId,
      mensaje: mensaje ?? this.mensaje,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      archivada: archivada ?? this.archivada,
    );
  }
}
