/// Convierte de forma segura los valores que llegan del backend (siempre
/// JSON: String, num o null) a los tipos que usamos en Dart. Evita que la
/// app truene si un campo llega null o como texto en vez de número.
double parseDouble(dynamic valor) {
  if (valor == null) return 0;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString()) ?? 0;
}

int? parseIntOrNull(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor.toString());
}

int parseInt(dynamic valor) => parseIntOrNull(valor) ?? 0;

DateTime? parseFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  return DateTime.tryParse(valor.toString());
}