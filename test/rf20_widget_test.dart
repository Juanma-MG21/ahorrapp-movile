import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/models/gasto_model.dart';
import 'package:ahorrapp_movil/models/ingreso_model.dart';
import 'package:ahorrapp_movil/models/imprevisto_model.dart';
import 'package:ahorrapp_movil/services/financial_widget_summary.dart';

void main() {
  test('limpiar no espera a que finalice el cierre de sesión', () async {
    final writes = <Map<String, dynamic>>[];
    final updater = FinancialWidgetUpdater(
        session: () => Completer<String?>().future,
        load: (_) => throw StateError('No debe consultar'),
        publish: (data) async => writes.add(data));
    await updater.clear();
    expect(writes.single['balance'], '—');
  });
  final october = DateTime(2026, 10, 7);
  FinancialWidgetSummary summary(double income, double expenses) =>
      FinancialWidgetSummary(
          month: DateTime(2026, 10), ingresos: income, gastos: expenses);

  test('mes y año actuales, imprevistos y exclusión de pendientes', () {
    final result = FinancialWidgetSummary.calculate(october, [
      IngresoModel(monto: 1000, fechaRegistro: october),
      IngresoModel(monto: 9999, fechaRegistro: october, syncState: 'pending'),
      IngresoModel(monto: 900, fechaRegistro: DateTime(2025, 10)),
      IngresoModel(monto: 900, fechaRegistro: DateTime(2026, 9)),
    ], [
      GastoModel(monto: 200, fecha: october),
      GastoModel(monto: 999, fecha: october, syncState: 'sending'),
      GastoModel(monto: 999, fecha: october, syncState: 'error'),
      GastoModel(monto: 999, fecha: DateTime(2026, 11)),
    ], [
      ImprevistoModel(monto: 50, fecha: october),
      ImprevistoModel(monto: 800, fecha: DateTime(2025, 10))
    ]);
    expect(result.ingresos, 1000);
    expect(result.gastos, 250);
    expect(result.balance, 750);
    expect(result.toJson()['porcentaje'], '25%');
    expect(result.toJson()['fecha'], 'Octubre 2026');
  });

  test('centavos y formato iguales incluso con balance negativo', () {
    final result = FinancialWidgetSummary.calculate(october, [
      IngresoModel(monto: .1, fechaRegistro: october),
      IngresoModel(monto: .2, fechaRegistro: october)
    ], [
      GastoModel(monto: .4, fecha: october)
    ], []);
    expect(result.ingresos, .3);
    expect(result.toJson()['balance'], '-\$0.10');
    expect(result.toJson()['porcentaje'], '133%');
    expect(result.toJson()['progreso'], 100);
  });

  test('sin ingresos el porcentaje es indefinido, no un 0% falso', () {
    expect(summary(0, 20).toJson()['porcentaje'], '—');
    expect(summary(0, 20).balance, -20);
    expect(summary(0, 0).toJson()['ingresos'], '\$0.00');
  });

  test('copia local identificada y montos inválidos rechazados', () {
    expect(
        FinancialWidgetSummary.calculate(october, [], [], [], local: true)
            .toJson()['fecha'],
        contains('copia local'));
    expect(
        () => FinancialWidgetSummary.calculate(october,
            [IngresoModel(monto: double.nan, fechaRegistro: october)], [], []),
        throwsFormatException);
  });

  test('solicitudes repetidas conservan el resumen completo', () async {
    final writes = <Map<String, dynamic>>[];
    final updater = FinancialWidgetUpdater(
        session: () async => '7:1',
        load: (_) async => summary(1000, 250),
        publish: (data) async => writes.add(data));
    for (final module in ['gastos', 'ingresos', 'imprevistos']) {
      await updater.refresh();
      expect(writes.last['balance'], '\$750.00', reason: module);
      expect(writes.last['ingresos'], '\$1000.00', reason: module);
      expect(writes.last['gastos'], '\$250.00', reason: module);
    }
  });

  test('fallo de un recurso conserva cifras del mismo mes, sin poner ceros',
      () async {
    final writes = <Map<String, dynamic>>[];
    var fail = false;
    var month = october;
    final updater = FinancialWidgetUpdater(
        session: () async => '7:1',
        clock: () => month,
        load: (_) async {
          if (fail) throw Exception('Servidor no disponible');
          return summary(1000, 250);
        },
        publish: (data) async => writes.add(data));
    await updater.refresh();
    fail = true;
    await updater.refresh();
    expect(writes.last['ingresos'], '\$1000.00');
    expect(writes.last['fecha'], contains('sin actualizar'));
    month = DateTime(2026, 11);
    await updater.refresh();
    expect(writes.last['balance'], '—');
  });

  test('respuestas fuera de orden no pisan la actualización reciente',
      () async {
    final first = Completer<FinancialWidgetSummary>();
    final started = Completer<void>();
    final writes = <Map<String, dynamic>>[];
    var calls = 0;
    final updater = FinancialWidgetUpdater(
        session: () async => '7:1',
        load: (_) {
          if (++calls == 1) {
            started.complete();
            return first.future;
          }
          return Future.value(summary(2000, 500));
        },
        publish: (data) async => writes.add(data));
    final old = updater.refresh();
    await started.future;
    await updater.refresh();
    first.complete(summary(100, 30));
    await old;
    expect(writes.last['balance'], '\$1500.00');
  });

  test('logout borra cifras e invalida una consulta en vuelo', () async {
    String? owner = '7:1';
    final pending = Completer<FinancialWidgetSummary>();
    final started = Completer<void>();
    final writes = <Map<String, dynamic>>[];
    final updater = FinancialWidgetUpdater(
        session: () async => owner,
        load: (_) {
          started.complete();
          return pending.future;
        },
        publish: (data) async => writes.add(data));
    final request = updater.refresh();
    await started.future;
    owner = null;
    await updater.clear();
    pending.complete(summary(1000, 250));
    await request;
    expect(writes.last['balance'], '—');
    expect(writes.last['fecha'], 'Inicia sesión');
  });

  test('otra cuenta no conserva el resumen anterior si falla su descarga',
      () async {
    var owner = '7:1';
    final writes = <Map<String, dynamic>>[];
    final updater = FinancialWidgetUpdater(
        session: () async => owner,
        load: (_) async {
          if (owner == '8:2') throw Exception('Sin copia');
          return summary(1000, 250);
        },
        publish: (data) async => writes.add(data));
    await updater.refresh();
    owner = '8:2';
    await updater.refresh();
    expect(writes.last['balance'], '—');
    expect(writes.last['fecha'], 'No se pudo actualizar');
  });
}
