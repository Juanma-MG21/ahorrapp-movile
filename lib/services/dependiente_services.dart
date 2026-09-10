import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/api_client.dart';
import '../models/dependiente_model.dart';

class DependientesService {
  static const _api = ApiClient();

  static Future<String?> _token() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: 'token');
  }

  static Future<List<DependienteModel>> getDependientes() async {
    final data = await _api.get('/auth/PanelDependientes', token: await _token());

    return (data['dependientes'] as List<dynamic>)
        .map((item) => DependienteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<int> crearDependiente(DependienteModel dependiente) async {
    final data = await _api.post(
      '/dependientes',
      body: dependiente.toJson(),
      token: await _token(),
    );

    return data['dependiente']['id_dependientes'] as int;
  }

  static Future<void> actualizarDependiente(
    int id,
    DependienteModel dependiente,
  ) async {
    await _api.put(
      '/dependientes/$id',
      body: dependiente.toJson(),
      token: await _token(),
    );
  }

  static Future<void> eliminarDependiente(int idDependientes) async {
    await _api.delete('/dependientes/$idDependientes', token: await _token());
  }
}