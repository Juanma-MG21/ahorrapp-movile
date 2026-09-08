// Helpers de parseo defensivo para las respuestas de /api/presupuestos.
//
// El driver de Postgres (pg) a veces serializa numéricos como String
// (columnas DECIMAL) y booleanos como bool nativo o como 0/1 según la
// consulta. Estas funciones evitan que un cambio de formato en el
// backend rompa el parseo en la app.

bool parseBoolFlexible(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 't';
  }
  return false;
}

int? parseIntFlexible(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? parseDoubleFlexible(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Acepta tanto fechas 'YYYY-MM-DD' (las que arma el backend con
/// toLocalDate en abrirPeriodo) como timestamps ISO completos (los que
/// devuelve pg al seleccionar columnas DATE directamente).
DateTime? parseDateFlexible(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// Formatea un monto como pesos sin decimales y con puntos de miles,
/// ej: 2000000 -> "2.000.000". No depende del paquete `intl`.
String formatMonto(num value) {
  final isNegative = value < 0;
  final entero = value.abs().round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < entero.length; i++) {
    final posicionDesdeElFinal = entero.length - i;
    buffer.write(entero[i]);
    final faltanParaElFinal = posicionDesdeElFinal - 1;
    if (faltanParaElFinal > 0 && faltanParaElFinal % 3 == 0) {
      buffer.write('.');
    }
  }
  return '${isNegative ? '-' : ''}\$${buffer.toString()}';
}

/// Formatea una fecha como dd/MM/yyyy.
String formatFechaCorta(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final y = fecha.year.toString();
  return '$d/$m/$y';
}