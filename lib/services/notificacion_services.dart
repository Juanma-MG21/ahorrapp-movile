import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notificaciones.dart';

class NotificacionesServices {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'notificaciones';

  Future<List<Notificacion>> getNotificaciones(int idUsuario) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('id_usuario', idUsuario)
          .order('fecha', ascending: false);

      return response.map((json) => Notificacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  Future<void> marcarComoLeida(int idNotificacion) async {
    try {
      await _supabase
          .from(_table)
          .update({'leida': true})
          .eq('id_notificacion', idNotificacion);
    } catch (e) {
      throw Exception('Error al marcar como leída: $e');
    }
  }

  // Otros métodos que tengas...
}