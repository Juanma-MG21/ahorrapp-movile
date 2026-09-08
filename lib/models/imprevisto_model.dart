import 'package:flutter/material.dart';
import '../core/utils/parsers.dart';
import '../core/theme/design_tokens.dart';

class ImprevistoModel {
  final int? id;
  final int? idCategoria;
  final double monto;
  final String? descripcion;
  final DateTime fecha;
  final String? categoriaNombre;

  ImprevistoModel({
    this.id,
    this.idCategoria,
    required this.monto,
    this.descripcion,
    required this.fecha,
    this.categoriaNombre,
  });

  /// Mapea una fila de GET /api/movimientos/imprevistos.
  factory ImprevistoModel.fromJson(Map<String, dynamic> json) {
    return ImprevistoModel(
      id: json['id'],
      idCategoria: json['id_categoria'],
      monto: parseMonto(json['monto']),
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      categoriaNombre: json['categoria'],
    );
  }

  /// Arma el objeto "datos" para POST /movimientos y PUT /movimientos/imprevistos/:id.
  Map<String, dynamic> toRequestBody() {
    return {
      'monto': monto,
      'descripcion': descripcion,
      'fecha_registro': fecha.toIso8601String().split('T')[0],
      'id_categoria': idCategoria,
    };
  }

  // ---- Getters calculados para UI ----

  String get titulo => categoriaNombre ?? 'Imprevisto';

  String get subtitulo {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  IconData get icono => _getIconForCategory(categoriaNombre ?? '');

  Color get color => AppColors.error;

  static IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Salud':
        return Icons.medical_services;
      case 'Hogar':
        return Icons.home_repair_service;
      case 'Vehículo':
        return Icons.directions_car;
      case 'Emergencia':
        return Icons.emergency;
      case 'Mascota':
        return Icons.pets;
      case 'Otros':
        return Icons.report_problem;
      default:
        return Icons.warning_amber_rounded;
    }
  }
}
