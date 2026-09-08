import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/periodo_presupuesto_model.dart';
import '../models/presupuesto_model.dart';
import '../services/presupuestos_service.dart';

enum PresupuestoLoadStatus { initial, loading, loaded, error }

/// Estado de la vista "Presupuestos": perfiles + período activo,
/// y las acciones (abrir/cerrar período, ajustar ingreso, activar
/// perfil, crear/editar perfil). Después de cualquier acción que
/// muta datos en el backend, vuelve a pedir todo con [cargar] en vez
/// de intentar reconstruir el estado a mano — así el modelo nunca
/// queda desincronizado con lo que el backend calculó (montos,
/// ejecución, saldo, etc.).
class PresupuestoProvider extends ChangeNotifier {
  PresupuestoProvider({PresupuestosService? service})
      : _service = service ?? PresupuestosService();

  final PresupuestosService _service;

  PresupuestoLoadStatus status = PresupuestoLoadStatus.initial;
  String? errorMessage;

  List<Presupuesto> perfiles = [];
  PeriodoPresupuesto? periodoActivo;

  bool resumenExpandido = false;
  int? perfilExpandidoId;

  bool _accionEnCurso = false;
  bool get accionEnCurso => _accionEnCurso;

  bool get cargando => status == PresupuestoLoadStatus.loading;

  Presupuesto? get perfilActivo {
    for (final p in perfiles) {
      if (p.activo) return p;
    }
    return null;
  }

  /// Carga inicial / refresco completo. Llamar en initState de la
  /// pantalla y en pull-to-refresh.
  Future<void> cargar() async {
    status = PresupuestoLoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _service.listarPerfiles(),
        _service.obtenerPeriodoActivo(),
      ]);
      perfiles = resultados[0] as List<Presupuesto>;
      periodoActivo = resultados[1] as PeriodoPresupuesto?;
      status = PresupuestoLoadStatus.loaded;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = PresupuestoLoadStatus.error;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado: $e';
      status = PresupuestoLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> refrescar() => cargar();

  void toggleResumen() {
    resumenExpandido = !resumenExpandido;
    notifyListeners();
  }

  void togglePerfilExpandido(int idPresupuesto) {
    perfilExpandidoId = perfilExpandidoId == idPresupuesto ? null : idPresupuesto;
    notifyListeners();
  }

  /// Ejecuta una mutación contra el backend y, si tiene éxito, refresca
  /// todo el estado. Devuelve true/false para que la UI pueda mostrar
  /// un SnackBar de éxito o dejar que [errorMessage] hable por sí solo.
  Future<bool> _ejecutarAccion(Future<void> Function() accion) async {
    _accionEnCurso = true;
    errorMessage = null;
    notifyListeners();
    try {
      await accion();
      await cargar();
      _accionEnCurso = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      _accionEnCurso = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Ocurrió un error inesperado: $e';
      _accionEnCurso = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> abrirPeriodo(double ingresoEstimado) {
    return _ejecutarAccion(
      () => _service.abrirPeriodo(ingresoEstimado: ingresoEstimado),
    );
  }

  Future<bool> cerrarPeriodo() {
    return _ejecutarAccion(() => _service.cerrarPeriodo());
  }

  Future<bool> ajustarIngreso(double ingresoEstimado) {
    return _ejecutarAccion(
      () => _service.ajustarIngreso(ingresoEstimado: ingresoEstimado),
    );
  }

  Future<bool> activarPerfil(int id) {
    return _ejecutarAccion(() => _service.activarPerfil(id));
  }

  Future<bool> eliminarPerfil(int id) {
    return _ejecutarAccion(() => _service.eliminarPerfil(id));
  }

  Future<bool> crearPerfil({
    required String nombre,
    String? descripcion,
    required int diaCorte,
    required double porcentajeGastos,
    required double porcentajeDeudas,
    required double porcentajeImprevistos,
    required double porcentajeAhorros,
    required double porcentajeEmergencia,
  }) {
    return _ejecutarAccion(
      () => _service.crearPerfil(
        nombre: nombre,
        descripcion: descripcion,
        diaCorte: diaCorte,
        porcentajeGastos: porcentajeGastos,
        porcentajeDeudas: porcentajeDeudas,
        porcentajeImprevistos: porcentajeImprevistos,
        porcentajeAhorros: porcentajeAhorros,
        porcentajeEmergencia: porcentajeEmergencia,
      ),
    );
  }

  Future<bool> editarPerfil({
    required int id,
    String? nombre,
    String? descripcion,
    int? diaCorte,
    double? porcentajeGastos,
    double? porcentajeDeudas,
    double? porcentajeImprevistos,
    double? porcentajeAhorros,
    double? porcentajeEmergencia,
  }) {
    return _ejecutarAccion(
      () => _service.editarPerfil(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        diaCorte: diaCorte,
        porcentajeGastos: porcentajeGastos,
        porcentajeDeudas: porcentajeDeudas,
        porcentajeImprevistos: porcentajeImprevistos,
        porcentajeAhorros: porcentajeAhorros,
        porcentajeEmergencia: porcentajeEmergencia,
      ),
    );
  }
}