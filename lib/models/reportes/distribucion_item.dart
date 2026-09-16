import 'reporte_json_utils.dart';

class DistribucionItem {
  final int? id;
  final String nombre;
  final double total;

  DistribucionItem({
    this.id,
    required this.nombre,
    required this.total,
  });

  /// [nombreKey] es la llave del nombre en el JSON (ej: "categoria",
  /// "dependiente", "fuente"), cambia según el endpoint.
  /// [idKey] es opcional porque ingresos/fuentes no trae id.
  factory DistribucionItem.fromJson(
    Map<String, dynamic> json, {
    required String nombreKey,
    String? idKey,
  }) {
    return DistribucionItem(
      id: idKey != null ? parseIntOrNull(json[idKey]) : null,
      nombre: json[nombreKey] as String? ?? '',
      total: parseDouble(json['total']),
    );
  }

  static List<DistribucionItem> listFromJson(
    List<dynamic> datos, {
    required String nombreKey,
    String? idKey,
  }) {
    return datos
        .map((e) => DistribucionItem.fromJson(
              e as Map<String, dynamic>,
              nombreKey: nombreKey,
              idKey: idKey,
            ))
        .toList();
  }
}