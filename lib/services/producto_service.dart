import '../core/network/api_client.dart';
import '../models/producto_model.dart';

class ProductoService {
  Future<List<Producto>> getProductos() async {
    try {
      final response = await ApiClient.dio.get('/posts');
      
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Producto.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
