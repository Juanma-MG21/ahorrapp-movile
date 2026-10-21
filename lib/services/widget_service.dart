import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../core/network/api_client.dart';
import '../models/gasto_model.dart';
import '../models/ingreso_model.dart';
import '../models/imprevisto_model.dart';
import 'auth_service.dart';
import 'offline_query_service.dart';
import 'financial_widget_summary.dart';

class WidgetService {
  static final _updater = FinancialWidgetUpdater(session: () async {
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    final owner = await auth.getCurrentUser();
    if (!identical(auth, AuthService.instance) ||
        version != auth.sessionVersion) {
      return null;
    }
    return owner == null ? null : '${owner.id}:$version';
  }, load: (now) async {
    final queries = OfflineQueryService.instance;
    final client = const ApiClient();
    // obtenerImprevistos() oculta errores como []; aquí se exige copia válida.
    final rows = await Future.wait([
      queries.query('/movimientos/ingresos', client, IngresoModel.fromJson),
      queries.query('/movimientos/gastos', client, GastoModel.fromJson),
      queries.query(
          '/movimientos/imprevistos', client, ImprevistoModel.fromJson),
    ]);
    return FinancialWidgetSummary.calculate(now, rows[0].cast<IngresoModel>(),
        rows[1].cast<GastoModel>(), rows[2].cast<ImprevistoModel>(),
        local: [
          '/movimientos/ingresos',
          '/movimientos/gastos',
          '/movimientos/imprevistos'
        ].any(
            (key) => queries.statuses.value[key]?.source == QuerySource.local));
  }, publish: (values) async {
    // Una instantánea atómica: Android nunca mezcla cifras de dos consultas.
    await HomeWidget.saveWidgetData('financial_summary_v1', jsonEncode(values));
    await HomeWidget.updateWidget(androidName: 'AhorrAppSmallWidgetProvider');
    await HomeWidget.updateWidget(androidName: 'AhorrAppMediumWidgetProvider');
  });

  static bool _started = false;
  static void start() {
    if (_started) return;
    _started = true;
    AuthService.sessionChanges.addListener(_sessionChanged);
  }

  static void _sessionChanged() async {
    try {
      await _updater.clear();
      await refresh();
    } catch (error) {
      debugPrint('No se pudo limpiar el widget: $error');
    }
  }

  static Future<void> refresh() async {
    start();
    try {
      await _updater.refresh();
    } catch (error) {
      debugPrint('No se pudo actualizar el widget: $error');
    }
  }
}
