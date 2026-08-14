import 'package:flutter/material.dart';

class GastoModel {
  final String titulo;
  final String subtitulo;
  final String description;
  final double monto;
  final IconData icono;
  final Color color;
  final DateTime fecha;
  final String categoriaNombre;
  final String responsableNombre;

  GastoModel({
    required this.titulo,
    required this.subtitulo,
    required this.description,
    required this.monto,
    required this.icono,
    required this.color,
    required this.fecha,
    required this.categoriaNombre,
    required this.responsableNombre,
  });
}
