import 'package:flutter/material.dart';
import '../core/utils/parsers.dart';

class GastoModel {
  final int? id;
  final int? idCategoria;
  final int? idDependientes;
  final double monto;
  final String? descripcion;
  final DateTime fecha;

  // Solo vienen poblados al listar (GET /movimientos/gastos), gracias
  // al JOIN que hace el backend con categorias y dependientes.
  final String? categoriaNombre;
  final String? dependienteNombre;

  GastoModel({
    this.id,
    this.idCategoria,
    this.idDependientes,
    required this.monto,
    this.descripcion,
    required this.fecha,
    this.categoriaNombre,
    this.dependienteNombre,
  });

  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id'],
      idCategoria: json['id_categoria'],
      idDependientes: json['id_dependientes'],
      monto: parseMonto(json['monto']),
      descripcion: json['descripcion'],
      fecha: DateTime.parse(json['fecha']),
      categoriaNombre: json['categoria'],
      dependienteNombre: json['dependiente'],
    );
  }


  /// Body para POST /movimientos (dentro de "datos") y para
  /// PUT /movimientos/gastos/:id. Ambos endpoints esperan las mismas
  /// claves.
  Map<String, dynamic> toRequestBody() {
    return {
      'monto': monto,
      'descripcion': descripcion,
      'fecha_registro': fecha.toIso8601String().split('T')[0],
      'id_categoria': idCategoria,
      'id_dependientes': idDependientes,
    };
  }

  // Getters calculados para UI (NO vienen del backend).
  String get titulo => categoriaNombre ?? 'General';
  String get description => descripcion ?? 'Sin descripción';
  String get responsableNombre => dependienteNombre ?? 'Gasto propio';

  String get subtitulo {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$responsableNombre • $dd/$mm/${fecha.year}';
  }

  IconData get icono => _getIconForCategory(categoriaNombre ?? '');
  Color get color => _getColorForCategory(categoriaNombre ?? '');

  static IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_bus;
      case 'Salud':
        return Icons.medical_services;
      case 'Educación':
        return Icons.school;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Servicios':
        return Icons.home;
      case 'Ropa':
        return Icons.checkroom;
      default:
        return Icons.shopping_cart;
    }
  }

  static Color _getColorForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación':
        return const Color(0xFFA8A2FF);
      case 'Transporte':
        return const Color(0xFF60A5FA);
      case 'Salud':
        return const Color(0xFFFF6B6B);
      case 'Educación':
        return const Color(0xFF4ADE80);
      case 'Entretenimiento':
        return const Color(0xFFC084FC);
      case 'Servicios':
        return const Color(0xFFFF8C4A);
      case 'Ropa':
        return const Color(0xFF4ADE80);
      default:
        return const Color(0xFFFFB800);
    }
  }
}