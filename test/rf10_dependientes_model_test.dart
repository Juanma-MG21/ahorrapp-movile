import 'package:flutter_test/flutter_test.dart';
import 'package:ahorrapp_movil/models/dependiente_model.dart';

void main() {
  DependienteModel model({
    String nombre = '  Ana  ',
    String? relacion = ' Hija ',
    int? peso = 3,
  }) =>
      DependienteModel(
        nombre: nombre,
        relacion: relacion,
        ocupacion: ' Estudiante ',
        fechaNacimiento: DateTime(2010, 1, 2),
        pesoEconomico: peso,
      );

  test('valida campos requeridos y peso económico 1 a 5', () {
    expect(model().validationError, isNull);
    expect(model(nombre: '  ').validationError, isNotNull);
    expect(model(relacion: ' ').validationError, isNotNull);
    for (final peso in [null, 0, 6]) {
      expect(model(peso: peso).validationError, isNotNull);
    }
    for (final peso in [1, 5]) {
      expect(model(peso: peso).validationError, isNull);
    }
  });

  test('serializa texto limpio y fecha sin desplazamiento de zona horaria', () {
    expect(model().toJson(), {
      'Nombre': 'Ana',
      'Relacion': 'Hija',
      'Ocupacion': 'Estudiante',
      'Fecha_nacimiento': '2010-01-02',
      'Peso_economico': 3,
    });
  });

  test('lee el identificador tanto de la respuesta plana como de la anidada',
      () {
    expect(DependienteModel.parseCreatedId({'id_dependientes': 17}), 17);
    expect(
        DependienteModel.parseCreatedId({
          'dependiente': {'id_dependientes': 18}
        }),
        18);
    expect(DependienteModel.parseCreatedId({'id_dependientes': 0}), isNull);
    expect(DependienteModel.parseCreatedId({}), isNull);
  });
}
