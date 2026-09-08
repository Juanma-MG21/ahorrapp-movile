// ════════════════════════════════════════════════════════════════════
// AhorrApp · Dashboard (versión Flutter/Dart)
// Puerto del componente React original, organizado en las mismas
// 17 secciones para que puedas comparar ambos archivos lado a lado.
// ════════════════════════════════════════════════════════════════════

// 'package:flutter/material.dart' importa TODOS los widgets de Material
// Design (Scaffold, Container, Text, Column, Row, etc.). Es el
// equivalente a importar React + los componentes HTML base a la vez.
import 'package:flutter/material.dart';

// fl_chart es la librería de gráficas más usada en Flutter; cumple el
// mismo rol que 'recharts' en el original. Hay que agregarla en
// pubspec.yaml (ver instrucciones al final de mi respuesta).
import 'package:fl_chart/fl_chart.dart';

// 'intl' trae NumberFormat, que reemplaza a `n.toLocaleString("es-CO")`.
import 'package:intl/intl.dart';

import '../services/notificaciones_services.dart';

import '../models/notificaciones.dart';

import '../widgets/notificacion_panel.dart';

// Punto de entrada de toda app Flutter. Es literalmente el
// `ReactDOM.render(<App />)` de una app web: arranca el widget raíz.
void main() {
  runApp(const AhorrApp());
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 1 · TOKENS DE DISEÑO
// En React usabas un objeto plano `TOKEN = {...}`. En Dart, como es un
// lenguaje fuertemente tipado, lo natural es una `class` con campos
// `static const` (constantes de clase, no hace falta instanciarla:
// se usa como `Tokens.amber`, nunca `Tokens().amber`).
// ─────────────────────────────────────────────────────────────────────

class Tokens {
  // Constructor privado (el guion bajo `_` antes del nombre) para que
  // nadie pueda hacer `Tokens()` por accidente; esta clase es solo un
  // "namespace" de constantes, como un enum de valores.
  Tokens._();

  // Colores base. `Color(0xFF1e3a5f)` es Dart para un color hex:
  // 0xFF = canal alpha (opacidad, FF = 100%), seguido del RGB.
  static const Color bgTop = Color(0xFF1e3a5f);
  static const Color bgMid = Color(0xFF0f172a);
  static const Color bgBottom = Color(0xFF1a0f2e);

  // `withOpacity(0.05)` es el equivalente a `rgba(255,255,255,0.05)`:
  // toma un color base y le baja la opacidad a ese porcentaje (0.0–1.0).
  static Color card = Colors.white.withOpacity(0.05);
  static Color cardBorder = Colors.white.withOpacity(0.09);
  static Color glassBorder = Colors.white.withOpacity(0.13);

  static const Color amber = Color(0xFFfbbf24);
  static Color amberDim = amber.withOpacity(0.15);
  static const Color green = Color(0xFF34d399);
  static const Color red = Color(0xFFf87171);
  static const Color purple = Color(0xFFa78bfa);

  static const Color textPrimary = Color(0xFFf4f4f5);
  static const Color textSecondary = Color(0xFFa1a1aa);
  static const Color textMuted = Color(0xFF71717a);

  // `double` porque los radios de borde en Flutter siempre son
  // números de punto flotante (BorderRadius los exige así).
  static const double radius = 18;
  static const double radiusSm = 12;

  // El "radial-gradient" de CSS se modela en Flutter con la clase
  // `RadialGradient`. `Alignment(-0.4, -0.6)` ubica el centro del
  // degradado (el sistema de Alignment va de -1 a 1 en cada eje,
  // por eso convertí el "30% 20%" del CSS a esa escala).
  static const RadialGradient background = RadialGradient(
    center: Alignment(-0.4, -0.6),
    radius: 1.2,
    colors: [bgTop, bgMid, bgBottom],
    // `stops` marca en qué punto (0.0–1.0) empieza cada color,
    // igual que los porcentajes "10%, 60%, 100%" del CSS original.
    stops: [0.10, 0.60, 1.0],
  );
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 2 · DATOS MOCK
// En React tenías objetos `{ label: ..., value: ... }` sueltos.
// En Dart es más idiomático (y más seguro) definir una `class` por
// cada "forma" de dato: así el compilador te avisa si te falta un
// campo o pones el tipo equivocado, algo que TypeScript hacía a medias
// y JS puro no hacía en absoluto.
// ─────────────────────────────────────────────────────────────────────

// `String fmt(int n)` = función que recibe un entero y devuelve texto.
// Aquí exigimos `int` (no `num` ni `double`) porque tus montos son
// pesos colombianos sin decimales, igual que en el original.
String fmt(int n) {
  // NumberFormat.currency crea un formateador reutilizable.
  // `locale: 'es_CO'` agrupa los miles con punto, como Colombia.
  // `symbol: '\$'` antepone el símbolo (la barra invertida escapa el
  // signo $, que en Dart abre interpolación de strings, ver más abajo).
  // `decimalDigits: 0` = sin centavos, igual que el original.
  final formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  return formatter.format(n);
}

// `class` para cada tarjeta de resumen financiero.
class StatCardData {
  // Todos los campos son `final`: una vez creado el objeto, no cambian.
  // Es la costumbre en Dart/Flutter para datos inmutables (como los
  // props de un componente React que nunca reasignas).
  final String label;
  final String emoji;
  final int value;
  final String sub;
  final Color accent;

  // Constructor "const": permite crear estos objetos en tiempo de
  // compilación (más eficiente) porque todos sus campos son const-safe.
  // `required` obliga a pasar cada nombre al crear la instancia.
  const StatCardData({
    required this.label,
    required this.emoji,
    required this.value,
    required this.sub,
    required this.accent,
  });
}

// Lista de tarjetas, equivalente al array `STAT_CARDS` original.
// `const` al inicio = la lista entera es inmutable y se calcula una
// sola vez, no en cada rebuild (optimización que React no ofrece así).
const List<StatCardData> statCards = [
  StatCardData(label: 'Ingresos', emoji: '💰', value: 4500000, sub: 'Período activo', accent: Tokens.green),
  StatCardData(label: 'Gastos', emoji: '💸', value: 2150000, sub: 'Período activo', accent: Tokens.red),
  StatCardData(label: 'Ahorros', emoji: '🎯', value: 1200000, sub: 'Período activo', accent: Tokens.amber),
  StatCardData(label: 'Balance', emoji: '💜', value: 1150000, sub: 'Disponible este período', accent: Tokens.purple),
];

class BolsaItem {
  final String ticker;
  final String price; // Texto ya formateado, igual que en el original.
  final String change;
  final bool up; // Reemplaza el `up: true/false` de JS; en Dart es `bool`.

  const BolsaItem({required this.ticker, required this.price, required this.change, required this.up});
}

const List<BolsaItem> bolsaData = [
  BolsaItem(ticker: 'ECOPETROL', price: '\$2.340', change: '+1.8%', up: true),
  BolsaItem(ticker: 'BANCOLOMBIA', price: '\$38.200', change: '-0.4%', up: false),
  BolsaItem(ticker: 'ISA', price: '\$16.850', change: '+2.3%', up: true),
  BolsaItem(ticker: 'GRUPO SURA', price: '\$28.700', change: '-1.1%', up: false),
];

class BudgetItem {
  final String cat;
  final int presupuestado;
  final int ejecutado;
  final int disponible;
  const BudgetItem({required this.cat, required this.presupuestado, required this.ejecutado, required this.disponible});
}

const List<BudgetItem> budgetData = [
  BudgetItem(cat: 'Vivienda', presupuestado: 1200000, ejecutado: 950000, disponible: 250000),
  BudgetItem(cat: 'Alimentación', presupuestado: 800000, ejecutado: 720000, disponible: 80000),
  BudgetItem(cat: 'Transporte', presupuestado: 400000, ejecutado: 380000, disponible: 20000),
  BudgetItem(cat: 'Entret.', presupuestado: 300000, ejecutado: 160000, disponible: 140000),
  BudgetItem(cat: 'Servicios', presupuestado: 350000, ejecutado: 310000, disponible: 40000),
  BudgetItem(cat: 'Salud', presupuestado: 250000, ejecutado: 180000, disponible: 70000),
];

class WeeklyItem {
  final String semana;
  final int ingresos;
  final int gastos;
  final int balance;
  const WeeklyItem({required this.semana, required this.ingresos, required this.gastos, required this.balance});
}

const List<WeeklyItem> weeklyData = [
  WeeklyItem(semana: 'S1', ingresos: 1200000, gastos: 480000, balance: 720000),
  WeeklyItem(semana: 'S2', ingresos: 950000, gastos: 620000, balance: 330000),
  WeeklyItem(semana: 'S3', ingresos: 1100000, gastos: 590000, balance: 510000),
  WeeklyItem(semana: 'S4', ingresos: 1250000, gastos: 460000, balance: 790000),
];

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 3 · COMPONENTES ATÓMICOS
// Cada `function Componente()` de React sin estado propio se traduce a
// una `class` que extiende `StatelessWidget`. "Stateless" significa
// que el widget no guarda datos que cambien por sí solo (como tu
// `function Skeleton()` original, que solo recibe props y pinta).
// ─────────────────────────────────────────────────────────────────────

// 3a · Skeleton (shimmer de carga)
class Skeleton extends StatelessWidget {
  // `h` es el equivalente al prop `h = 20` con valor por defecto.
  final double h;
  // `super.key` es un identificador interno que Flutter usa para saber
  // qué widget es cuál al reconstruir el árbol; no tiene equivalente
  // directo en React porque React usa el `key` de listas de forma
  // parecida, pero aquí TODO widget puede llevarlo.
  const Skeleton({super.key, this.h = 20});

  // Todo StatelessWidget debe implementar `build`: es literalmente el
  // `return (...)` del final de tu función de componente en React.
  @override
  Widget build(BuildContext context) {
    // `Container` = el `<div style={{...}}>` de Flutter: un caja con
    // tamaño, color, bordes, etc.
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        color: Colors.white.withOpacity(0.07),
      ),
      // Flutter no tiene un equivalente 1:1 de `animation: pulse` en
      // CSS puro; la forma idiomática es envolver esto en un
      // `AnimatedOpacity` o usar el paquete `shimmer`. Lo dejo como
      // nota porque agregar la animación real requiere un
      // StatefulWidget con un `AnimationController` (más abajo verás
      // otro ejemplo de StatefulWidget para que compares el patrón).
    );
  }
}

