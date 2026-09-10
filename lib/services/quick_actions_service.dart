import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import '../screens/gastos/agregar_gasto_screen.dart';
import '../screens/ingresos/agregar_ingreso_screen.dart';

class QuickActionsService {
  static final QuickActions _quickActions = const QuickActions();

  static void init(BuildContext context) {
    debugPrint('QuickActionsService: Inicializando...');
    _quickActions.initialize((String type) {
      debugPrint('QuickActionsService: Atajo detectado -> $type');
      if (type == 'action_gasto') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarGastoScreen()),
        );
      } else if (type == 'action_ingreso') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgregarIngresoScreen()),
        );
      }
    });

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_gasto',
        localizedTitle: 'Nuevo Gasto',
        icon: 'ic_launcher', // Usa el ícono por defecto si no hay específicos
      ),
      const ShortcutItem(
        type: 'action_ingreso',
        localizedTitle: 'Nuevo Ingreso',
        icon: 'ic_launcher',
      ),
    ]);
  }
}
