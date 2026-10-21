import 'package:flutter/material.dart';

class SyncStateBadge extends StatelessWidget {
  const SyncStateBadge({super.key, required this.state, this.error});
  final String state;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      'synced' => 'Sincronizado',
      'sending' => 'Enviando…',
      'error' => 'Requiere corrección con conexión',
      'session_required' => 'Pendiente: inicia sesión de nuevo',
      _ => 'Pendiente de sincronizar',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            state == 'synced'
                ? Icons.cloud_done_outlined
                : Icons.cloud_upload_outlined,
            size: 16,
            color: state == 'synced' ? Colors.greenAccent : Colors.amber),
        const SizedBox(width: 6),
        Expanded(
            child: Text('$label${error == null ? '' : '\n$error'}',
                style: TextStyle(
                    fontSize: 12,
                    color: state == 'synced'
                        ? Colors.greenAccent
                        : Colors.amber))),
      ]),
    );
  }
}
