import 'package:flutter/material.dart';

class GastoModel {
  final int? id;
  final int? idSalida;
  final int? idCategoria;
  final int? idDependientes;
  final double monto;
  final String description;
  final DateTime fecha;
  
  // Campos auxiliares para la UI (traídos por join)
  final String categoriaNombre;
  final String responsableNombre;
  final IconData icono;
  final Color color;

  GastoModel({
    this.id,
    this.idSalida,
    this.idCategoria,
    this.idDependientes,
    required this.monto,
    required this.description,
    required this.fecha,
    this.categoriaNombre = 'General',
    this.responsableNombre = 'Gasto propio',
    this.icono = Icons.shopping_cart,
    this.color = Colors.grey,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'id_salida': idSalida,
      'id_categoria': idCategoria,
      'id_dependientes': idDependientes,
      'monto': monto,
      'descripcion': description,
      'fecha_registro': fecha.toIso8601String().split('T')[0], // YYYY-MM-DD para DATE en Postgres
    };
  }

  factory GastoModel.fromMap(Map<String, dynamic> map) {
    // Mapeo de iconos/colores estáticos para la UI basado en el nombre de la categoría
    // (En una fase posterior esto podría estar en la tabla categorias)
    final catNombre = map['categorias']?['nombre'] ?? map['categoria_nombre'] ?? 'General';
    
    return GastoModel(
      id: map['id_gastos'],
      idSalida: map['id_salida'],
      idCategoria: map['id_categoria'],
      idDependientes: map['id_dependientes'],
      monto: (map['monto'] as num).toDouble(),
      description: map['descripcion'] ?? '',
      fecha: DateTime.parse(map['fecha_registro']),
      categoriaNombre: catNombre,
      responsableNombre: map['dependientes']?['nombre'] ?? map['responsable_nombre'] ?? 'Gasto propio',
      icono: _getIconForCategory(catNombre),
      color: _getColorForCategory(catNombre),
    );
  }

  static IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación': return Icons.restaurant;
      case 'Transporte': return Icons.directions_bus;
      case 'Salud': return Icons.medical_services;
      case 'Educación': return Icons.school;
      case 'Entretenimiento': return Icons.movie;
      case 'Servicios': return Icons.home;
      case 'Ropa': return Icons.checkroom;
      default: return Icons.shopping_cart;
    }
  }

  static Color _getColorForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación': return const Color(0xFFA8A2FF);
      case 'Transporte': return const Color(0xFF60A5FA);
      case 'Salud': return const Color(0xFFFF6B6B);
      case 'Educación': return const Color(0xFF4ADE80);
      case 'Entretenimiento': return const Color(0xFFC084FC);
      case 'Servicios': return const Color(0xFFFF8C4A);
      case 'Ropa': return const Color(0xFF4ADE80);
      default: return const Color(0xFFFFB800);
    }
  }
  
  // Getter para compatibilidad con la UI actual que usa 'titulo' y 'subtitulo'
  String get titulo => categoriaNombre;
  String get subtitulo => '$responsableNombre • ${_formatDate(fecha)}';

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