// 3b · Tooltip oscuro para gráficas
// fl_chart no usa un widget de tooltip como recharts (`<Tooltip content={...}/>`);
// en su lugar, configuras un `LineTouchTooltipData` / `BarTouchTooltipData`
// dentro de cada gráfica (lo verás en las Secciones 10 y 11). Esta
// función es un helper que arma el texto que ese tooltip mostrará.
String darkTooltipLabel(String seriesName, int value) {
  // Interpolación de strings: `$variable` (o `${expresión}` si hay
  // algo más que un nombre suelto) inserta el valor dentro del texto,
  // igual que los backticks `` `texto ${var}` `` de JS.
  return '$seriesName: ${fmt(value)}';
}

// 3c · Chip de período
class PeriodChip extends StatelessWidget {
  final String text;
  const PeriodChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      // `Text` es el `<p>`/`<span>` de Flutter. El `style` recibe un
      // `TextStyle`, no un mapa CSS.
      child: Text(text, style: const TextStyle(fontSize: 11, color: Tokens.textMuted)),
    );
  }
}

// 3d · Leyenda compacta para gráficas
class LegendItemData {
  final String label;
  final Color color;
  final bool dashed;
  const LegendItemData({required this.label, required this.color, this.dashed = false});
}

class ChartLegend extends StatelessWidget {
  final List<LegendItemData> items;
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // `Wrap` reemplaza al `flexWrap: "wrap"` de tu `<div style={{display:"flex", flexWrap:"wrap"}}>`.
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: items.map((item) {
        // `Row` = flex-direction: row. Cada `map` de tu JSX (`items.map(l => <div>...)`
        // se traduce igual: `.map((item) { ... }).toList()` (Dart exige
        // convertir el iterable resultante en `List` con `.toList()`).
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 2,
              decoration: item.dashed
                  ? BoxDecoration(border: Border(top: BorderSide(color: item.color, width: 2)))
                  : BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(1)),
            ),
            const SizedBox(width: 6),
            Text(item.label, style: const TextStyle(fontSize: 11, color: Tokens.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 4 · TARJETA CONTENEDORA DE GRÁFICA
// ─────────────────────────────────────────────────────────────────────

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? period; // `?` = nullable: equivale a un prop opcional.
  // `Widget child` reemplaza `children: React.ReactNode` — en Flutter
  // el contenido anidado se pasa como un widget normal, no como
  // "children" mágico de JSX.
  final Widget child;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.period,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: Tokens.glassBorder),
        color: Tokens.card,
        // El `backdropFilter: blur()` de CSS no existe como propiedad
        // de Container; en Flutter se logra envolviendo el contenido
        // en un `BackdropFilter` + `ImageFilter.blur`. Lo omito aquí
        // para no complicar el ejemplo, pero es la pieza que falta si
        // quieres el efecto "glass" exacto.
      ),
      // `Column` = flex-direction: column, el default de un div en bloque.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tokens.amber, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Tokens.textSecondary)),
          // `if (period != null) ...` es "spread condicional": solo
          // agrega el widget a la lista si la condición es verdadera.
          // Es el equivalente Dart de `{period && <PeriodChip .../>}`.
          if (period != null) PeriodChip(text: period!),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 5 · HEADER MÓVIL
// ─────────────────────────────────────────────────────────────────────

class MobileHeader extends StatelessWidget {
  final int idUsuario; // 👈 Nuevo parámetro
  const MobileHeader({super.key, required this.idUsuario});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // El "safe area" del notch/Dynamic Island se maneja en Flutter
        // con `MediaQuery.of(context).padding.top` (tal como comentaba
        // tu propio código original) en vez de `env(safe-area-inset-top)`.
        SizedBox(height: MediaQuery.of(context).padding.top + 54),
        SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AhorrApp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Tokens.amber, letterSpacing: -0.5)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Dashboard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tokens.textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    // Botón de notificaciones. `GestureDetector` es el
                    // `onClick` de un `<button>`; a diferencia de HTML,
                    // en Flutter cualquier widget puede volverse
                    // "clickeable" envolviéndolo así.
                    GestureDetector(
                      onTap: onNotif,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Tokens.glassBorder),
                              color: Colors.white.withOpacity(0.06),
                            ),
                            child: const Icon(Icons.notifications_none, size: 17, color: Tokens.amber),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Tokens.amber,
                                border: Border.all(color: Tokens.bgMid, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Línea degradada ámbar. `LinearGradient` con transparencias en
        // los extremos reemplaza el `linear-gradient(90deg, transparent...)`.
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Tokens.amber.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 6 · BIENVENIDA
// ─────────────────────────────────────────────────────────────────────

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Bienvenido de vuelta', style: TextStyle(fontSize: 12, color: Tokens.textSecondary, fontWeight: FontWeight.w500)),
          SizedBox(height: 2),
          Text('Carlos 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Tokens.textPrimary, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 7 · TARJETA FINANCIERA (StatCard)
// ─────────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final StatCardData data;
  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: Tokens.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // `Expanded` reemplaza el `flex: 1` de tu div: hace que este
          // hijo ocupe todo el espacio restante dentro del Row.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Tokens.textMuted, letterSpacing: 0.07 * 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    fmt(data.value),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: data.accent, letterSpacing: -0.5, height: 1.1),
                  ),
                ),
                Text(data.sub, style: const TextStyle(fontSize: 11, color: Tokens.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Opacity(opacity: 0.55, child: Text(data.emoji, style: const TextStyle(fontSize: 28))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 8 · RESUMEN FINANCIERO (4 tarjetas)
// ─────────────────────────────────────────────────────────────────────

class FinancialSummary extends StatelessWidget {
  const FinancialSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: statCards
            // Por cada dato, genero el widget y le agrego el espacio
            // (`gap: 10` en CSS no existe en Column, así que lo simulo
            // intercalando `SizedBox`).
            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: StatCard(data: c)))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 9 · WIDGET BOLSA
// ─────────────────────────────────────────────────────────────────────

class BolsaWidget extends StatelessWidget {
  const BolsaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Bolsa',
      subtitle: 'Mercado colombiano · Hoy',
      child: Column(
        children: bolsaData.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.ticker, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Tokens.textPrimary)),
                Row(
                  children: [
                    Text(s.price, style: const TextStyle(fontSize: 13, color: Tokens.textSecondary)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (s.up ? Tokens.green : Tokens.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.change,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.up ? Tokens.green : Tokens.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 10 · GRÁFICA DE BARRAS (Presupuesto vs Ejecutado)
// fl_chart's `BarChart` es más "manual" que recharts: no adivina ejes
// ni grupos, cada barra y grupo se declara explícitamente.
// ─────────────────────────────────────────────────────────────────────

class BudgetChart extends StatelessWidget {
  const BudgetChart({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Presupuesto vs Ejecutado',
      subtitle: 'Comparación del período activo',
      period: 'Período: 01/09/2026 → 30/09/2026',
      child: Column(
        children: [
          SizedBox(
            height: 230,
            // `SingleChildScrollView` con `scrollDirection: horizontal`
            // reemplaza tu `overflowX: "auto"`.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 340,
                child: BarChart(
                  BarChartData(
                    // `barGroups`: un grupo por categoría (Vivienda,
                    // Alimentación...), cada grupo con 3 barras.
                    // `asMap().entries` me da el índice `i` junto al
                    // valor, porque `BarChartGroupData` necesita un
                    // `x` numérico (posición en el eje) por grupo.
                    barGroups: budgetData.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: item.presupuestado.toDouble(), color: const Color(0xBFF59E0B), width: 8),
                          BarChartRodData(toY: item.ejecutado.toDouble(), color: const Color(0xBFEF4444), width: 8),
                          BarChartRodData(toY: item.disponible.toDouble(), color: const Color(0xA66366F1), width: 8),
                        ],
                      );
                    }).toList(),
                    // `titlesData` controla las etiquetas de los ejes,
                    // equivalente a tus `<XAxis>` / `<YAxis>`.
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // `value` llega como double; lo convierto a
                            // índice entero para buscar la categoría.
                            final index = value.toInt();
                            if (index < 0 || index >= budgetData.length) return const SizedBox.shrink();
                            return Text(budgetData[index].cat, style: const TextStyle(fontSize: 11, color: Tokens.textMuted));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) => Text('\$${(value / 1e6).toStringAsFixed(1)}M', style: const TextStyle(fontSize: 10, color: Tokens.textMuted)),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const ChartLegend(items: [
            LegendItemData(label: 'Presupuestado', color: Color(0xE6F59E0B)),
            LegendItemData(label: 'Ejecutado', color: Color(0xE6EF4444)),
            LegendItemData(label: 'Disponible', color: Color(0xE66366F1)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 11 · GRÁFICA DE ÁREA (Flujo semanal)
// fl_chart no tiene un "AreaChart" separado: se logra con `LineChart`
// + `belowBarData` (el relleno bajo la línea).
// ─────────────────────────────────────────────────────────────────────

class WeeklyFlowChart extends StatelessWidget {
  const WeeklyFlowChart({super.key});

  // Método auxiliar privado (el `_` inicial marca "privado a este
  // archivo", equivalente a no exportar una función en JS) que arma
  // una serie de línea+área a partir de una lista de valores.
  LineChartBarData _series(List<int> values, Color color, {bool dashed = false}) {
    return LineChartBarData(
      // `FlSpot(x, y)` es un punto de la gráfica; `i.toDouble()` porque
      // el eje X de fl_chart siempre es double.
      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dashArray: dashed ? [5, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Flujo semanal',
      subtitle: 'Ingresos vs gastos semana a semana',
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  _series(weeklyData.map((w) => w.ingresos).toList(), Tokens.green),
                  _series(weeklyData.map((w) => w.gastos).toList(), Tokens.red),
                  _series(weeklyData.map((w) => w.balance).toList(), Tokens.purple, dashed: true),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weeklyData.length) return const SizedBox.shrink();
                        return Text(weeklyData[index].semana, style: const TextStyle(fontSize: 11, color: Tokens.textMuted));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text('\$${(value / 1e6).toStringAsFixed(1)}M', style: const TextStyle(fontSize: 10, color: Tokens.textMuted)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const ChartLegend(items: [
            LegendItemData(label: 'Ingresos', color: Tokens.green),
            LegendItemData(label: 'Gastos', color: Tokens.red),
            LegendItemData(label: 'Balance', color: Tokens.purple, dashed: true),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 12 · ESTADOS DE CARGA Y ERROR
// ─────────────────────────────────────────────────────────────────────

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // `List.generate(4, ...)` reemplaza el `[100,100,100,100].map(...)`:
          // genera 4 elementos ejecutando la función con cada índice.
          ...List.generate(4, (i) => const Padding(padding: EdgeInsets.only(bottom: 10), child: Skeleton(h: 100))),
          const SizedBox(height: 6),
          const Skeleton(h: 240),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius),
        border: Border.all(color: Tokens.red.withOpacity(0.2)),
        color: Tokens.red.withOpacity(0.06),
      ),
      child: Column(
        children: [
          const Text('No pudimos cargar esta información.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tokens.red)),
          const SizedBox(height: 6),
          const Text('Intenta nuevamente.', style: TextStyle(fontSize: 13, color: Tokens.textSecondary)),
          const SizedBox(height: 16),
          // `TextButton` / `ElevatedButton` reemplazan al `<button>`.
          // Uso `TextButton.styleFrom` para personalizar look, como el
          // `style={{...}}` inline original.
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: Tokens.red.withOpacity(0.12),
              foregroundColor: Tokens.red,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Tokens.red.withOpacity(0.3)),
              ),
            ),
            child: const Text('Reintentar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 13 · BARRA DE NAVEGACIÓN INFERIOR (BottomNavBar)
// ─────────────────────────────────────────────────────────────────────

// `enum` es el tipo correcto para un conjunto fijo de valores con
// nombre — más seguro que el `type NavTab = "dashboard" | "ingresos" | ...`
// de TypeScript, porque el compilador de Dart valida cada caso.
enum NavTab { dashboard, ingresos, gastos, deudas, imprevistos, ahorros, dependientes }

class NavItemData {
  final NavTab id;
  final String label;
  final IconData icon; // Íconos de Material en vez de SVGs a mano.
  const NavItemData({required this.id, required this.label, required this.icon});
}

const List<NavItemData> navItems = [
  NavItemData(id: NavTab.dashboard, label: 'Inicio', icon: Icons.grid_view_rounded),
  NavItemData(id: NavTab.ingresos, label: 'Ingresos', icon: Icons.arrow_upward_rounded),
  NavItemData(id: NavTab.gastos, label: 'Gastos', icon: Icons.arrow_downward_rounded),
  NavItemData(id: NavTab.deudas, label: 'Deudas', icon: Icons.credit_card_rounded),
  NavItemData(id: NavTab.imprevistos, label: 'Imprevistos', icon: Icons.warning_amber_rounded),
  NavItemData(id: NavTab.ahorros, label: 'Ahorros', icon: Icons.savings_rounded),
  NavItemData(id: NavTab.dependientes, label: 'Dependientes', icon: Icons.people_rounded),
];

class BottomNavBar extends StatelessWidget {
  final NavTab active;
  // `ValueChanged<NavTab>` = función que recibe un NavTab y no
  // devuelve nada; equivale a `(t: NavTab) => void`.
  final ValueChanged<NavTab> onChange;
  const BottomNavBar({super.key, required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    // `Positioned` solo funciona dentro de un `Stack` (lo verás en la
    // Sección 17): así se logra el `position: fixed` del original.
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB80f172a),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.map((item) {
            final isActive = item.id == active;
            return GestureDetector(
              onTap: () => onChange(item.id),
              child: Container(
                constraints: const BoxConstraints(minWidth: 52),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Tokens.amber.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 20, color: isActive ? Tokens.amber : Colors.white.withOpacity(0.7)),
                    const SizedBox(height: 3),
                    Text(item.label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? Tokens.amber : Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 14 · PANEL DE NOTIFICACIONES (overlay)
// En vez de armar el overlay a mano, uso `showModalBottomSheet`, que es
// el widget nativo de Flutter para "hojas inferiores" — hace el mismo
// trabajo que tu backdrop + panel, pero con gestos y animación gratis.
// ─────────────────────────────────────────────────────────────────────

class NotifItemData {
  final String icon;
  final String title;
  final String body;
  final String time;
  const NotifItemData({required this.icon, required this.title, required this.body, required this.time});
}

const List<NotifItemData> notifs = [
  NotifItemData(icon: '💰', title: 'Ingreso registrado', body: 'Se acreditaron \$450.000 a tu cuenta.', time: 'hace 5 min'),
  NotifItemData(icon: '⚠️', title: 'Límite de Entretenimiento', body: 'Alcanzaste el 90% de tu presupuesto.', time: 'hace 1 h'),
  NotifItemData(icon: '🎯', title: 'Meta cumplida', body: '¡Llegaste a tu meta de ahorro de agosto!', time: 'ayer'),
  NotifItemData(icon: '📊', title: 'Resumen semanal', body: 'Tu balance esta semana fue positivo en \$510.000.', time: 'lun.'),
];

// Función que abre el panel; se llama desde el botón de campana.
// `Future<void>` porque `showModalBottomSheet` es asíncrono (retorna
// cuando el usuario cierra la hoja), aunque aquí no esperamos nada.
// 👇 Esta es la nueva función que debes usar
void showNotifPanel(BuildContext context, int idUsuario) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return NotificacionPanel(idUsuario: idUsuario);
    },
  );
}

// 👇 Este es el nuevo widget del panel (Stateful para manejar datos)
class NotificacionPanel extends StatefulWidget {
  final int idUsuario;
  const NotificacionPanel({super.key, required this.idUsuario});

  @override
  State<NotificacionPanel> createState() => _NotificacionPanelState();
}

class _NotificacionPanelState extends State<NotificacionPanel> {
  final NotificacionesServices _service = NotificacionesServices();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getNotificaciones(widget.idUsuario);
      setState(() {
        _notificaciones = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Muestra un mensaje de error si algo falla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _marcarComoLeida(int id) async {
    try {
      await _service.marcarComoLeida(id);
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.idNotificacion == id);
        if (index != -1) {
          _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
        }
      });
    } catch (e) {
      // Manejar error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Los colores y estilos son los mismos que tenías, solo que ahora usan los datos reales
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xF20f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔔 Notificaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido: carga, vacío o lista
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                : _notificaciones.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notif = _notificaciones[index];
                          // Mapeo de tipo a icono (puedes personalizarlo)
                          final Map<String, String> tipoIcono = {
                            'sistema': '📢',
                            'recordatorio': '🔔',
                            'sugerencia': '💡',
                            'alerta': '⚠️',
                            'presupuesto': '💰',
                          };
                          final icono = tipoIcono[notif.tipo] ?? '📌';

                          return GestureDetector(
                            onTap: () {
                              if (!notif.leida) {
                                _marcarComoLeida(notif.idNotificacion!);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: notif.leida
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.amber.withOpacity(0.1),
                                border: Border.all(
                                  color: notif.leida
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.amber.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    icono,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  if (!notif.leida)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      margin: const EdgeInsets
                                                          .only(right: 6),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.amber,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  Text(
                                                    notif.tipo.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: notif.leida
                                                          ? Colors.grey[400]
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatFecha(notif.fecha),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif.mensaje,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: notif.leida
                                                ? Colors.grey[500]
                                                : Colors.white,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()} sem.';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 15 · PANTALLAS DE MÓDULOS (placeholders)
// En una app Flutter real, esto se volvería una ruta con go_router
// (equivalente a react-router-dom, que ya usas en el backend/frontend
// web según tus notas de AhorrApp).
// ─────────────────────────────────────────────────────────────────────

class ModulePlaceholder extends StatelessWidget {
  final String title;
  final String emoji;
  const ModulePlaceholder({super.key, required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Tokens.textPrimary)),
            const SizedBox(height: 12),
            const Text('Esta sección está en desarrollo. Próximamente disponible.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Tokens.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 16 · DASHBOARD PRINCIPAL (scroll content)
// ─────────────────────────────────────────────────────────────────────

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    // `ListView` reemplaza al `<SingleChildScrollView><Column>` cuando
    // el contenido puede ser largo: ya trae scroll incorporado y es
    // más eficiente porque recicla widgets fuera de pantalla.
    return ListView(
      children: const [
        WelcomeSection(),
        SizedBox(height: 14),
        FinancialSummary(),
        SizedBox(height: 14),
        BolsaWidget(),
        SizedBox(height: 14),
        BudgetChart(),
        SizedBox(height: 14),
        WeeklyFlowChart(),
        // Espacio para que la nav bar flotante no tape el último elemento.
        SizedBox(height: 90),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('© 2026 AhorrApp. Todos los derechos reservados.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Tokens.textMuted)),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SECCIÓN 17 · RAÍZ DE LA APLICACIÓN
// Aquí SÍ necesitamos estado (qué pestaña está activa), así que este
// widget extiende `StatefulWidget` en vez de `StatelessWidget` — el
// equivalente directo de tu `useState` en el componente `App`.
// ─────────────────────────────────────────────────────────────────────

class AhorrApp extends StatelessWidget {
  const AhorrApp({super.key});

  @override
  Widget build(BuildContext context) {
    // `MaterialApp` es la raíz obligatoria de cualquier app Flutter con
    // Material Design; equivale a envolver tu `<App />` en un
    // `<ThemeProvider>` + `<BrowserRouter>` en la web.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AhorrApp',
      theme: ThemeData(fontFamily: 'Inter', useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}

// Un StatefulWidget en Dart siempre viene en DOS partes:
// 1) la clase pública, inmutable, que declara "qué props recibe".
// 2) la clase `State`, que SÍ puede mutar y contiene tu lógica de
//    `useState`. Es más verboso que React a propósito: separa
//    "configuración" de "estado interno".
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  // Flutter exige este método: le dice al framework qué objeto State
  // usar para este widget.
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// El `_` inicial hace esta clase privada al archivo — nadie fuera de
// este archivo puede referenciarla directamente, similar a no
// exportarla en JS.
class _DashboardScreenState extends State<DashboardScreen> {
  // Estas dos variables reemplazan tus `useState`:
  //   const [activeTab, setActiveTab] = useState<NavTab>("dashboard");
  // En Dart, en vez de una función `setActiveTab`, mutas la variable
  // DENTRO de un `setState(() { ... })`, que es lo que le avisa a
  // Flutter "repinta la pantalla, algo cambió".
  NavTab _activeTab = NavTab.dashboard;

  // (El panel de notificaciones ya no necesita su propio booleano
  // porque `showModalBottomSheet` maneja su propio ciclo de vida;
  // ahorra el `showNotif` / `setShowNotif` del original.)

  @override
  Widget build(BuildContext context) {
    // Mapa de pestaña → widget a mostrar, igual que tu `MODULE_MAP`.
    final Map<NavTab, Widget> moduleMap = {
      NavTab.dashboard: const DashboardContent(),
      NavTab.ingresos: const ModulePlaceholder(title: 'Ingresos', emoji: '💰'),
      NavTab.gastos: const ModulePlaceholder(title: 'Gastos', emoji: '💸'),
      NavTab.deudas: const ModulePlaceholder(title: 'Deudas', emoji: '🧾'),
      NavTab.imprevistos: const ModulePlaceholder(title: 'Imprevistos', emoji: '⚠️'),
      NavTab.ahorros: const ModulePlaceholder(title: 'Ahorros', emoji: '🎯'),
    };

    // `Scaffold` es la estructura base de una pantalla Material
    // (equivalente a tu `<div className="w-full min-h-screen ...">`).
    return Scaffold(
      body: Container(
        // El degradado de fondo, definido una vez en Tokens.
        decoration: const BoxDecoration(gradient: Tokens.background),
        child: SafeArea(
          // `Center` + `ConstrainedBox` reproduce tu
          // `maxWidth: 430, margin: "0 auto"` para que en pantallas
          // anchas (tablet/desktop) el contenido no se estire de más.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              // `Stack` apila widgets uno sobre otro; lo necesitamos
              // para que la BottomNavBar quede "flotando" sobre el
              // contenido scrolleable, igual que el `position: fixed`
              // del original.
              child: Stack(
                children: [
                  Column(
                    children: [
                      MobileHeader(idUsuario: 1),
                      // `Expanded` dentro de una Column hace que este
                      // hijo tome todo el alto restante — necesario
                      // para que el ListView interno pueda scrollear.
                      Expanded(child: moduleMap[_activeTab]!),
                    ],
                  ),
                  BottomNavBar(
                    active: _activeTab,
                    onChange: (tab) {
                      // `setState` es la pieza clave: sin esto, cambiar
                      // `_activeTab` no repintaría nada en pantalla.
                      setState(() {
                        _activeTab = tab;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}