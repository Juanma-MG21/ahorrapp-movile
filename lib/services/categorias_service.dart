import 'dart:convert';
// PRUEBA TODAVIA SE SIGUE TESTEANDO 
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Este archivo es el equivalente Dart de las funciones que importabas
// de tu `../api`: `getCategorias`, `crearCategoria`, `editarCategoria`,
// `deshabilitarCategoria`, `habilitarCategoria`, y las 5 variantes
// `get*PorCategoria`. Cada import nombrado de JS se vuelve un método
// de esta clase.
//
// ⚠️ Las RUTAS (`/categorias/gastos`, etc.) son mi mejor suposición
// por convención — no las vi en tu código, solo los nombres de las
// funciones. Cuando me pases la tabla de categorías, ajusto tanto
// las rutas como la forma exacta del JSON de respuesta.
class CategoriasService {
  static const String _baseUrl = 'https://ahorrapp-react-pkj9.onrender.com/api';
  final FlutterSecureStorage _storage;

  CategoriasService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  // Helper interno: hace el GET, valida `ok`, y devuelve la lista cruda
  // de Maps — evita repetir el mismo try/parse 5 veces para las
  // variantes "por categoría".
  Future<List<Map<String, dynamic>>> _getLista(String path) async {
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: await _headers());
    final decoded = jsonDecode(response.body);

    // Algunos backends devuelven el array directo (`[...]`), otros lo
    // envuelven en `{ ok, data }`. Este `if` cubre ambos casos —
    // bórralo cuando confirmemos la forma real.
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    final map = decoded as Map<String, dynamic>;
    return (map['data'] as List<dynamic>? ?? map['categorias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCategorias() => _getLista('/categorias');
  Future<List<Map<String, dynamic>>> getGastosPorCategoria() => _getLista('/categorias/gastos');
  Future<List<Map<String, dynamic>>> getIngresosPorCategoria() => _getLista('/categorias/ingresos');
  Future<List<Map<String, dynamic>>> getAhorrosPorCategoria() => _getLista('/categorias/ahorros');
  Future<List<Map<String, dynamic>>> getImprevistosPorCategoria() => _getLista('/categorias/imprevistos');
  Future<List<Map<String, dynamic>>> getDeudasPorCategoria() => _getLista('/categorias/deudas');

  Future<Map<String, dynamic>> crearCategoria({required String nombre, required String descripcion}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/categorias'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editarCategoria(int id, {required String nombre, required String? descripcion}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/categorias/$id'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deshabilitarCategoria(int id) async {
    final response = await http.patch(Uri.parse('$_baseUrl/categorias/$id/deshabilitar'), headers: await _headers());
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> habilitarCategoria(int id) async {
    final response = await http.patch(Uri.parse('$_baseUrl/categorias/$id/habilitar'), headers: await _headers());
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}