import 'package:flutter/material.dart';

import '../../models/dependiente_model.dart';
import '../../services/dependiente_services.dart';
import '../../core/network/api_client.dart';
import '../dependientes/agregar_dependientes_screen.dart';

// Etiquetas y colores del peso económico, igual que `PESO_LABELS` y
// `pesoColor` en el archivo React — las replico aquí porque Dart no
// puede importar ese objeto de JS, hay que declarar el equivalente.
const Map<int, String> _pesoLabels = {
  1: 'Muy bajo',
  2: 'Bajo',
  3: 'Medio',
  4: 'Alto',
  5: 'Muy alto',
};

// Devuelve un color según el nivel de peso económico (1 a 5), igual
// que la función `pesoColor` de React. Si `peso` es null (dependiente
// sin ese dato), cae en el color por defecto de "Medio".
Color _pesoColor(int? peso) {
  final p = peso ?? 3;
  if (p <= 1) return const Color(0xFF34d399); // verde
  if (p <= 2) return const Color(0xFF60a5fa); // azul
  if (p <= 3) return const Color(0xFFfbbf24); // ámbar
  if (p <= 4) return const Color(0xFFfb923c); // naranja
  return const Color(0xFFf87171); // rojo
}

class PanelDependientesScreen extends StatefulWidget {
  const PanelDependientesScreen({super.key});

  @override
  State<PanelDependientesScreen> createState() =>
      _PanelDependientesScreenState();
}

class _PanelDependientesScreenState extends State<PanelDependientesScreen> {
  List<DependienteModel> _dependientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getDependientes();
  }

  Future<void> _getDependientes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await DependientesService.getDependientes();
      setState(() => _dependientes = lista);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error al obtener dependientes');
      debugPrint('$e');
    } finally {
      setState(() => _cargando = false);
    }
  }

 String _formatFecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha registrada';
  final dd = fecha.day.toString().padLeft(2, '0');
  final mm = fecha.month.toString().padLeft(2, '0');
  return '$dd/$mm/${fecha.year}';
}

  Future<void> _abrirAgregarDependiente() async {
    final resultado = await Navigator.push<DependienteModel>(
      context,
      MaterialPageRoute(builder: (context) => const AgregarDependienteScreen()),
    );
    if (resultado != null) _getDependientes();
  }

  Future<void> _abrirEditarDependiente(DependienteModel dep) async {
    final resultado = await Navigator.push<DependienteModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarDependienteScreen(dependienteParaEditar: dep),
      ),
    );
    if (resultado != null) _getDependientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `Container` con `RadialGradient` es el equivalente Flutter del
      // `radial-gradient(...)` que usa el CSS de la vista web — mismos
      // tres colores, mismos porcentajes aproximados de parada.
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6), // ~ "30% 20%" del CSS
            radius: 1.4,
            colors: [Color(0xFF1e3a5f), Color(0xFF0f172a), Color(0xFF1a0f2e)],
            stops: [0.1, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _getDependientes,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reemplaza el header viejo (con flecha de "volver") por el bloque
  // "Total Dependientes" + botón, igual que el `<article>` de React.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF6366f1).withOpacity(0.35),
              const Color(0xFF4f46e5).withOpacity(0.04),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL DEPENDIENTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: const Color(0xFF818cf8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dependientes.length}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _abrirAgregarDependiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('➕ Agregar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Cargando dependientes...',
              style: TextStyle(fontSize: 13, color: Color(0xFFa1a1aa))),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
        ),
      );
    }

    if (_dependientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay dependientes registrados. Agrega tu primer dependiente para comenzar.',
          style: TextStyle(fontSize: 13, color: Color(0xFF71717a)),
        ),
      );
    }

    // `ListView` en vez de `GridView`: en mobile va todo en una sola
    // columna, como pediste — el `GridView` de varias columnas de la
    // versión anterior era para pantallas anchas (web/tablet).
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _dependientes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dep = _dependientes[index];
        return _DependienteCard(
          dependiente: dep,
          fechaFormateada: _formatFecha(dep.fechaNacimiento),
          onTap: () => _abrirEditarDependiente(dep),
        );
      },
    );
  }
}

class _DependienteCard extends StatelessWidget {
  final DependienteModel dependiente;
  final String fechaFormateada;
  final VoidCallback onTap;

  const _DependienteCard({
    required this.dependiente,
    required this.fechaFormateada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _pesoColor(dependiente.pesoEconomico);
    final label = _pesoLabels[dependiente.pesoEconomico] ?? 'N/A';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dependiente.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFFf4f4f5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [dependiente.relacion, dependiente.ocupacion]
                  .where((v) => v != null && v.isNotEmpty)
                  .join(' · '),
              style: const TextStyle(fontSize: 12, color: Color(0xFFa1a1aa)),
            ),
            if (dependiente.fechaNacimiento != null) ...[
              const SizedBox(height: 4),
              Text(
                'Nac: $fechaFormateada',
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717a)),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                border: Border.all(color: color.withOpacity(0.27)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Peso económico: $label',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}