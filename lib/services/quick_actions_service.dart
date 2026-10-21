import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/gastos/agregar_gasto_screen.dart';
import '../screens/ingresos/agregar_ingreso_screen.dart';
import 'auth_service.dart';

/// Captura el arranque nativo antes del login y abre el formulario cuando
/// MainScreen está lista. Nunca guarda ni inicia dictado desde el shortcut.
class QuickActionsService {
  @visibleForTesting
  static QuickActions actions = const QuickActions();
  static bool _initialized = false;
  static BuildContext? _context;
  static String? _pending;
  static bool _opening = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await actions.initialize(receive);
      await actions.setShortcutItems(const [
        ShortcutItem(
            type: 'action_gasto',
            localizedTitle: 'Nuevo gasto',
            icon: 'ic_shortcut_gasto'),
        ShortcutItem(
            type: 'action_ingreso',
            localizedTitle: 'Nuevo ingreso',
            icon: 'ic_shortcut_ingreso'),
      ]);
    } catch (error) {
      debugPrint('Accesos nativos no disponibles: $error');
    }
  }

  static void attach(BuildContext context) {
    _context = context;
    _drain();
  }

  static void detach(BuildContext context) {
    if (identical(context, _context)) _context = null;
  }

  static void receive(String type) {
    if (type != 'action_gasto' && type != 'action_ingreso') return;
    if (_opening) return;
    _pending = type;
    _drain();
  }

  static Future<void> _drain() async {
    final context = _context;
    final type = _pending;
    if (_opening || context == null || !context.mounted || type == null) return;
    _opening = true;
    try {
      final auth = AuthService.instance;
      final version = auth.sessionVersion;
      final authenticated = await auth.hasSession();
      final owner = await auth.getCurrentUser();
      if (!context.mounted ||
          !identical(context, _context) ||
          !identical(auth, AuthService.instance) ||
          version != auth.sessionVersion ||
          !authenticated ||
          owner == null) {
        return;
      }
      _pending = null;
      await Navigator.of(context).push(MaterialPageRoute<Object?>(
          builder: (_) => AuthGate(
              watchSession: true,
              child: type == 'action_gasto'
                  ? const AgregarGastoScreen()
                  : const AgregarIngresoScreen())));
    } catch (error) {
      debugPrint('No se pudo abrir el acceso rápido: $error');
    } finally {
      _opening = false;
    }
  }

  @visibleForTesting
  static void reset() {
    _initialized = false;
    _context = null;
    _pending = null;
    _opening = false;
  }
}
