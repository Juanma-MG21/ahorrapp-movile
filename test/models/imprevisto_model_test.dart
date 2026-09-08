import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ahorrapp_movil/models/imprevisto_model.dart';
import 'package:ahorrapp_movil/core/theme/design_tokens.dart';

void main() {
  group('ImprevistoModel', () {
    final tFecha = DateTime(2026, 9, 7);
    final tJson = {
      'id': 1,
      'id_categoria': 2,
      'monto': '150000.00',
      'descripcion': 'Reparación techo',
      'fecha': '2026-09-07T00:00:00.000',
      'categoria': 'Hogar',
    };

    test('fromJson debe mapear correctamente los datos', () {
      final model = ImprevistoModel.fromJson(tJson);

      expect(model.id, 1);
      expect(model.idCategoria, 2);
      expect(model.monto, 150000.0);
      expect(model.descripcion, 'Reparación techo');
      expect(model.fecha, DateTime.parse('2026-09-07T00:00:00.000'));
      expect(model.categoriaNombre, 'Hogar');
    });

    test('toRequestBody debe generar el mapa correcto para el backend', () {
      final model = ImprevistoModel(
        id: 1,
        idCategoria: 2,
        monto: 150000.0,
        descripcion: 'Reparación techo',
        fecha: tFecha,
      );

      final body = model.toRequestBody();

      expect(body['monto'], 150000.0);
      expect(body['descripcion'], 'Reparación techo');
      expect(body['fecha_registro'], '2026-09-07');
      expect(body['id_categoria'], 2);
    });

    test('Getters de UI deben devolver valores coherentes', () {
      final model = ImprevistoModel(
        monto: 100,
        fecha: tFecha,
        categoriaNombre: 'Salud',
      );

      expect(model.titulo, 'Salud');
      expect(model.subtitulo, '07/09/2026');
      expect(model.icono, Icons.medical_services);
      expect(model.color, AppColors.error);
    });

    test('Getters de UI deben manejar categorías desconocidas', () {
      final model = ImprevistoModel(
        monto: 100,
        fecha: tFecha,
        categoriaNombre: 'Desconocida',
      );

      expect(model.titulo, 'Desconocida');
      expect(model.icono, Icons.warning_amber_rounded);
    });
  });
}
