import '../core/network/api_client.dart';
import '../models/ingreso_model.dart';
import '../models/categoria_model.dart';
import 'auth_service.dart';

class IngresosService {
  static final ApiClient _client = ApiClient();

  /// Crea un ingreso nuevo (POST /movimientos).
  /// Devuelve el id generado (id_ingresos) para que la pantalla pueda
  /// armar el IngresoModel completo localmente.
  static Future<int> crearIngreso(IngresoModel ingreso) async {
    final token = await AuthService.instance.getToken();

    final respuesta = await _client.post(
      '/movimientos',
      token: token,
      body: {
        'tipo_flujo': 'Entrada',
        'subtipo_modulo': 'Ingreso',
        'datos': ingreso.toRequestBody(),
      },
    );

    return respuesta['ID_detalle'] as int;
  }

  /// Actualiza un ingreso existente (PUT /movimientos/ingresos/:id).
  static Future<void> actualizarIngreso(int id, IngresoModel ingreso) async {
    final token = await AuthService.instance.getToken();

    await _client.put(
      '/movimientos/ingresos/$id',
      token: token,
      body: ingreso.toRequestBody(),
    );
  }

  /// Trae las categorías disponibles (GET /categorias).
  static Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final token = await AuthService.instance.getToken();
      final respuesta = await _client.get('/categorias', token: token);

      final List categorias = respuesta['categorias'] ?? [];
      return categorias
          .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Si falla, la pantalla simplemente no muestra categorías y el
      // usuario puede guardar el ingreso sin categoría.
      return [];
    }
  }
}