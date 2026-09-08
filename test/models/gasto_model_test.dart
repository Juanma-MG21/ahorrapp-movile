import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/models/gasto_model.dart';

void main() {
  final tFecha = DateTime(2023, 10, 1);
  final tGastoJson = {
    'id': 1,
    'id_categoria': 2,
    'id_dependientes': 3,
    'monto': "150.75",
    'descripcion': 'Cena familiar',
    'fecha': tFecha.toIso8601String(),
    'categoria': 'Alimentación',
    'dependiente': 'Hijo'
  };

  group('GastoModel', () {
    test('fromJson debe crear una instancia válida', () {
      final model = GastoModel.fromJson(tGastoJson);

      expect(model.id, 1);
      expect(model.monto, 150.75);
      expect(model.categoriaNombre, 'Alimentación');
      expect(model.dependienteNombre, 'Hijo');
    });

    test('toRequestBody debe generar el mapa correcto para el backend', () {
      final model = GastoModel(
        idCategoria: 2,
        idDependientes: 3,
        monto: 150.75,
        descripcion: 'Cena familiar',
        fecha: tFecha,
      );

      final body = model.toRequestBody();

      expect(body['monto'], 150.75);
      expect(body['id_categoria'], 2);
      expect(body['fecha_registro'], '2023-10-01');
    });

    test('getters de UI deben devolver valores coherentes', () {
      final model = GastoModel(
        monto: 50.0,
        fecha: tFecha,
        categoriaNombre: 'Transporte',
        dependienteNombre: 'Esposa',
      );

      expect(model.titulo, 'Transporte');
      expect(model.responsableNombre, 'Esposa');
      expect(model.icono, Icons.directions_bus);
      expect(model.color, const Color(0xFF60A5FA));
      expect(model.subtitulo, contains('Esposa'));
      expect(model.subtitulo, contains('01/10/2023'));
    });

    test('debe usar valores por defecto cuando los campos son nulos', () {
      final model = GastoModel(monto: 10.0, fecha: tFecha);

      expect(model.titulo, 'General');
      expect(model.responsableNombre, 'Gasto propio');
      expect(model.icono, Icons.shopping_cart);
    });
  });
}
