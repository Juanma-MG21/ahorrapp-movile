import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetService', () {
    testWidgets('updateWidgetData debe guardar datos y llamar a update', (WidgetTester tester) async {
      final List<MethodCall> log = <MethodCall>[];
      
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('es.antonborri.home_widget'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return true;
        },
      );

      await WidgetService.updateWidgetData(
        balance: '\$100.000',
        ingresos: '\$50.000',
        gastos: '\$20.000',
        porcentaje: 40,
        fecha: 'Septiembre 2026',
      );

      final saveCalls = log.where((m) => m.method == 'saveWidgetData').toList();
      expect(saveCalls.length, 5);

      final updateCalls = log.where((m) => m.method == 'updateWidget').toList();
      expect(updateCalls.length, 2);
      
      expect(updateCalls[0].arguments['androidName'], 'AhorrAppSmallWidgetProvider');
      expect(updateCalls[1].arguments['androidName'], 'AhorrAppMediumWidgetProvider');
    });
  });
}
