import 'package:flutter/material.dart';

class IngresoModel {
  final int? id;
  final int? idEntrada;
  final int? idCategoria;
  final double monto;
  final String? descripcion;
  final String? fuente;
  final DateTime fechaRegistro;
  
  // Campos auxiliares para la UI
  final String categoriaNombre;
  final IconData icono;
  final Color color;

  IngresoModel({
    this.id,
    this.idEntrada,
    this.idCategoria,
    required this.monto,
    this.descripcion,
    this.fuente,
    required this.fechaRegistro,
    this.categoriaNombre = 'General',
    this.icono = Icons.account_balance_wallet,
    this.color = Colors.green,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'id_entrada': idEntrada,
      'id_categoria': idCategoria,
      'monto': monto,
      'descripcion': descripcion,
      'fuente': fuente,
      'fecha_registro': fechaRegistro.toIso8601String().split('T')[0],
    };
  }

  factory IngresoModel.fromMap(Map<String, dynamic> map) {
    final catNombre = map['categorias']?['nombre'] ?? map['categoria_nombre'] ?? 'General';
    
    return IngresoModel(
      id: map['id_ingresos'],
      idEntrada: map['id_entrada'],
      idCategoria: map['id_categoria'],
      monto: (map['monto'] as num).toDouble(),
      descripcion: map['descripcion'],
      fuente: map['fuente'],
      fechaRegistro: DateTime.parse(map['fecha_registro']),
      categoriaNombre: catNombre,
      icono: _getIconForCategory(catNombre),
      color: _getColorForCategory(catNombre),
    );
  }

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
      // Compatibilidad con categorías de gastos
      case 'Alimentación': return Icons.restaurant;
      case 'Transporte': return Icons.directions_bus;
      case 'Salud': return Icons.medical_services;
      case 'Educación': return Icons.school;
      case 'Entretenimiento': return Icons.movie;
      case 'Servicios': return Icons.home;
      case 'Ropa': return Icons.checkroom;
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
      // Colores de gastos (para consistencia si se usan)
      case 'Alimentación': return const Color(0xFFA8A2FF);
      case 'Transporte': return const Color(0xFF60A5FA);
      case 'Salud': return const Color(0xFFFF6B6B);
      case 'Educación': return const Color(0xFF4ADE80);
      case 'Entretenimiento': return const Color(0xFFC084FC);
      case 'Servicios': return const Color(0xFFFF8C4A);
      case 'Ropa': return const Color(0xFF4ADE80);
      default: return const Color(0xFF2DD4BF);
    }
  }

  // Getters para compatibilidad con UI
  String get titulo => categoriaNombre;
  String get subtitulo => '${fuente ?? "Ingreso"} • ${_formatDate(fechaRegistro)}';

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
