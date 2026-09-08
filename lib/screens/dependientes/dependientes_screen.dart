// 'dart:convert' trae jsonDecode, el equivalente a `response.json()`
// del fetch de JS — en Dart la decodificación de JSON es una función
// suelta, no un método del objeto de respuesta.
import 'dart:convert';

import 'package:flutter/material.dart';
// El paquete 'http' reemplaza al `fetch` nativo del navegador; no
// viene incluido en Flutter por defecto, hay que declararlo en
// pubspec.yaml (ya lo agregamos la vez pasada).
import 'package:http/http.dart' as http;
// Para leer el token igual que `localStorage.getItem('token')`, pero
// de forma segura (Keychain en iOS, Keystore en Android).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────
// PALETA · mismos colores que tu Tailwind, ahora como constantes Dart.
// Los saco a top-level (fuera de cualquier clase) porque solo los usa
// este archivo; si luego los reusas en más pantallas, muévelos a tu
// clase `Tokens` central.
// ─────────────────────────────────────────────────────────────────────

const Color _bg = Color(0xFF080c18);
const Color _card = Color(0xFF0d1526);
const Color _border = Color(0xFF1c2942);
const Color _gold = Color(0xFFe0b855);
const Color _textPrimary = Color(0xFFf4f1e8);
const Color _textSecondary = Color(0xFF9aa6c4);
const Color _textMuted = Color(0xFF7d8aa8);
const Color _blue = Color(0xFF85b7eb);

// ─────────────────────────────────────────────────────────────────────
// MODELO · en JS trabajabas con el objeto crudo que devuelve el fetch
// (`dependiente.Nombre`, etc.). En Dart es más seguro envolver ese JSON
// en una clase con un constructor `fromJson`: si el backend cambia un
// nombre de campo, el error aparece en un solo lugar (aquí) y no
// desperdigado por toda la pantalla.
// ─────────────────────────────────────────────────────────────────────

class Dependiente {
  final int idDependientes;
  final String nombre;
  final String relacion;
  final String usuarioNombre;
  final String? ocupacion; // Nullable: el backend puede mandar null.
  final String fechaNacimiento;

  const Dependiente({
    required this.idDependientes,
    required this.nombre,
    required this.relacion,
    required this.usuarioNombre,
    required this.ocupacion,
    required this.fechaNacimiento,
  });

