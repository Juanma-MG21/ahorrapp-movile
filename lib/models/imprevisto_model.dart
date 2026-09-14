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
  final int? idDependientes;
  final String? dependienteNombre;

  ImprevistoModel({
    this.id,
    this.idCategoria,
    required this.monto,
    this.descripcion,
    required this.fecha,
    this.categoriaNombre,
    this.idDependientes,
    this.dependienteNombre,
  });

  /// Mapea una fila de GET /api/movimientos/imprevistos.
  /// OJO: el backend llama a este campo `causa` (columna real de la tabla
  /// `imprevistos`), no `descripcion` — antes se leía la clave equivocada
  /// y el texto siempre llegaba null.
  factory ImprevistoModel.fromJson(Map<String, dynamic> json) {
    return ImprevistoModel(
      id: json['id'],
      idCategoria: json['id_categoria'],
      monto: parseMonto(json['monto']),
      descripcion: json['causa'],
      fecha: DateTime.parse(json['fecha']),
      categoriaNombre: json['categoria'],
      idDependientes: json['id_dependientes'],
      dependienteNombre: json['dependiente'],
    );
  }

  /// Arma el objeto "datos" para POST /movimientos y PUT /movimientos/imprevistos/:id.
  /// El backend espera la clave `causa` (ver movimientosController.js,
  /// crearMovimiento/updateImprevistos: `const { monto, causa, ... } = ...`).
  /// Antes se mandaba 'descripcion', que el backend simplemente ignora al
  /// desestructurar el body, así que `causa` siempre se guardaba null.
  Map<String, dynamic> toRequestBody() {
    return {
      'monto': monto,
      'causa': descripcion,
      'fecha_registro': fecha.toIso8601String().split('T')[0],
      'id_categoria': idCategoria,
      'id_dependientes': idDependientes,
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
