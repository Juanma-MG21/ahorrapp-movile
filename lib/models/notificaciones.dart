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

  Notificacion({
    this.idNotificacion,
    required this.idUsuario,
    required this.tipo,
    required this.entidadTipo,
    this.entidadId,
    required this.mensaje,
    required this.fecha,
    this.leida = false,
    this.archivada = false,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['id_notificacion'],
      idUsuario: json['id_usuario'],
      tipo: json['tipo'],
      entidadTipo: json['entidad_tipo'],
      entidadId: json['entidad_id'],
      mensaje: json['mensaje'],
      fecha: DateTime.parse(json['fecha']),
      leida: json['leida'] ?? false,
      archivada: json['archivada'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'tipo': tipo,
      'entidad_tipo': entidadTipo,
      'entidad_id': entidadId,
      'mensaje': mensaje,
      'fecha': fecha.toIso8601String(),
      'leida': leida,
      'archivada': archivada,
    };
  }

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