  // `factory` = un constructor que, en vez de siempre crear una
  // instancia nueva "a mano", puede decidir cómo construirla a partir
  // de otra cosa — aquí, a partir de un `Map` (el JSON ya decodificado).
  factory Dependiente.fromJson(Map<String, dynamic> json) {
    return Dependiente(
      // El backend manda `ID_dependientes` como número; lo casteamos
      // explícitamente a `int` porque Dart es estricto con tipos
      // (JS no distingue int/double, Dart sí).
      idDependientes: json['ID_dependientes'] as int,
      nombre: json['Nombre'] as String,
      relacion: json['Relacion'] as String,
      usuarioNombre: json['usuario_nombre'] as String,
      // `as String?` (con el `?`) permite que el valor sea null sin
      // que la app truene, replicando tu `dependiente.Ocupacion || 'Sin ocupacion registrada'`.
      ocupacion: json['Ocupacion'] as String?,
      fechaNacimiento: json['Fecha_nacimiento'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PANTALLA · StatefulWidget porque hace fetch al montarse y guarda
// 3 variables de estado, igual que tus 3 `useState` originales.
// ─────────────────────────────────────────────────────────────────────

class PanelDependientesScreen extends StatefulWidget {
  const PanelDependientesScreen({super.key});

  @override
  State<PanelDependientesScreen> createState() => _PanelDependientesScreenState();
}

class _PanelDependientesScreenState extends State<PanelDependientesScreen> {
  // Instancia del almacenamiento seguro; se crea una sola vez.
  final _storage = const FlutterSecureStorage();

  // Estas tres variables son, literalmente, tus tres `useState`:
  //   const [dependientes, setDependientes] = useState([]);
  //   const [cargando, setCargando] = useState(true);
  //   const [error, setError] = useState(null);
  // La diferencia es que aquí las mutas dentro de `setState(() {...})`
  // en vez de llamar una función "setter" generada automáticamente.
  List<Dependiente> _dependientes = [];
  bool _cargando = true;
  String? _error;

  // `initState` es el `useEffect(() => {...}, [])` de Flutter: se
  // ejecuta UNA sola vez, justo cuando el widget se monta por primera
  // vez en pantalla. El `[]` (array de dependencias vacío) de React
  // es literalmente lo que `initState` hace por naturaleza — no hace
  // falta declarar ninguna lista de dependencias.
  @override
  void initState() {
    super.initState();
    _getDependientes();
  }

  // `Future<void>` marca que esta función es asíncrona y no devuelve
  // ningún valor útil (equivalente a tu `async () => {...}` de JS que
  // tampoco retorna nada). Nota que puse el guion bajo `_getDependientes`
  // porque, al ser un método de una clase privada (`_PanelDependientesScreenState`),
  // es buena práctica marcarlo también como privado.
  Future<void> _getDependientes() async {
    try {
      // `await` funciona igual que en JS: pausa esta función hasta que
      // la promesa/Future se resuelva, sin bloquear el resto de la app.
      final token = await _storage.read(key: 'token');

      // `http.get` recibe un `Uri`, no un string plano — por eso envuelvo
      // la URL en `Uri.parse(...)`. El resto es igual a tu `fetch`.
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/auth/PanelDependientes'),
        headers: {
          // Si `token` es null, esto pondría "Bearer null" como string;
          // más abajo lo puedes reforzar redirigiendo al login cuando
          // `token` no exista, pero lo dejo simple para igualar tu JS.
          'Authorization': 'Bearer $token',
        },
      );

      // `jsonDecode` convierte el texto crudo de la respuesta
      // (`response.body`, un String) en un `Map<String, dynamic>` —
      // el equivalente Dart de lo que `response.json()` te daba ya
      // parseado en JS.
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // `data['ok']` puede venir como bool desde el backend; lo casteo
      // para que el compilador lo tenga claro.
      if (data['ok'] == true) {
        // `data['dependientes']` llega como `List<dynamic>` (una lista
        // de Maps sin tipar todavía). `.map(...)` reconstruye cada
        // elemento como un `Dependiente` fuerte y tipado, y `.toList()`
        // vuelve a convertir el resultado en una lista de verdad
        // (en Dart, `.map()` devuelve un `Iterable` perezoso, no una
        // lista, así que siempre hay que cerrarlo con `.toList()`).
        final lista = (data['dependientes'] as List<dynamic>)
            .map((item) => Dependiente.fromJson(item as Map<String, dynamic>))
            .toList();

        // `setState` es obligatorio: cambiar `_dependientes` sin esto
        // guardaría el dato pero NO repintaría la pantalla.
        setState(() {
          _dependientes = lista;
        });
      } else {
        setState(() {
          // `data['mensaje'] as String?` + `??` (operador "si es null,
          // usa esto otro") reemplaza tu `data.mensaje || 'No se pudieron obtener los dependientes'`.
          _error = data['mensaje'] as String? ?? 'No se pudieron obtener los dependientes';
        });
      }
    } catch (err) {
      // Cualquier error de red, de parseo, etc. cae aquí — igual que
      // tu bloque `catch (err)`.
      setState(() {
        _error = 'Error al obtener dependientes';
      });
      // `debugPrint` es el `console.error` de Flutter: imprime en la
      // consola de depuración sin romper la app en modo release.
      debugPrint('$err');
    } finally {
      // El `finally` corre siempre, haya ido bien o mal — igual que en JS.
      setState(() {
        _cargando = false;
      });
    }
  }

  // Helper para las iniciales del avatar — traducción directa de tu
  // función `getIniciales`, solo que aquí es un método de la clase.
  String _getIniciales(String? nombre) {
    // `nombre?.isNotEmpty == true` es el equivalente a tu chequeo
    // `nombre ? ... : '?'`: si `nombre` es null, el `?.` corta la
    // cadena antes de tronar y el resultado completo da `null`,
    // que NUNCA es `== true`, así que cae directo al `?` de abajo.
    if (nombre != null && nombre.isNotEmpty) {
      // `nombre[0]` saca el primer carácter; `.toUpperCase()` es igual
      // que en JS.
      return nombre[0].toUpperCase();
    }
    return '?';
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
            // `Expanded` + adentro un `SingleChildScrollView`/`GridView`
            // para que el body pueda crecer y scrollear como tu `<main>`.
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Separé el header en su propio método (no en un widget aparte)
  // solo por prolijidad — podrías perfectamente extraerlo a una
  // clase `StatelessWidget` como hicimos con `MobileHeader` antes.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          // El `<Link to="/PanelAdmin">` de react-router-dom se traduce
          // a `Navigator.pop(context)` SI esta pantalla se abrió con
          // `Navigator.push` desde PanelAdmin (lo más común). Si en tu
          // app usas rutas con nombre (go_router / named routes),
          // cambiarías esto por `Navigator.pushReplacementNamed(context, '/panel-admin')`.
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 16, color: _textSecondary),
                  SizedBox(width: 8),
                  Text('Volver al panel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lista de dependientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary)),
              const SizedBox(height: 4),
              // Interpolación con una expresión (`${...}`, no solo un
              // nombre suelto) porque `.length` es una llamada, no una
              // variable simple.
              Text('${_dependientes.length} registrados', style: const TextStyle(fontSize: 13, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // Este método concentra el `{cargando && ...} {error && ...} {!cargando && !error && (...)}`
  // encadenado que tenías en JSX. En Dart, como no hay renderizado
  // condicional "inline" tan directo, es más legible resolverlo con
  // `if/else` normales antes de decidir qué widget devolver.
  Widget _buildBody() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Text('Cargando dependientes...', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _textSecondary)),
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
          // El `!` después de `_error` le dice al compilador "confía en
          // mí, en este punto ya sé que no es null" — válido aquí
          // porque acabamos de comprobarlo con el `if` de arriba.
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
        ),
      );
    }

    if (_dependientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No hay dependientes registrados.', style: TextStyle(fontSize: 13, color: _textSecondary)),
      );
    }

    // `GridView.builder` reemplaza tu `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`.
    // Flutter no tiene "breakpoints" automáticos como Tailwind, así que
    // calculamos las columnas a mano según el ancho disponible con
    // `LayoutBuilder` (el equivalente a una media query, pero en Dart).
    return LayoutBuilder(
      builder: (context, constraints) {
        int columnas = 1;
        if (constraints.maxWidth >= 1024) {
          columnas = 3; // lg:grid-cols-3
        } else if (constraints.maxWidth >= 640) {
          columnas = 2; // sm:grid-cols-2
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // `childAspectRatio` controla alto/ancho de cada card; lo
            // ajusté a ojo para que quepan las 3 líneas de detalle.
            childAspectRatio: 1.1,
          ),
          itemCount: _dependientes.length,
          itemBuilder: (context, index) => _DependienteCard(
            dependiente: _dependientes[index],
            iniciales: _getIniciales(_dependientes[index].nombre),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// CARD · la extraje a su propio StatelessWidget (igual que hicimos con
// StatCard en el dashboard) porque no depende del estado de la
// pantalla, solo de los datos que recibe — más fácil de reusar y testear.
// ─────────────────────────────────────────────────────────────────────

class _DependienteCard extends StatelessWidget {
  final Dependiente dependiente;
  final String iniciales;
  const _DependienteCard({required this.dependiente, required this.iniciales});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: avatar + nombre + chip de relación.
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withOpacity(0.1)),
                alignment: Alignment.center,
                child: Text(iniciales, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dependiente.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary)),
                    Text('ID ${dependiente.idDependientes}', style: const TextStyle(fontSize: 11, color: _textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(dependiente.relacion, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          // Fila "Dependiente de <usuario>" — uso `Expanded` en el
          // `Text` para que el nombre largo no desborde la card.
          _detailRow(
            icon: Icons.people_outline,
            child: Text.rich(
              // `TextSpan` permite mezclar dos estilos dentro del mismo
              // texto (el "Dependiente de" en gris, el nombre en claro),
              // igual que tu `<span>Dependiente de <span className="...">{nombre}</span></span>`.
              TextSpan(
                style: const TextStyle(fontSize: 13, color: _textSecondary),
                children: [
                  const TextSpan(text: 'Dependiente de '),
                  TextSpan(text: dependiente.usuarioNombre, style: const TextStyle(color: _textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _detailRow(
            icon: Icons.badge_outlined,
            // `??` de nuevo: si `ocupacion` es null, muestra el texto
            // por defecto, igual que tu `|| 'Sin ocupacion registrada'`.
            child: Text(dependiente.ocupacion ?? 'Sin ocupacion registrada', style: const TextStyle(fontSize: 13, color: _textSecondary)),
          ),
          const SizedBox(height: 8),
          _detailRow(
            icon: Icons.calendar_today_outlined,
            child: Text(dependiente.fechaNacimiento, style: const TextStyle(fontSize: 13, color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  // Pequeño helper repetido 3 veces en el original (ícono + texto);
  // en vez de copiar el `Row` tres veces, lo armo una sola vez aquí.
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