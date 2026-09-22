import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/categoria_model.dart';
import 'auth_service.dart';

class CategoriasService {
  static const String _baseUrl = 'https://ahorrapp-react-pkj9.onrender.com/api';

  CategoriasService();

  // ============================================================
  // HEADERS
  // ============================================================

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getToken();

    debugPrint(
      '🔑 Token leído: '
      '${token == null ? "NULL" : "(${token.length} chars)"}',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('⚠️ NO se agregó Authorization (token null o vacío)');
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

  List<Map<String, dynamic>> _procesarLista(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _obtenerMensajeError(decoded) ?? 'Error HTTP ${response.statusCode}',
      );
    }

    if (decoded is List) {
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

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
    return data.map((json) => CategoriaModel.fromJson(json)).toList();
  }

  static Future<List<CategoriaModel>> obtenerCategorias() {
    return CategoriasService().getCategorias();
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
  // CREAR
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
  // EDITAR
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
  // DESHABILITAR / HABILITAR
  // ============================================================

  Future<Map<String, dynamic>> deshabilitarCategoria(int id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/categorias/$id/deshabilitar'),
      headers: await _headers(),
    );
    return _procesarRespuesta(response);
  }

  Future<Map<String, dynamic>> habilitarCategoria(int id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/categorias/$id/habilitar'),
      headers: await _headers(),
    );
    return _procesarRespuesta(response);
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  Future<Map<String, dynamic>> eliminarCategoria(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/categorias/$id'),
      headers: await _headers(),
    );
    return _procesarRespuesta(response);
  }

  // ============================================================
  // RESPUESTAS CRUD
  // ============================================================

  Map<String, dynamic> _procesarRespuesta(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _obtenerMensajeError(decoded) ?? 'Error HTTP ${response.statusCode}',
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'ok': true, 'data': decoded};
  }

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