// notificacion_panel.dart (o donde tengas este código)
import 'package:flutter/material.dart';
import '../models/notificaciones.dart';
import '../services/notificacion_services.dart';

// Los Tokens deberías tenerlos en tu tema, pero los dejamos como estaban
// import 'theme/tokens.dart'; // si existe

// Función que abre el panel (recibe el idUsuario)
void showNotifPanel(BuildContext context, int idUsuario) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return NotificacionPanel(idUsuario: idUsuario);
    },
  );
}

// Widget Stateful para manejar los datos
class NotificacionPanel extends StatefulWidget {
  final int idUsuario;
  const NotificacionPanel({super.key, required this.idUsuario});

  @override
  State<NotificacionPanel> createState() => _NotificacionPanelState();
}

class _NotificacionPanelState extends State<NotificacionPanel> {
  final NotificacionService _service = NotificacionService();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  // Carga notificaciones desde Supabase
  Future<void> _cargarNotificaciones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getNotificaciones(widget.idUsuario);
      setState(() {
        _notificaciones = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Puedes mostrar un snackbar o un widget de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Marcar como leída
  Future<void> _marcarComoLeida(int id) async {
    try {
      await _service.marcarComoLeida(id);
      // Actualizar la lista localmente sin recargar todo
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.idNotificacion == id);
        if (index != -1) {
          _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
        }
      });
    } catch (e) {
      // Manejar error
    }
  }

  // Eliminar notificación
  Future<void> _eliminarNotificacion(int id) async {
    try {
      await _service.eliminarNotificacion(id);
      setState(() {
        _notificaciones.removeWhere((n) => n.idNotificacion == id);
      });
    } catch (e) {
      // Manejar error
    }
  }

  // Mapeo de tipo a icono y color
  Map<String, Map<String, dynamic>> get _tipoConfig => {
        'ingreso': {'icono': '💰', 'color': Colors.green},
        'egreso': {'icono': '💸', 'color': Colors.red},
        'limite': {'icono': '⚠️', 'color': Colors.orange},
        'meta': {'icono': '🎯', 'color': Colors.purple},
        'recordatorio': {'icono': '🔔', 'color': Colors.blue},
        'sistema': {'icono': '📢', 'color': Colors.grey},
      };

  // Formateo de fecha
  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()} sem.';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Reemplazamos Tokens por valores directos o colores de tu tema
    final colorAmber = Colors.amber; // o Tokens.amber
    final colorTextSecondary = Colors.grey[400]!; // o Tokens.textSecondary
    final colorTextPrimary = Colors.white; // o Tokens.textPrimary
    final colorTextMuted = Colors.grey[600]!; // o Tokens.textMuted

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xF20f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔔 Notificaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorAmber,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: colorTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                : _notificaciones.isEmpty
                    ? Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(color: colorTextMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notif = _notificaciones[index];
                          final config = _tipoConfig[notif.tipo] ??
                              {'icono': '📌', 'color': Colors.grey};

                          return GestureDetector(
                            onTap: () {
                              if (!notif.leida) {
                                _marcarComoLeida(notif.idNotificacion!);
                              }
                            },
                            onLongPress: () {
                              // Eliminar con presión larga
                              _eliminarNotificacion(notif.idNotificacion!);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: notif.leida
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.amber.withOpacity(0.1),
                                border: Border.all(
                                  color: notif.leida
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.amber.withOpacity(0.3),
                                ),
                                borderRadius:
                                    BorderRadius.circular(8), // antes Tokens.radiusSm
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    config['icono'] as String,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  if (!notif.leida)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      margin: const EdgeInsets
                                                          .only(right: 6),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.amber,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  Text(
                                                    notif.tipo.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: notif.leida
                                                          ? colorTextSecondary
                                                          : (config['color']
                                                              as Color),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatFecha(notif.fecha),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif.mensaje,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notif.leida
                                                ? colorTextSecondary
                                                : colorTextPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (notif.entidadTipo.isNotEmpty &&
                                            notif.entidadId != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${notif.entidadTipo}: #${notif.entidadId}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorTextMuted,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}