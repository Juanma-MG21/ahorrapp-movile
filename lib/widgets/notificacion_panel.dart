import 'package:flutter/material.dart';
import '../models/notificaciones.dart';
import '../services/notificacion_services.dart';

void showNotifPanel(BuildContext context, int idUsuario) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => NotificacionPanel(idUsuario: idUsuario),
  );
}

class NotificacionPanel extends StatefulWidget {
  final int idUsuario;
  const NotificacionPanel({super.key, required this.idUsuario});

  @override
  State<NotificacionPanel> createState() => _NotificacionPanelState();
}

class _NotificacionPanelState extends State<NotificacionPanel> {
  final NotificacionesServices _service = NotificacionesServices();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notificaciones: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _marcarComoLeida(int id) async {
    try {
      await _service.marcarComoLeida(id);
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
    final Map<String, String> tipoIcono = {
      'sistema': '📢',
      'recordatorio': '🔔',
      'sugerencia': '💡',
      'alerta': '⚠️',
      'presupuesto': '💰',
    };

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔔 Notificaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _notificaciones.isEmpty
                    ? const Center(child: Text('No hay notificaciones', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notif = _notificaciones[index];
                          final icono = tipoIcono[notif.tipo] ?? '📌';

                          return GestureDetector(
                            onTap: () {
                              if (!notif.leida) {
                                _marcarComoLeida(notif.idNotificacion!);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: notif.leida
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.amber.withOpacity(0.1),
                                border: Border.all(
                                  color: notif.leida
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.amber.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(icono, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  if (!notif.leida)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      margin: const EdgeInsets.only(right: 6),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.amber,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  Text(
                                                    notif.tipo.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: notif.leida ? Colors.grey[400] : Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatFecha(notif.fecha),
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif.mensaje,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notif.leida ? Colors.grey[500] : Colors.white,
                                            height: 1.4,
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