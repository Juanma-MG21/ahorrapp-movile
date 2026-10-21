import 'package:flutter/foundation.dart';

import 'ahorros_service.dart';
import 'gastos_service.dart';
import 'ingresos_service.dart';

class OfflineDownloadService {
  /// Cada recurso tiene su propio resultado: un fallo no borra los demás.
  static Future<void> refresh() async {
    final results = await Future.wait([
      _download(GastosService.obtenerGastos),
      _download(IngresosService.obtenerIngresos),
      _download(AhorrosService.obtenerAhorros),
      _download(GastosService.obtenerCategorias),
      _download(GastosService.obtenerDependientes),
    ]);
    for (final error in results.whereType<Object>()) {
      debugPrint('Descarga RF-19 no completada: $error');
    }
  }

  static Future<Object?> _download(Future<Object> Function() action) async {
    try {
      await action();
      return null;
    } catch (error) {
      return error;
    }
  }
}
