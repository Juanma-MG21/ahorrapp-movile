import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/categoria_model.dart';

class CategoriasService {
  static const String _baseUrl =
      'https://ahorrapp-react-pkj9.onrender.com/api';

  final FlutterSecureStorage _storage;

  CategoriasService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  // ============================================================
  // HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // GET
  // ============================================================

  Future<List<Map<String, dynamic>>> _getLista(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );

    return _procesarLista(response);
  }

  // ============================================================
  // PROCESAR LISTAS
  // ============================================================

  List<Map<String, dynamic>> _procesarLista(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _obtenerMensajeError(decoded) ??
            'Error HTTP ${response.statusCode}',
      );
    }

    // Caso:
    // [
    //   {...},
    //   {...}
    // ]
    if (decoded is List) {
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    // Caso:
    // {
    //   "data": [...]
    // }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is List) {
        return data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      final categorias = decoded['categorias'];

      if (categorias is List) {
        return categorias
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // CATEGORÍAS
  // ============================================================

Future<List<CategoriaModel>> getCategorias() async {
  final data = await _getLista('/categorias');

  return data
      .map((json) => CategoriaModel.fromJson(json))
      .toList();
}

  // ============================================================
  // MOVIMIENTOS POR CATEGORÍA
  // ============================================================

  Future<List<Map<String, dynamic>>> getGastosPorCategoria() async {
    return _getLista('/categorias/gastos');
  }

  Future<List<Map<String, dynamic>>> getIngresosPorCategoria() async {
    return _getLista('/categorias/ingresos');
  }

  Future<List<Map<String, dynamic>>> getAhorrosPorCategoria() async {
    return _getLista('/categorias/ahorros');
  }

  Future<List<Map<String, dynamic>>> getImprevistosPorCategoria() async {
    return _getLista('/categorias/imprevistos');
  }

  Future<List<Map<String, dynamic>>> getDeudasPorCategoria() async {
    return _getLista('/categorias/deudas');
  }

  // ============================================================
  // CREAR CATEGORÍA
  // ============================================================

  Future<Map<String, dynamic>> crearCategoria({
    required String nombre,
    required String descripcion,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/categorias'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
      }),
    );

    return _procesarRespuesta(response);
  }

  // ============================================================
  // EDITAR CATEGORÍA
  // ============================================================

  Future<Map<String, dynamic>> editarCategoria(
    int id, {
    required String nombre,
    required String? descripcion,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/categorias/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
      }),
    );

    return _procesarRespuesta(response);
  }

  // ============================================================
  // DESHABILITAR
  // ============================================================

  Future<Map<String, dynamic>> deshabilitarCategoria(
    int id,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/categorias/$id/deshabilitar',
      ),
      headers: await _headers(),
    );

    return _procesarRespuesta(response);
  }

  // ============================================================
  // HABILITAR
  // ============================================================

  Future<Map<String, dynamic>> habilitarCategoria(
    int id,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$_baseUrl/categorias/$id/habilitar',
      ),
      headers: await _headers(),
    );

    return _procesarRespuesta(response);
  }

  // ============================================================
  // PROCESAR RESPUESTAS CRUD
  // ============================================================

  Map<String, dynamic> _procesarRespuesta(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _obtenerMensajeError(decoded) ??
            'Error HTTP ${response.statusCode}',
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {
      'ok': true,
      'data': decoded,
    };
  }

  // ============================================================
  // OBTENER MENSAJE DE ERROR
  // ============================================================

  String? _obtenerMensajeError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final mensaje = decoded['mensaje'] ?? decoded['message'];

      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    }

    return null;
  }
}