/// Parsers compartidos para convertir valores que vienen del backend
/// en tipos de Dart que la app espera.
library;

/// Convierte a `double` un valor que puede venir como String o num.
///
/// El backend devuelve columnas NUMERIC/DECIMAL de PostgreSQL (como
/// `monto`) serializadas como String (ej. "75000.00") en vez de
/// número — es el comportamiento por defecto del driver `pg` de
/// Node, para no perder precisión decimal. Se usa en cualquier
/// modelo que tenga un campo de este tipo (GastoModel, IngresoModel,
/// y probablemente Ahorro/Deuda/Imprevisto más adelante).
double parseMonto(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Monto inválido: $value');
}