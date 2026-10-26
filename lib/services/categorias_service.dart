import '../core/network/api_client.dart';
import 'offline_query_service.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/categoria_model.dart';
import 'auth_service.dart';

class CategoriasService {
  static const String _baseUrl = 'https://ahorrapp-react.onrender.com/api';

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
    return OfflineQueryService.instance.query(
        '/categorias', const ApiClient(), CategoriaModel.fromJson,
        listKey: 'categorias');
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
    return _write((headers) async {
      final response = await http.post(
        Uri.parse('$_baseUrl/categorias'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
        }),
      );
      return response;
    });
  }

  // ============================================================
  // EDITAR
  // ============================================================

  Future<Map<String, dynamic>> editarCategoria(
    int id, {
    required String nombre,
    required String? descripcion,
  }) async {
    return _write((headers) async {
      final response = await http.put(
        Uri.parse('$_baseUrl/categorias/$id'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
        }),
      );
      return response;
    });
  }

  // ============================================================
  // DESHABILITAR / HABILITAR
  // ============================================================

  Future<Map<String, dynamic>> deshabilitarCategoria(int id) async {
    return _write((headers) async {
      final response = await http.patch(
        Uri.parse('$_baseUrl/categorias/$id/deshabilitar'),
        headers: headers,
      );
      return response;
    });
  }

  Future<Map<String, dynamic>> habilitarCategoria(int id) async {
    return _write((headers) async {
      final response = await http.patch(
        Uri.parse('$_baseUrl/categorias/$id/habilitar'),
        headers: headers,
      );
      return response;
    });
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  Future<Map<String, dynamic>> eliminarCategoria(int id) async {
    return _write((headers) async {
      final response = await http.delete(
        Uri.parse('$_baseUrl/categorias/$id'),
        headers: headers,
      );
      return response;
    });
  }

  // ============================================================
  // RESPUESTAS CRUD
  // ============================================================

  Future<Map<String, dynamic>> _write(
      Future<http.Response> Function(Map<String, String>) send) {
    return OfflineQueryService.instance.onlineMutation('/categorias',
        (token) async {
      final response = await send({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      final result = _procesarRespuesta(response);
      if (result['ok'] == false) {
        throw ApiException(
            _obtenerMensajeError(result) ?? 'No se guardó la categoría.');
      }
      return result;
    });
  }

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