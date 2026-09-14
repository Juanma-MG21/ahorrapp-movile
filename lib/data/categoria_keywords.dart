// lib/data/categoria_keywords.dart
//
// Diccionario de palabras clave -> nombre de categoría, compartido por
// QrParserService y OcrParserService. Es solo data (no lógica): al
// extraerlo a un archivo único, agregar o ajustar una categoría se
// refleja automáticamente en ambos flujos de autollenado sin tener que
// tocar cada parser por separado.
//
// Los nombres del lado derecho deben coincidir EXACTAMENTE (mismas
// tildes/mayúsculas) con los nombres reales de categorías en la tabla
// `categorias`, porque AgregarGastoScreen hace el match por nombre
// (case-insensitive) contra las categorías reales del backend.
const Map<String, String> mapeoCategoriasKeywords = {
  // Alimentación
  'supermercado': 'Alimentación', 'super': 'Alimentación', 'mercado': 'Alimentación',
  'restaurante': 'Alimentación', 'panaderia': 'Alimentación', 'panadería': 'Alimentación',
  'cafeteria': 'Alimentación', 'cafetería': 'Alimentación', 'domicilios': 'Alimentación',
  'rappi': 'Alimentación', 'ara': 'Alimentación', 'exito': 'Alimentación', 'éxito': 'Alimentación',
  'd1': 'Alimentación', 'justo y bueno': 'Alimentación', 'olimpica': 'Alimentación',

  // Ropa
  'almacen': 'Ropa', 'almacén': 'Ropa', 'boutique': 'Ropa', 'calzado': 'Ropa',
  'zara': 'Ropa', 'falabella': 'Ropa',

  // Hogar
  'arriendo': 'Hogar', 'administracion': 'Hogar', 'administración': 'Hogar',
  'ferreteria': 'Hogar', 'ferretería': 'Hogar', 'homecenter': 'Hogar',
  'acueducto': 'Hogar', 'energia': 'Hogar', 'energía': 'Hogar', 'gas natural': 'Hogar',

  // Transporte
  'combustible': 'Transporte', 'gasolina': 'Transporte', 'estacion de servicio': 'Transporte',
  'estación de servicio': 'Transporte', 'peaje': 'Transporte', 'parqueadero': 'Transporte',
  'taxi': 'Transporte', 'uber': 'Transporte', 'terminal': 'Transporte',

  // Salud
  'farmacia': 'Salud', 'droguer': 'Salud', 'clinica': 'Salud', 'clínica': 'Salud',
  'hospital': 'Salud', 'eps': 'Salud', 'laboratorio': 'Salud',

  // Entretenimiento
  'cine': 'Entretenimiento', 'cinemark': 'Entretenimiento', 'cinepolis': 'Entretenimiento',
  'netflix': 'Entretenimiento', 'spotify': 'Entretenimiento', 'teatro': 'Entretenimiento',
};