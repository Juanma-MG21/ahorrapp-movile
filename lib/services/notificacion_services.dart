// lib/services/notificacion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notificaciones.dart';
import '../models/preferencia_notificacion.dart';
import '../models/enums.dart';

class NotificacionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableNotificaciones = 'notificaciones';
  static const String _tablePreferencias = 'preferencias_notificacion';

  // ==================== NOTIFICACIONES ====================

  // Obtener todas las notificaciones de un usuario
  Future<List<Notificacion>> getNotificaciones(int idUsuario) async {
    try {
      final response = await _supabase
          .from(_tableNotificaciones)
          .select('*')
          .eq('id_usuario', idUsuario)
          .eq('archivada', false)
          .order('fecha', ascending: false);

      return response.map((json) => Notificacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  // Obtener notificaciones no leídas de un usuario
  Future<List<Notificacion>> getNotificacionesNoLeidas(int idUsuario) async {
    try {
      final response = await _supabase
          .from(_tableNotificaciones)
          .select('*')
          .eq('id_usuario', idUsuario)
          .eq('leida', false)
          .eq('archivada', false)
          .order('fecha', ascending: false);

      return response.map((json) => Notificacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones no leídas: $e');
    }
  }

  // Obtener notificaciones por tipo
  Future<List<Notificacion>> getNotificacionesByTipo(
    int idUsuario,
    TipoNotificacion tipo,
  ) async {
    try {
      final response = await _supabase
          .from(_tableNotificaciones)
          .select('*')
          .eq('id_usuario', idUsuario)
          .eq('tipo', tipo.value)
          .eq('archivada', false)
          .order('fecha', ascending: false);

      return response.map((json) => Notificacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones por tipo: $e');
    }
  }

  // Crear una nueva notificación
  Future<Notificacion> crearNotificacion(Notificacion notificacion) async {
    try {
      final response = await _supabase
          .from(_tableNotificaciones)
          .insert(notificacion.toJson())
          .select()
          .single();

      return Notificacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(int idNotificacion) async {
    try {
      await _supabase
          .from(_tableNotificaciones)
          .update({'leida': true})
          .eq('id_notificacion', idNotificacion);
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas(int idUsuario) async {
    try {
      await _supabase
          .from(_tableNotificaciones)
          .update({'leida': true})
          .eq('id_usuario', idUsuario)
          .eq('leida', false);
    } catch (e) {
      throw Exception('Error al marcar todas como leídas: $e');
    }
  }

  // Archivar una notificación
  Future<void> archivarNotificacion(int idNotificacion) async {
    try {
      await _supabase
          .from(_tableNotificaciones)
          .update({'archivada': true})
          .eq('id_notificacion', idNotificacion);
    } catch (e) {
      throw Exception('Error al archivar notificación: $e');
    }
  }

  // Eliminar una notificación
  Future<void> eliminarNotificacion(int idNotificacion) async {
    try {
      await _supabase
          .from(_tableNotificaciones)
          .delete()
          .eq('id_notificacion', idNotificacion);
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> contarNoLeidas(int idUsuario) async {
    try {
      final response = await _supabase
          .from(_tableNotificaciones)
          .select('*', count: CountOption.exact)
          .eq('id_usuario', idUsuario)
          .eq('leida', false)
          .eq('archivada', false);

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Error al contar notificaciones no leídas: $e');
    }
  }

  // ==================== PREFERENCIAS ====================

  // Obtener preferencias de un usuario
  Future<List<PreferenciaNotificacion>> getPreferencias(int idUsuario) async {
    try {
      final response = await _supabase
          .from(_tablePreferencias)
          .select('*')
          .eq('id_usuario', idUsuario);

      return response.map((json) => PreferenciaNotificacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener preferencias: $e');
    }
  }

  // Actualizar preferencia
  Future<void> actualizarPreferencia(
    int idUsuario,
    TipoNotificacion tipo,
    bool activa,
  ) async {
    try {
      await _supabase
          .from(_tablePreferencias)
          .upsert({
            'id_usuario': idUsuario,
            'tipo': tipo.value,
            'activa': activa,
          });
    } catch (e) {
      throw Exception('Error al actualizar preferencia: $e');
    }
  }

  // Verificar si un tipo de notificación está activo
  Future<bool> isTipoActivo(int idUsuario, TipoNotificacion tipo) async {
    try {
      final response = await _supabase
          .from(_tablePreferencias)
          .select('activa')
          .eq('id_usuario', idUsuario)
          .eq('tipo', tipo.value)
          .maybeSingle();

      if (response == null) return true; // Por defecto activo
      return response['activa'] ?? true;
    } catch (e) {
      return true; // Por defecto activo en caso de error
    }
  }
}