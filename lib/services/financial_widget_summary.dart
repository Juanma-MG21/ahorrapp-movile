import '../models/gasto_model.dart';
import '../models/ingreso_model.dart';
import '../models/imprevisto_model.dart';

/// Regla única del mes actual para ambos tamaños del widget Android.
class FinancialWidgetSummary {
  FinancialWidgetSummary(
      {required this.month,
      required this.ingresos,
      required this.gastos,
      this.local = false});
  final DateTime month;
  final double ingresos;
  final double gastos;
  final bool local;
  double get balance => ingresos - gastos;
  double? get percentage => ingresos > 0 ? gastos / ingresos * 100 : null;

  static FinancialWidgetSummary calculate(
      DateTime now,
      List<IngresoModel> incomes,
      List<GastoModel> expenses,
      List<ImprevistoModel> unexpected,
      {bool local = false}) {
    bool current(DateTime date) =>
        date.year == now.year && date.month == now.month;
    // Centavos enteros para no acumular errores de punto flotante.
    int cents(Iterable<double> amounts) => amounts.fold(0, (total, value) {
          if (!value.isFinite || value < 0) {
            throw const FormatException('Monto inválido');
          }
          return total + (value * 100).round();
        });
    return FinancialWidgetSummary(
        month: DateTime(now.year, now.month),
        ingresos: cents(incomes
                .where((i) => i.isSynced && current(i.fechaRegistro))
                .map((i) => i.monto)) /
            100,
        gastos: cents([
              ...expenses
                  .where((g) => g.isSynced && current(g.fecha))
                  .map((g) => g.monto),
              ...unexpected.where((i) => current(i.fecha)).map((i) => i.monto),
            ]) /
            100,
        local: local);
  }

  static const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];
  static String currency(double amount) =>
      '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}';
  Map<String, dynamic> toJson() => {
        'balance': currency(balance),
        'ingresos': currency(ingresos),
        'gastos': currency(gastos),
        'porcentaje': percentage == null ? '—' : '${percentage!.round()}%',
        'progreso': (percentage ?? 0).clamp(0, 100).round(),
        'fecha':
            '${months[month.month - 1]} ${month.year}${local ? ' · copia local' : ''}',
      };
}

/// Publica solo consultas completas de la sesión vigente. Las escrituras
/// se serializan y las respuestas antiguas no sobrescriben las recientes.
class FinancialWidgetUpdater {
  FinancialWidgetUpdater(
      {required this.session,
      required this.load,
      required this.publish,
      DateTime Function()? clock})
      : clock = clock ?? DateTime.now;
  final Future<String?> Function() session;
  final Future<FinancialWidgetSummary> Function(DateTime) load;
  final Future<void> Function(Map<String, dynamic>) publish;
  final DateTime Function() clock;
  int _revision = 0;
  String? _owner;
  FinancialWidgetSummary? _last;
  Future<void> _writes = Future.value();

  Future<void> _write(Map<String, dynamic> values, int revision, String? owner,
      {bool verifySession = true}) {
    final result = _writes.then((_) async {
      if (revision != _revision) return;
      final current = verifySession ? await session() : owner;
      if (revision == _revision && owner == current) {
        await publish(values);
      }
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> clear() async {
    final revision = ++_revision;
    _owner = null;
    _last = null;
    // No espera a borrar credenciales ni a cerrar Google: oculta las cifras ya.
    await _write(empty('Inicia sesión'), revision, null, verifySession: false);
  }

  static Map<String, dynamic> empty(String label) => {
        'balance': '—',
        'ingresos': '—',
        'gastos': '—',
        'porcentaje': '—',
        'progreso': 0,
        'fecha': label,
      };

  Future<void> refresh() async {
    final revision = ++_revision;
    final owner = await session();
    if (revision != _revision) return;
    if (owner != _owner) {
      _owner = owner;
      _last = null;
      await _write(empty(owner == null ? 'Inicia sesión' : 'Actualizando'),
          revision, owner);
    }
    if (owner == null) {
      await _write(empty('Inicia sesión'), revision, owner);
      return;
    }
    final now = clock();
    try {
      final summary = await load(now);
      if (revision != _revision || owner != await session()) return;
      await _write(summary.toJson(), revision, owner);
      if (revision == _revision) _last = summary;
    } catch (_) {
      if (revision != _revision || owner != await session()) return;
      final previous = _last;
      final sameMonth = previous != null &&
          previous.month.year == now.year &&
          previous.month.month == now.month;
      await _write(
          sameMonth
              ? {
                  ...previous.toJson(),
                  'fecha':
                      '${FinancialWidgetSummary.months[now.month - 1]} ${now.year} · sin actualizar'
                }
              : empty('No se pudo actualizar'),
          revision,
          owner);
    }
  }
}
