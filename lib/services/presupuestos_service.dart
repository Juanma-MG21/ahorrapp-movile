import '../core/network/api_client.dart';
import '../models/periodo_presupuesto_model.dart';
import '../models/presupuesto_model.dart';
import 'auth_service.dart';

class PresupuestosService {
  PresupuestosService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<String?> get _token => AuthService.instance.getToken();

  // ───────────────────────────── Perfiles ─────────────────────────────

  /// GET /presupuestos
  Future<List<Presupuesto>> listarPerfiles() async {
    final token = await _token;
    final res = await _api.get('/presupuestos', token: token);
    final data = (res['data'] as List<dynamic>?) ?? const [];
    return data
        .map((e) => Presupuesto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /presupuestos/:id
  Future<Presupuesto> obtenerPerfil(int id) async {
    final token = await _token;
    final res = await _api.get('/presupuestos/$id', token: token);
    return Presupuesto.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  /// POST /presupuestos — los 5 porcentajes deben sumar 100 (lo valida
  /// también el backend, pero conviene validarlo antes en el form).
  Future<void> crearPerfil({
    required String nombre,
    String? descripcion,
    required int diaCorte,
    required double porcentajeGastos,
    required double porcentajeDeudas,
    required double porcentajeImprevistos,
    required double porcentajeAhorros,
    required double porcentajeEmergencia,
  }) async {
    final token = await _token;
    await _api.post(
      '/presupuestos',
      token: token,
      body: {
        'Nombre': nombre,
        'Descripcion': descripcion,
        'Dia_corte': diaCorte,
        'Porcentaje_gastos': porcentajeGastos,
        'Porcentaje_deudas': porcentajeDeudas,
        'Porcentaje_imprevistos': porcentajeImprevistos,
        'Porcentaje_ahorros': porcentajeAhorros,
        'Porcentaje_emergencia': porcentajeEmergencia,
      },
    );
  }

  /// PUT /presupuestos/:id — el backend rechaza (409) editar un perfil
  /// que tiene un período abierto asociado.
  Future<void> editarPerfil({
    required int id,
    String? nombre,
    String? descripcion,
    int? diaCorte,
    double? porcentajeGastos,
    double? porcentajeDeudas,
    double? porcentajeImprevistos,
    double? porcentajeAhorros,
    double? porcentajeEmergencia,
  }) async {
    final token = await _token;
    await _api.put(
      '/presupuestos/$id',
      token: token,
      body: {
        if (nombre != null) 'Nombre': nombre,
        if (descripcion != null) 'Descripcion': descripcion,
        if (diaCorte != null) 'Dia_corte': diaCorte,
        if (porcentajeGastos != null) 'Porcentaje_gastos': porcentajeGastos,
        if (porcentajeDeudas != null) 'Porcentaje_deudas': porcentajeDeudas,
        if (porcentajeImprevistos != null)
          'Porcentaje_imprevistos': porcentajeImprevistos,
        if (porcentajeAhorros != null) 'Porcentaje_ahorros': porcentajeAhorros,
        if (porcentajeEmergencia != null)
          'Porcentaje_emergencia': porcentajeEmergencia,
      },
    );
  }

  /// DELETE /presupuestos/:id — el backend rechaza (409) si es el
  /// perfil activo o si tiene períodos históricos.
  Future<void> eliminarPerfil(int id) async {
    final token = await _token;
    await _api.delete('/presupuestos/$id', token: token);
  }

  /// PUT /presupuestos/:id/activar — el backend rechaza (409) si hay
  /// un período abierto (hay que cerrarlo primero).
  Future<void> activarPerfil(int id) async {
    final token = await _token;
    await _api.put('/presupuestos/$id/activar', token: token);
  }

  // ───────────────────────────── Períodos ─────────────────────────────

  /// GET /presupuestos/periodos/activo — devuelve null si no hay
  /// período abierto (el backend responde { ok: true, data: null }).
  Future<PeriodoPresupuesto?> obtenerPeriodoActivo() async {
    final token = await _token;
    final res = await _api.get('/presupuestos/periodos/activo', token: token);
    final data = res['data'];
    if (data == null) return null;
    return PeriodoPresupuesto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// GET /presupuestos/periodos (histórico paginado)
  Future<({List<PeriodoPresupuesto> periodos, int total, int pagina, int limite})>
      listarPeriodos({int pagina = 1, int limite = 10}) async {
    final token = await _token;
    final res = await _api.get(
      '/presupuestos/periodos?pagina=$pagina&limite=$limite',
      token: token,
    );
    final data = (res['data'] as List<dynamic>?) ?? const [];
    return (
      periodos: data
          .map((e) =>
              PeriodoPresupuesto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: parseIntFlexibleOrZero(res['total']),
      pagina: parseIntFlexibleOrZero(res['pagina']),
      limite: parseIntFlexibleOrZero(res['limite']),
    );
  }

  /// POST /presupuestos/periodos/abrir — requiere un perfil activo
  /// (el backend lo resuelve solo, no se manda id_presupuesto).
  Future<void> abrirPeriodo({required double ingresoEstimado}) async {
    final token = await _token;
    await _api.post(
      '/presupuestos/periodos/abrir',
      token: token,
      body: {'ingreso_estimado': ingresoEstimado},
    );
  }

  /// PUT /presupuestos/periodos/cerrar
  Future<void> cerrarPeriodo() async {
    final token = await _token;
    await _api.put('/presupuestos/periodos/cerrar', token: token);
  }

  /// PATCH /presupuestos/periodos/ajustar-ingreso
  Future<void> ajustarIngreso({required double ingresoEstimado}) async {
    final token = await _token;
    await _api.patch(
      '/presupuestos/periodos/ajustar-ingreso',
      token: token,
      body: {'ingreso_estimado': ingresoEstimado},
    );
  }
}

int parseIntFlexibleOrZero(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}