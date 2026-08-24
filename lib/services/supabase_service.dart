import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gasto_model.dart';
import '../models/categoria_model.dart';
import '../models/dependiente_model.dart';

class SupabaseService {
  static final client = Supabase.instance.client;
  static const int defaultUserId = 1;

  // --- CATEGORÍAS ---
  static Future<List<CategoriaModel>> fetchCategorias() async {
    try {
      final response = await client
          .from('categorias')
          .select()
          .or('id_usuario.eq.$defaultUserId,es_global.eq.true');
      
      return (response as List).map((data) => CategoriaModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
      return [];
    }
  }

  // --- DEPENDIENTES ---
  static Future<List<DependienteModel>> fetchDependientes() async {
    try {
      final response = await client
          .from('dependientes')
          .select()
          .eq('id_usuario', defaultUserId);
      
      return (response as List).map((data) => DependienteModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error al obtener dependientes: $e');
      return [];
    }
  }

  // --- GASTOS ---
  static Future<List<GastoModel>> fetchGastos() async {
    try {
      // Realizamos un join para obtener los nombres de categorías y dependientes
      final response = await client
          .from('gastos')
          .select('*, categorias(nombre), dependientes(nombre)')
          .order('fecha_registro', ascending: false);
      
      return (response as List).map((data) => GastoModel.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error al obtener gastos: $e');
      return [];
    }
  }

  static Future<GastoModel?> insertGasto(GastoModel gasto) async {
    try {
      // 1. Insertar en movimientos
      final movimiento = await client.from('movimientos').insert({
        'id_usuario': defaultUserId,
        'tipo_flujo': 'Salida',
        'subtipo_modulo': 'Gasto',
      }).select().single();

      final int idMovimiento = movimiento['id_movimiento'];

      // 2. Insertar en salida
      final salida = await client.from('salida').insert({
        'id_movimiento': idMovimiento,
      }).select().single();

      final int idSalida = salida['id_salida'];

      // 3. Insertar en gastos
      final gastoData = gasto.toInsertMap();
      gastoData['id_salida'] = idSalida;

      final response = await client
          .from('gastos')
          .insert(gastoData)
          .select('*, categorias(nombre), dependientes(nombre)')
          .single();
      
      return GastoModel.fromMap(response);
    } catch (e) {
      debugPrint('Error al insertar gasto: $e');
      return null;
    }
  }

  static Future<GastoModel?> updateGasto(GastoModel gasto) async {
    if (gasto.id == null) return null;
    
    try {
      final response = await client
          .from('gastos')
          .update(gasto.toInsertMap())
          .eq('id_gastos', gasto.id!)
          .select('*, categorias(nombre), dependientes(nombre)')
          .single();
      
      return GastoModel.fromMap(response);
    } catch (e) {
      debugPrint('Error al actualizar gasto: $e');
      return null;
    }
  }

  static Future<bool> deleteGasto(int idGastos) async {
    try {
      // Al borrar el gasto, deberíamos considerar si borrar también la salida y el movimiento
      // El esquema tiene ON DELETE CASCADE en id_salida, así que borrar en 'movimientos' 
      // debería limpiar todo si estuviera configurado así.
      // Pero para ser directos y seguros borramos el registro de gastos.
      await client
          .from('gastos')
          .delete()
          .eq('id_gastos', idGastos);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar gasto: $e');
      return false;
    }
  }
}
