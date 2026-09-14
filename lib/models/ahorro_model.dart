import 'package:flutter/material.dart';
import '../core/utils/parsers.dart';

class AhorroModel {
  final int? id;
  final String nombre;
  final double montoObjetivo;
  final double montoActual;
  final DateTime? fechaLimite;
  final String? descripcion;
  final int? idCategoria;
  final String estado; // 'Activo', 'Finalizado'
  // Fecha de creación de la meta (columna fecha_registro de `ahorros`,
  // que GET /movimientos/ahorros expone como "fecha"). No se estaba
  // leyendo antes, aunque el backend siempre la devuelve.
  final DateTime? fechaRegistro;

  AhorroModel({
    this.id,
    required this.nombre,
    required this.montoObjetivo,
    this.montoActual = 0.0,
    this.fechaLimite,
    this.descripcion,
    this.idCategoria,
    this.estado = 'Activo',
    this.fechaRegistro,
  });

  factory AhorroModel.fromJson(Map<String, dynamic> json) {
    return AhorroModel(
      id: json['id_ahorros'] ?? json['id'] ?? json['ID_detalle'],
      nombre: json['meta'] ?? json['nombre'] ?? json['categoria'] ?? 'Sin nombre',
      montoObjetivo: parseMonto(json['monto'] ?? json['monto_objetivo'] ?? json['objetivo'] ?? 0),
      montoActual: parseMonto(json['monto_acumulado'] ?? 
                             json['monto_actual'] ?? 
                             json['actual'] ?? 
                             json['saldo'] ?? 
                             json['monto_ahorrado'] ??
                             json['ahorrado'] ?? 0),
      fechaLimite: (json['fecha_meta'] ?? json['fecha_limite'] ?? json['fecha_finalizacion']) != null 
          ? DateTime.parse((json['fecha_meta'] ?? json['fecha_limite'] ?? json['fecha_finalizacion']).toString()) 
          : null,
      descripcion: json['descripcion'],
      idCategoria: json['id_categoria'],
      estado: json['estado'] ?? 'Activo',
      fechaRegistro: json['fecha'] != null ? DateTime.tryParse(json['fecha'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meta': nombre,
      'monto': montoObjetivo,
      'monto_acumulado': montoActual,
      'fecha_meta': fechaLimite?.toIso8601String().split('T')[0],
      'fecha_registro': DateTime.now().toIso8601String().split('T')[0],
      'descripcion': descripcion,
      'id_categoria': idCategoria,
      'estado': estado,
    };
  }

  double get progreso => montoObjetivo > 0 
      ? (montoActual / montoObjetivo).clamp(0.0, 1.0) 
      : 0.0;

  double get restante => (montoObjetivo - montoActual).clamp(0.0, double.infinity);

  IconData get icono => Icons.savings_outlined;
  Color get color => Colors.purple;
}
