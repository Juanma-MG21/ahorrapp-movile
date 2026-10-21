import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';
import '../services/session_logout.dart';

class OfflineSyncPanel extends StatelessWidget {
  const OfflineSyncPanel({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<SyncStatus>(
        valueListenable: OfflineSyncService.instance.status,
        builder: (context, status, _) {
          final connection = switch (status.connection) {
            'online' => 'Servidor disponible',
            'offline' => 'Sin conexión',
            'session' => 'Sesión vencida',
            'server' => 'Servidor no disponible',
            _ => 'Conexión por comprobar',
          };
          final last = status.lastSuccess?.toLocal();
          final lastText = last == null
              ? 'Sin sincronización previa'
              : 'Última: ${last.day}/${last.month}/${last.year} ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
          return SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                '$connection · ${status.pending} pendientes\n$lastText',
                                style: const TextStyle(fontSize: 11))),
                        TextButton(
                            onPressed: status.sending
                                ? null
                                : () => OfflineSyncService.instance
                                    .sync(force: true),
                            child: Text(
                                status.sending ? 'Enviando…' : 'Sincronizar')),
                      ]),
                      if (status.message != null || status.errors > 0)
                        Text(
                            status.message ??
                                '${status.errors} registros requieren corrección con conexión.',
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 11)),
                      if (status.pending > 0)
                        const Text(
                            'Las listas incluyen pendientes. Los reportes solo incluyen registros sincronizados.',
                            style:
                                TextStyle(fontSize: 11, color: Colors.amber)),
                      if (status.connection == 'session')
                        TextButton(
                            onPressed: () async {
                              if (await SessionLogout.confirmAndLogout(
                                      context) &&
                                  context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login', (_) => false);
                              }
                            },
                            child: const Text('Iniciar sesión de nuevo')),
                    ]),
              ));
        },
      );
}
