// import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/periodo_presupuesto_model.dart';
import '../models/reportes/ahorros_reporte_model.dart';
import '../models/reportes/deudas_reporte_model.dart';
import '../models/reportes/distribucion_item.dart';
import '../models/reportes/evolucion_model.dart';
import '../models/reportes/fondo_emergencia_reporte_model.dart';
import '../models/reportes/informe_completo.dart';
import '../models/reportes/presupuesto_reporte_model.dart';
import '../models/reportes/resumen_model.dart';
import '../services/presupuestos_service.dart';
// import '../../../../core/utils/presupuestos_parsing.dart';
import 'auth_service.dart';

class ReportesService { 
  ReportesService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<String?> get _token => AuthService.instance.getToken();

  // Arma el query string de rango de fechas para los endpoints de reportes.
  String _rangoQuery(DateTime fechaInicio, DateTime fechaFin) {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    return '?fecha_inicio=${fmt(fechaInicio)}&fecha_fin=${fmt(fechaFin)}';
  }


  // ---------------------------------------------------------------------
  // Reportes con rango de fechas
  // ---------------------------------------------------------------------

  Future<ReporteResumen> getResumen({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/resumen${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return ReporteResumen.fromJson(json);
  }

  Future<List<DistribucionItem>> getGastosPorCategoria({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/gastos/categorias${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return DistribucionItem.listFromJson(
      json['datos'] as List<dynamic>? ?? [],
      nombreKey: 'categoria',
      idKey: 'id_categoria',
    );
  }

  Future<List<DistribucionItem>> getGastosPorDependiente({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/gastos/dependientes${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return DistribucionItem.listFromJson(
      json['datos'] as List<dynamic>? ?? [],
      nombreKey: 'dependiente',
      idKey: 'id_dependiente',
    );
  }

  Future<List<DistribucionItem>> getIngresosPorCategoria({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/ingresos/categorias${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return DistribucionItem.listFromJson(
      json['datos'] as List<dynamic>? ?? [],
      nombreKey: 'categoria',
      idKey: 'id_categoria',
    );
  }

  Future<List<DistribucionItem>> getIngresosPorFuente({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/ingresos/fuentes${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return DistribucionItem.listFromJson(
      json['datos'] as List<dynamic>? ?? [],
      nombreKey: 'fuente',
    );
  }

  Future<List<DistribucionItem>> getImprevistosPorCategoria({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/imprevistos/categorias${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return DistribucionItem.listFromJson(
      json['datos'] as List<dynamic>? ?? [],
      nombreKey: 'categoria',
      idKey: 'id_categoria',
    );
  }

  Future<ReporteAhorros> getAhorros({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/ahorros${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return ReporteAhorros.fromJson(json);
  }

  Future<ReporteDeudas> getDeudas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/deudas${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return ReporteDeudas.fromJson(json);
  }

  Future<ReporteFondoEmergencia> getFondoEmergencia({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/fondo-emergencia${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return ReporteFondoEmergencia.fromJson(json);
  }

  Future<ReporteEvolucion> getEvolucion({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/evolucion${_rangoQuery(fechaInicio, fechaFin)}',
      token: token,
    );
    return ReporteEvolucion.fromJson(json);
  }

  Future<ReportePresupuesto> getReportePresupuesto({
    required int idPeriodo,
  }) async {
    final token = await _token;
    final json = await _api.get(
      '/reportes/presupuesto/$idPeriodo',
      token: token,
    );
    return ReportePresupuesto.fromJson(json);
  }

  // ---------------------------------------------------------------------
  // Estado actual (sin rango de fechas)
  // ---------------------------------------------------------------------

  Future<EstadoAhorros> getEstadoAhorros() async {
    final token = await _token;
    final json = await _api.get('/reportes/ahorros/estado', token: token);
    return EstadoAhorros.fromJson(json);
  }

  Future<EstadoDeudas> getEstadoDeudas() async {
    final token = await _token;
    final json = await _api.get('/reportes/deudas/estado', token: token);
    return EstadoDeudas.fromJson(json);
  }

  Future<EstadoFondoEmergencia> getEstadoFondoEmergencia() async {
    final token = await _token;
    final json =
        await _api.get('/reportes/fondo-emergencia/estado', token: token);
    return EstadoFondoEmergencia.fromJson(json);
  }

  // ---------------------------------------------------------------------
  // Períodos disponibles para el selector de presupuesto (reusa el
  // servicio ya existente de Presupuestos, no duplica lógica)
  // ---------------------------------------------------------------------

  Future<List<PeriodoPresupuesto>> getPeriodosDisponibles({
    int pagina = 1,
    int limite = 20,
  }) async {
    final resultado = await PresupuestosService()
        .listarPeriodos(pagina: pagina, limite: limite);
    return resultado.periodos;
  }

  // ---------------------------------------------------------------------
  // Informe completo (las 14 secciones juntas, tolerante a fallos)
  // ---------------------------------------------------------------------

  /// Llama a una función que puede fallar y, si falla, devuelve null en
  /// vez de tumbar todo el informe. Así una sección sin datos (ej. el
  /// usuario no tiene fondo de emergencia) no rompe las otras 13.
  Future<T?> _seguro<T>(Future<T> Function() llamada) async {
    try {
      return await llamada();
    } catch (_) {
      return null;
    }
  }

  Future<InformeCompleto> obtenerInformeCompleto({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int? idPeriodo,
  }) async {
    final resultados = await Future.wait<dynamic>([
      _seguro(() => getResumen(fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getGastosPorCategoria(
          fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getGastosPorDependiente(
          fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getIngresosPorCategoria(
          fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() =>
          getIngresosPorFuente(fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getImprevistosPorCategoria(
          fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getAhorros(fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getEstadoAhorros()),
      _seguro(() => getDeudas(fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getEstadoDeudas()),
      _seguro(() => getFondoEmergencia(
          fechaInicio: fechaInicio, fechaFin: fechaFin)),
      _seguro(() => getEstadoFondoEmergencia()),
      _seguro(
          () => getEvolucion(fechaInicio: fechaInicio, fechaFin: fechaFin)),
    ]);

    // El presupuesto solo se pide si el usuario eligió un período.
    final presupuesto = idPeriodo == null
        ? null
        : await _seguro(() => getReportePresupuesto(idPeriodo: idPeriodo));

    return InformeCompleto(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      idPeriodo: idPeriodo,
      resumen: resultados[0] as ReporteResumen?,
      gastosCategoria: resultados[1] as List<DistribucionItem>?,
      gastosDependiente: resultados[2] as List<DistribucionItem>?,
      ingresosCategoria: resultados[3] as List<DistribucionItem>?,
      ingresosFuente: resultados[4] as List<DistribucionItem>?,
      imprevistosCategoria: resultados[5] as List<DistribucionItem>?,
      ahorros: resultados[6] as ReporteAhorros?,
      estadoAhorros: resultados[7] as EstadoAhorros?,
      deudas: resultados[8] as ReporteDeudas?,
      estadoDeudas: resultados[9] as EstadoDeudas?,
      fondoEmergencia: resultados[10] as ReporteFondoEmergencia?,
      estadoFondoEmergencia: resultados[11] as EstadoFondoEmergencia?,
      evolucion: resultados[12] as ReporteEvolucion?,
      presupuesto: presupuesto,
    );
  }
}