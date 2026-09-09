import 'dart:convert';
// PRUEBA TODAVIA SE SIGUE TESTEANDO 
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/dependientes.dart';

// `class` que agrupa TODA la lógica de red relacionada a dependientes,
// separada de cualquier widget — es tu `api.js`, pero enfocado solo en
// este recurso. Así, si mañana `PanelDependientes`, un formulario de
// "editar dependiente" y un widget del dashboard necesitan los mismos
// datos, los tres llaman a esta misma clase en vez de repetir `http.get`
// por todas partes.
class DependientesService {
  // `static const` = el mismo valor para toda la app, no cambia por
  // instancia. Cámbialo aquí una sola vez cuando pases a producción,
  // o mejor, muévelo a un archivo de configuración por entorno
  // (ver mi nota sobre esto en tus mensajes anteriores).
  static const String _baseUrl = 'https://ahorrapp-react-pkj9.onrender.com/api';

  final FlutterSecureStorage _storage;

  // Constructor que RECIBE el storage en vez de crearlo internamente
  // (a esto se le llama "inyección de dependencias"): así, en tests,
  // puedes pasarle un storage falso sin tocar el código real.
  // `FlutterSecureStorage()` se usa como valor por defecto si no
  // pasas nada.
  DependientesService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  // Método privado (el `_` inicial) reutilizado por todos los
  // requests: arma los headers con el token, igual que el
  // interceptor centralizado que tenías en `api.js`.
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Authorization': 'Bearer $token',
      // Necesario en POST/PUT para que Express/body-parser entienda
      // que el body viene en JSON.
      'Content-Type': 'application/json',
    };
  }

  // ── LEER TODOS ──────────────────────────────────────────────────
  // Este SÍ está confirmado: es el mismo endpoint que ya vimos
  // funcionando en PanelDependientes.jsx.
  Future<List<Dependiente>> getDependientes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/PanelDependientes'),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] != true) {
      // Lanzar una `Exception` es el equivalente Dart de tu
      // `throw new Error(...)`; quien llame a este método debe
      // envolverlo en un try/catch (como hicimos en la pantalla).
      throw Exception(data['mensaje'] as String? ?? 'No se pudieron obtener los dependientes');
    }

    return (data['dependientes'] as List<dynamic>)
        .map((item) => Dependiente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── CREAR ────────────────────────────────────────────────────────
  // ⚠️ Ruta y forma de la respuesta ASUMIDAS por convención REST
  // (POST /api/dependientes). No la vi en tu código — confírmame la
  // ruta real de tu backend y ajusto esto en un segundo.
  Future<Dependiente> crearDependiente({
    required int idUsuario,
    required String nombre,
    String? relacion,
    String? ocupacion,
    DateTime? fechaNacimiento,
    int? pesoEconomico,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/dependientes'),
      headers: await _authHeaders(),
      // El backend espera un JSON en el body, no un Map de Dart
      // directo — por eso `jsonEncode` lo convierte a texto antes
      // de mandarlo, igual que harías con `JSON.stringify(body)` en JS.
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nombre': nombre,
        'relacion': relacion,
        'ocupacion': ocupacion,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'peso_economico': pesoEconomico,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] != true) {
      throw Exception(data['mensaje'] as String? ?? 'No se pudo crear el dependiente');
    }

    return Dependiente.fromJson(data['dependiente'] as Map<String, dynamic>);
  }

  // ── ACTUALIZAR ───────────────────────────────────────────────────
  // ⚠️ Misma advertencia: ruta asumida (PUT /api/dependientes/:id).
  Future<void> actualizarDependiente(Dependiente dependiente) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/dependientes/${dependiente.idDependientes}'),
      headers: await _authHeaders(),
      body: jsonEncode(dependiente.toJson()),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] != true) {
      throw Exception(data['mensaje'] as String? ?? 'No se pudo actualizar el dependiente');
    }
  }

  // ── ELIMINAR ─────────────────────────────────────────────────────
  // ⚠️ Misma advertencia: ruta asumida (DELETE /api/dependientes/:id).
  Future<void> eliminarDependiente(int idDependientes) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/dependientes/$idDependientes'),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['ok'] != true) {
      throw Exception(data['mensaje'] as String? ?? 'No se pudo eliminar el dependiente');
    }
  }
}