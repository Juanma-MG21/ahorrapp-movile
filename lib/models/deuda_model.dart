import 'package:flutter/material.dart';
import '../core/utils/parsers.dart';

class DeudaModel {
  final int? id;
  final int? idSalida;
  final int? idCategoria;
  final double monto;
  final String fuente;
  final String? descripcion;
  final double tasaInteres; // RF-06: No puede ser negativa
  final int? cuotasTotal;
  final int cuotasPagadas;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado; // 'pendiente', 'pagada'

  DeudaModel({
    this.id,
    this.idSalida,
    this.idCategoria,
    required this.monto,
    required this.fuente,
    this.descripcion,
    this.tasaInteres = 0.0,
    this.cuotasTotal,
    this.cuotasPagadas = 0,
    this.fechaInicio,
    this.fechaFin,
    this.estado = 'pendiente',
  });

  factory DeudaModel.fromJson(Map<String, dynamic> json) {
    return DeudaModel(
      id: json['id_deudas'] ?? json['id'],
      idSalida: json['id_salida'],
      idCategoria: json['id_categoria'],
      monto: parseMonto(json['monto'] ?? 0),
      fuente: json['fuente'] ?? 'Desconocido',
      descripcion: json['descripcion'],
      tasaInteres: parseMonto(json['tasa_interes'] ?? 0),
      cuotasTotal: json['cuotas_total'],
      cuotasPagadas: json['cuotas_pagadas'] ?? 0,
      fechaInicio: json['fecha_inicio'] != null ? DateTime.parse(json['fecha_inicio']) : null,
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      estado: json['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toRequestBody() {
    return {
      'monto': monto,
      'fuente': fuente,
      'descripcion': descripcion,
      'tasa_interes': tasaInteres,
      'cuotas_total': cuotasTotal,
      'cuotas_pagadas': cuotasPagadas,
      'fecha_inicio': fechaInicio?.toIso8601String().split('T')[0],
      'fecha_fin': fechaFin?.toIso8601String().split('T')[0],
      'id_categoria': idCategoria,
      'estado': estado,
    };
  }

  // Getters para UI
  double get progresoCuotas => (cuotasTotal != null && cuotasTotal! > 0)
      ? (cuotasPagadas / cuotasTotal!).clamp(0.0, 1.0)
      : 0.0;

  double get montoRestante => monto - (monto * progresoCuotas);

  String get cuotasTexto => cuotasTotal != null 
      ? '$cuotasPagadas de $cuotasTotal cuotas' 
      : 'Sin cuotas definidas';

  IconData get icono => Icons.credit_card;
  Color get color => const Color(0xFFFF6B6B); // AppColors.error para deudas
}
