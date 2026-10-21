import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'offline_sync_service.dart';

class SessionLogout {
  static Future<bool> confirmAndLogout(BuildContext context) async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final owner = await auth.getCurrentUser();
    int? pending;
    try {
      pending = owner == null
          ? 0
          : (await OfflineSyncService.instance.database
                  .operations(owner.id, all: true))
              .length;
    } catch (_) {
      // Si no se pudo leer la cola, tampoco se afirma que esté vacía.
    }
    if (!context.mounted) return false;
    if (pending != 0) {
      final accepted = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Registros en este teléfono'),
                content: Text(pending == null
                    ? 'No pudimos comprobar los pendientes. Al salir, los datos locales se conservan asociados a esta cuenta.'
                    : 'Tienes $pending registros pendientes de sincronizar. Se conservarán para esta cuenta en este teléfono. Vuelve a iniciar sesión con la misma cuenta para enviarlos. Si eliminas los datos de la app, podrías perderlos.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar sesión')),
                ],
              ));
      if (accepted != true) return false;
    }
    if (!identical(auth, AuthService.instance) ||
        version != auth.sessionVersion) {
      return false;
    }
    await auth.logout();
    return true;
  }
}
