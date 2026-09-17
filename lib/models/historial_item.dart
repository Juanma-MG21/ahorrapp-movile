/// Item del historial de acciones del sistema (GET /historial),
/// visible únicamente en el Panel de administración.
class HistorialItem {
  HistorialItem({
    required this.id,
    required this.usuarioNombre,
    required this.usuarioApellido,
    required this.accion,
    required this.detalles,
    required this.fecha,
  });

  final int id;
  final String usuarioNombre;
  final String? usuarioApellido;
  final String accion;
  final String? detalles;
  final DateTime? fecha;

  factory HistorialItem.fromJson(Map<String, dynamic> json) {
    DateTime? fecha;
    final fechaRaw = json['fecha']?.toString();
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      fecha = DateTime.tryParse(fechaRaw);
    }

    return HistorialItem(
      id: json['id_historial'] is int
          ? json['id_historial'] as int
          : int.tryParse('${json['id_historial']}') ?? 0,
      usuarioNombre: json['usuario_nombre']?.toString() ?? 'Usuario',
      usuarioApellido: json['usuario_apellido']?.toString(),
      accion: json['accion']?.toString() ?? '',
      detalles: json['detalles']?.toString(),
      fecha: fecha,
    );
  }
}
