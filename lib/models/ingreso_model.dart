import 'package:flutter/material.dart';
import '../core/utils/parsers.dart';

class IngresoModel {
  final int? id;
  final int? idCategoria;
  final double monto;
  final String? descripcion;
  final String? fuente;
  final DateTime fechaRegistro;
  final String? categoriaNombre; // solo viene poblado al listar (GET), no al crear/editar

  IngresoModel({
    this.id,
    this.idCategoria,
    required this.monto,
    this.descripcion,
    this.fuente,
    required this.fechaRegistro,
    this.categoriaNombre,
  });

  /// Mapea una fila de GET /api/movimientos/ingresos.
  factory IngresoModel.fromJson(Map<String, dynamic> json) {
    return IngresoModel(
      id: json['id'],
      idCategoria: json['id_categoria'],
      monto: parseMonto(json['monto']),
      descripcion: json['descripcion'],
      fuente: json['fuente'],
      fechaRegistro: DateTime.parse(json['fecha']),
      categoriaNombre: json['categoria'],
    );
  }

  /// Arma el objeto "datos" que piden POST /movimientos y
  /// PUT /movimientos/ingresos/:id (mismos campos en ambos).
  Map<String, dynamic> toRequestBody() {
    return {
      'monto': monto,
      'descripcion': descripcion,
      'fuente': fuente,
      'fecha_registro': fechaRegistro.toIso8601String().split('T')[0],
      'id_categoria': idCategoria,
    };
  }

  // ---- Getters calculados para UI (no vienen del backend) ----
  // Se derivan de categoriaNombre para no duplicar datos.

  String get titulo => categoriaNombre ?? 'General';

  String get subtitulo {
    final dd = fechaRegistro.day.toString().padLeft(2, '0');
    final mm = fechaRegistro.month.toString().padLeft(2, '0');
    return '${fuente ?? "Ingreso"} • $dd/$mm/${fechaRegistro.year}';
  }

  IconData get icono => _getIconForCategory(categoriaNombre ?? '');

  Color get color => _getColorForCategory(categoriaNombre ?? '');

  static IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Salario': return Icons.payments;
      case 'Venta': return Icons.sell;
      case 'Regalo': return Icons.card_giftcard;
      case 'Inversión': return Icons.trending_up;
      case 'Bonificación': return Icons.redeem;
      case 'Reembolso': return Icons.settings_backup_restore;
      case 'Honorarios': return Icons.work;
      case 'Arriendo': return Icons.apartment;
      case 'Otros': return Icons.more_horiz;
      default: return Icons.account_balance_wallet;
    }
  }

  static Color _getColorForCategory(String nombre) {
    switch (nombre) {
      case 'Salario': return const Color(0xFF4ADE80);
      case 'Venta': return const Color(0xFF34D399);
      case 'Regalo': return const Color(0xFFF472B6);
      case 'Inversión': return const Color(0xFF60A5FA);
      case 'Bonificación': return const Color(0xFFFBBF24);
      case 'Reembolso': return const Color(0xFFA8A2FF);
      case 'Honorarios': return const Color(0xFFC084FC);
      case 'Arriendo': return const Color(0xFFFF8C4A);
      case 'Otros': return const Color(0xFF94A3B8);
      default: return const Color(0xFF2DD4BF);
    }
  }
}