import '../core/network/api_client.dart';
import '../models/dependiente_model.dart';
import 'auth_service.dart';

class DependientesService {
  static const _api = ApiClient();

  // Delega en AuthService, que ya consulta memoria o storage
  // según corresponda, con la clave correcta ('auth_token').
  static Future<String?> _token() async {
    return AuthService.instance.getToken();
  }

  // ✅ El endpoint /dependientes devuelve un array plano, no un
  //    objeto { ok, dependientes: [...] }. Por eso usamos getList()
  //    en lugar de get().
  static Future<List<DependienteModel>> getDependientes() async {
    final data = await _api.getList('/dependientes', token: await _token());

    return data
        .map((item) => DependienteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<int> crearDependiente(DependienteModel dependiente) async {
  final body = dependiente.toJson();
  print('📤 POST /dependientes → $body');   // ← añade esto

  final data = await _api.post(
    '/dependientes',
    body: body,
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