import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/offline_query_service.dart';

/// Hace visible el origen y la antigüedad de la copia, incluso si está vacía.
class OfflineQueryBanner extends StatelessWidget {
  const OfflineQueryBanner({super.key, required this.resource, this.onRetry});
  final String resource;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, QueryStatus>>(
      valueListenable: OfflineQueryService.instance.statuses,
      builder: (context, statuses, _) {
        final status = statuses[resource];
        if (status == null) return const SizedBox.shrink();
        final date = status.downloadedAt == null
            ? null
            : DateFormat('dd/MM/yyyy HH:mm')
                .format(status.downloadedAt!.toLocal());
        final message = switch (status.source) {
          QuerySource.local => date == null
              ? status.message ?? 'Solo registros guardados en este teléfono.'
              : 'Copia local del $date. ${status.message ?? 'No se pudo conectar con el servidor.'}',
          QuerySource.server => status.message ?? 'Datos actualizados: $date',
          QuerySource.unavailable =>
            status.message ?? 'No se pudo consultar la información.',
        };
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                  status.source == QuerySource.server && status.message == null
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 12))),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Actualizar')),
            ],
          ),
        );
      },
    );
  }
}
