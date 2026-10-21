import '../core/network/api_client.dart';
import '../models/dependiente_model.dart';
import 'offline_query_service.dart';
import 'package:flutter/foundation.dart';

class DependientesService {
  @visibleForTesting
  static ApiClient client = const ApiClient();

  static Future<List<DependienteModel>> getDependientes() {
    return OfflineQueryService.instance
        .query('/dependientes', client, DependienteModel.fromJson);
  }

  static Future<int> crearDependiente(DependienteModel dependiente) {
    final error = dependiente.validationError;
    if (error != null) throw ApiException(error);
    return OfflineQueryService.instance.onlineMutation('/dependientes',
        (token) async {
      final data = await client.post('/dependientes',
          body: dependiente.toJson(), token: token);

      final id = DependienteModel.parseCreatedId(data);
      if (id == null) {
        throw ApiException(
            'El servidor no devolvió un identificador de dependiente válido');
      }
      return id;
    });
  }

  static Future<void> actualizarDependiente(
      int id, DependienteModel dependiente) async {
    final error = dependiente.validationError;
    if (error != null) throw ApiException(error);
    await OfflineQueryService.instance.onlineMutation(
        '/dependientes',
        (token) => client.put('/dependientes/$id',
            body: dependiente.toJson(), token: token));
  }

  static Future<void> eliminarDependiente(int idDependientes) async {
    await OfflineQueryService.instance.onlineMutation(
        '/dependientes',
        (token) =>
            client.delete('/dependientes/$idDependientes', token: token));
  }
}
