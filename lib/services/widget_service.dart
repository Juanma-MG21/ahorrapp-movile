import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _smallWidgetName = 'AhorrAppSmallWidgetProvider';
  static const String _mediumWidgetName = 'AhorrAppMediumWidgetProvider';

  static Future<void> updateWidgetData({
    required String balance,
    String? ingresos,
    String? gastos,
    int? porcentaje,
    String? fecha,
  }) async {
    await HomeWidget.saveWidgetData('balance', balance);
    if (ingresos != null) await HomeWidget.saveWidgetData('ingresos', ingresos);
    if (gastos != null) await HomeWidget.saveWidgetData('gastos', gastos);
    if (porcentaje != null) await HomeWidget.saveWidgetData('porcentaje', porcentaje);
    if (fecha != null) await HomeWidget.saveWidgetData('fecha', fecha);

    await HomeWidget.updateWidget(
      androidName: _smallWidgetName,
    );
    await HomeWidget.updateWidget(
      androidName: _mediumWidgetName,
    );
  }
}
