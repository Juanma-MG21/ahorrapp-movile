import 'package:flutter/material.dart';

import '../../models/dependiente_model.dart';
import '../../services/dependiente_services.dart';
import '../../core/network/api_client.dart'; // para capturar ApiException
import '../dependientes/agregar_dependientes_screen.dart';

// ── PALETA (sin cambios) ──────────────────────────────────────────
const Color _bg = Color(0xFF0f172a);
const Color _card = Color(0xFF1e293b);
const Color _border = Color(0xFF334155);
const Color _amber = Color(0xFFfbbf24);
const Color _textPrimary = Color(0xFFf4f4f5);
const Color _textSecondary = Color(0xFFa1a1aa);
const Color _textMuted = Color(0xFF71717a);
const Color _indigo = Color(0xFF818cf8);

// La clase `Dependiente` que estaba definida aquí se ELIMINA por
// completo. Ya tienes `DependienteModel` en models/dependiente_model.dart
// — mantener dos clases distintas para lo mismo es justo el tipo de
// duplicación que causaba parte de los errores que veníamos arreglando.

class PanelDependientesScreen extends StatefulWidget {
  const PanelDependientesScreen({super.key});

  @override
  State<PanelDependientesScreen> createState() =>
      _PanelDependientesScreenState();
}

class _PanelDependientesScreenState extends State<PanelDependientesScreen> {
  // Ya no necesitas `_storage` aquí: `DependientesService` lee el
  // token internamente (lo agregamos en `_token()` dentro del
  // service). La pantalla ya no debe saber nada de tokens ni de
  // headers — esa es justo la idea de tener un service separado.
  List<DependienteModel> _dependientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getDependientes();
  }

  Future<void> _getDependientes() async {
    // `setState` al inicio: si el usuario refresca (por ejemplo, al
    // volver de agregar un dependiente), queremos que vuelva a
    // mostrarse "Cargando..." y se limpie cualquier error anterior,
    // en vez de quedarse pegado con el estado de la carga previa.
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Toda la lógica de `http.get`, headers, token y parseo de
      // `data['ok']` que tenías aquí a mano, ahora vive dentro de
      // `DependientesService.getDependientes()` (que a su vez usa
      // `ApiClient`). Esta línea reemplaza como 20 líneas de tu
      // versión anterior.
      final lista = await DependientesService.getDependientes();

      setState(() {
        _dependientes = lista;
      });
    } on ApiException catch (e) {
      // `ApiException` es justo la excepción que `ApiClient` lanza
      // cuando `data['ok'] != true` o el status es >= 400 — trae el
      // mensaje real del backend en `e.message`, en vez del texto
      // fijo que tenías antes ('Error al obtener dependientes').
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      // Cualquier otro error (sin conexión, JSON raro, etc.) cae
      // aquí, como antes.
      setState(() {
        _error = 'Error al obtener dependientes';
      });
      debugPrint('$e');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  String _getIniciales(String? nombre) {
    if (nombre != null && nombre.isNotEmpty) {
      return nombre[0].toUpperCase();
    }
    return '?';
  }

  // Nuevo: helper para mostrar `fechaNacimiento`, que en
  // `DependienteModel` es `DateTime?` (no `String` como en tu clase
  // vieja). Sin esto, `Text(dependiente.fechaNacimiento)` ni siquiera
  // compilaría, porque `Text` espera un `String`.
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha registrada';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year}';
  }

  // Nuevo método: se llama cuando se toca el botón "+". Antes hacía
  // `Navigator.pushNamed(context, '/registro-dependiente')`, una ruta
  // con nombre que probablemente no está registrada en tu
  // `MaterialApp` (por eso "la ruta que importe" no llegaba a ningún
  // lado). En vez de depender de rutas nombradas, navego directo a
  // la clase del widget con `MaterialPageRoute` — más simple y no
  // depende de que hayas registrado el string en otro archivo.
  Future<void> _abrirAgregarDependiente() async {
    final resultado = await Navigator.push<DependienteModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarDependienteScreen(),
      ),
    );

    // `AgregarDependienteScreen` hace `Navigator.pop(context, resultado)`
    // al guardar con éxito. Si `resultado` no es null, significa que
    // se creó/editó un dependiente — en vez de solo agregarlo a mano
    // a la lista local, pido la lista completa de nuevo al backend:
    // así la pantalla siempre refleja el estado real del servidor,
    // no una copia que podría desincronizarse.
    if (resultado != null) {
      _getDependientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                // Antes: `Navigator.pushNamed(context, '/registro-dependiente')`.
                // Ahora llama al método de arriba.
                onPressed: _abrirAgregarDependiente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(223, 187, 159, 0),
                  foregroundColor: _textPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Agregar dependiente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: _textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lista de dependientes',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
              const SizedBox(height: 4),
              Text('${_dependientes.length} registrados',
                  style: const TextStyle(fontSize: 13, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('Cargando dependientes...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary)),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          constraints: const BoxConstraints(maxWidth: 400),
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
        child: Text('No hay dependientes registrados.',
            style: TextStyle(fontSize: 13, color: _textSecondary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columnas = 1;
        if (constraints.maxWidth >= 1024) {
          columnas = 3;
        } else if (constraints.maxWidth >= 640) {
          columnas = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: _dependientes.length,
          itemBuilder: (context, index) => _DependienteCard(
            dependiente: _dependientes[index],
            iniciales: _getIniciales(_dependientes[index].nombre),
            fechaFormateada: _formatFecha(_dependientes[index].fechaNacimiento),
            // Tocar la card abre el mismo formulario, pero en modo
            // "editar" (pasando el dependiente actual).
            onTap: () async {
              final resultado = await Navigator.push<DependienteModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => AgregarDependienteScreen(
                    dependienteParaEditar: _dependientes[index],
                  ),
                ),
              );
              if (resultado != null) _getDependientes();
            },
          ),
        );
      },
    );
  }
}

class _DependienteCard extends StatelessWidget {
  final DependienteModel dependiente;
  final String iniciales;
  final String fechaFormateada;
  final VoidCallback onTap;

  const _DependienteCard({
    required this.dependiente,
    required this.iniciales,
    required this.fechaFormateada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _amber.withOpacity(0.1)),
                  alignment: Alignment.center,
                  child: Text(iniciales,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _amber)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dependiente.nombre,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary)),
                      // `dependiente.id` es `int?` en el modelo nuevo,
                      // así que uso `?? '-'` para no mostrar "null" en
                      // pantalla si por algún motivo llegara sin id.
                      Text('ID ${dependiente.id ?? "-"}',
                          style: const TextStyle(
                              fontSize: 11, color: _textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  // `relacion` es `String?` en el modelo nuevo (antes
                  // era `String` obligatorio) — con `?? 'Sin relación'`
                  // cubrimos el caso null.
                  child: Text(dependiente.relacion ?? 'Sin relación',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _indigo)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 12),
            // La fila "Dependiente de <usuario>" se eliminó: ese dato
            // (`usuarioNombre`) no existe en `DependienteModel`. Ver
            // nota abajo de la respuesta sobre esto.
            _detailRow(
              icon: Icons.badge_outlined,
              child: Text(dependiente.ocupacion ?? 'Sin ocupación registrada',
                  style:
                      const TextStyle(fontSize: 13, color: _textSecondary)),
            ),
            const SizedBox(height: 8),
            _detailRow(
              icon: Icons.calendar_today_outlined,
              child: Text(fechaFormateada,
                  style:
                      const TextStyle(fontSize: 13, color: _textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}