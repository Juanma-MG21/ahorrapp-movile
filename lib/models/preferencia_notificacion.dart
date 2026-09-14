// lib/models/preferencia_notificacion.dart
class PreferenciaNotificacion {
  final int idUsuario;
  final String tipo;
  final bool activa;

  PreferenciaNotificacion({
    required this.idUsuario,
    required this.tipo,
    this.activa = true,
  });

  // NOTA DE ARQUITECTURA: según Santiago, este modelo se usa para llamar
  // directo a Supabase desde Flutter (no a través del backend Express
  // que usa el resto de la app vía ApiClient). Es una divergencia real
  // de cómo está construido todo lo demás — pendiente de decidir
  // cuando revisemos el servicio de notificaciones: ¿se mantiene así,
  // o se migra para que pase por el backend Express como todo lo demás?
  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'tipo': tipo,
    'activa': activa,
  };

  factory PreferenciaNotificacion.fromJson(Map<String, dynamic> json) =>
      PreferenciaNotificacion(
        idUsuario: json['id_usuario'],
        tipo: json['tipo'],
        activa: json['activa'] ?? true,
      );
}