// lib/models/preferencia_notificacion.dart
//PRUEBA
class PreferenciaNotificacion {
  final int idUsuario;
  final String tipo;
  final bool activa;

  PreferenciaNotificacion({
    required this.idUsuario,
    required this.tipo,
    this.activa = true,
  });

  // Convertir a JSON para enviar a Supabase
  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'tipo': tipo,
    'activa': activa,
  };

  // Convertir desde JSON (respuesta de Supabase)
  factory PreferenciaNotificacion.fromJson(Map<String, dynamic> json) => PreferenciaNotificacion(
    idUsuario: json['id_usuario'],
    tipo: json['tipo'],
    activa: json['activa'] ?? true,
  );
}