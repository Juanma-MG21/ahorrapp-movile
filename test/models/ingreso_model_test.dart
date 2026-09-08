import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/models/ingreso_model.dart';

void main() {
  final tFecha = DateTime(2023, 10, 5);
  final tIngresoJson = {
    'id': 10,
    'id_categoria': 5,
    'monto': 2000.0,
    'descripcion': 'Pago quincena',
    'fuente': 'Empresa X',
    'fecha': tFecha.toIso8601String(),
    'categoria': 'Salario'
  };

  group('IngresoModel', () {
    test('fromJson debe crear una instancia válida', () {
      final model = IngresoModel.fromJson(tIngresoJson);

      expect(model.id, 10);
      expect(model.monto, 2000.0);
      expect(model.categoriaNombre, 'Salario');
    });

    test('toRequestBody debe generar el mapa correcto', () {
      final model = IngresoModel(
        monto: 2000.0,
        fechaRegistro: tFecha,
        fuente: 'Empresa X',
        idCategoria: 5,
      );

      final body = model.toRequestBody();

      expect(body['monto'], 2000.0);
      expect(body['fuente'], 'Empresa X');
      expect(body['fecha_registro'], '2023-10-05');
    });

    test('getters de UI deben ser correctos', () {
      final model = IngresoModel(
        monto: 100.0,
        fechaRegistro: tFecha,
        categoriaNombre: 'Inversión',
        fuente: 'Cripto',
      );

      expect(model.titulo, 'Inversión');
      expect(model.icono, Icons.trending_up);
      expect(model.color, const Color(0xFF60A5FA));
      expect(model.subtitulo, contains('Cripto'));
    });
  });
}
