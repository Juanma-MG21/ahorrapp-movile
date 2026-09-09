import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../services/auth_service.dart';
import 'calendario/calendario_screen.dart';
import 'gastos/modulo_gastos.dart';
import 'home/home_screen.dart';
import 'ingresos/modulo_ingresos.dart';
import 'imprevistos/modulo_imprevistos.dart';
import 'ahorros/modulo_ahorros.dart';
import 'deudas/modulo_deudas.dart';
import 'presupuestos/modulo_presupuestos.dart';

/// Metadata (icono + label) de cada pantalla accesible desde el menú
/// "Más". El índice de cada _MenuItem debe corresponder al mismo
/// índice en `_pantallasSecundarias` (abajo), para que la hoja sepa
/// qué widget mostrar al seleccionarlo.
///
/// Para agregar una vista nueva en el futuro (ej. "Reportes"):
///   1. Agrega su _MenuItem aquí.
///   2. Agrega su widget en `_pantallasSecundarias`, en la misma posición.
class _MenuItem {
  const _MenuItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const List<_MenuItem> _itemsMas = [
  _MenuItem(icon: Icons.emergency_outlined, label: 'Imprevistos'),
  _MenuItem(icon: Icons.savings_outlined, label: 'Ahorros'),
  _MenuItem(icon: Icons.credit_card, label: 'Deudas'),
  _MenuItem(icon: Icons.calendar_month_outlined, label: 'Calendario'),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  // Pantallas fijas del bottom nav (índices 0-3).
  final List<Widget> _pantallasPrincipales = const [
    HomeScreen(),
    ModuloIngresos(),
    ModuloGastos(),
    ModuloPresupuestos(),
  ];

  // Pantallas accesibles desde "Más", alineadas 1 a 1 con _itemsMas.
  final List<Widget> _pantallasSecundarias = const [
    ModuloImprevistos(),
    ModuloAhorros(),
    ModuloDeudas(),
    CalendarioScreen(),
  ];

  // 0-3 = una de las pestañas fijas. 4 = estamos mostrando algo de "Más".
  int _tabPrincipal = 2; // Empezamos en Gastos.

  // Cuál de _pantallasSecundarias se muestra cuando _tabPrincipal == 4.
  int _indiceSecundario = 0;

  bool get _mostrandoSecundaria => _tabPrincipal == 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabPrincipal);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _seleccionarPrincipal(int index) {
    setState(() => _tabPrincipal = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _abrirMenuMas() async {
    final seleccion = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MenuMasSheet(indiceActivo: _mostrandoSecundaria ? _indiceSecundario : null),
    );
    if (seleccion == null) return;
    setState(() {
      _tabPrincipal = 4;
      _indiceSecundario = seleccion;
    });
    _pageController.animateToPage(
      4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _tabPrincipal = index);
        },
        children: [
          ..._pantallasPrincipales,
          IndexedStack(
            index: _indiceSecundario,
            children: _pantallasSecundarias,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Inicio', 0),
                _buildNavItem(Icons.arrow_upward, 'Ingresos', 1),
                _buildNavItem(Icons.account_balance_wallet, 'Gastos', 2),
                _buildNavItem(Icons.pie_chart_outline, 'Presupuestos', 3),
                _buildMasNavItem(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = !_mostrandoSecundaria && _tabPrincipal == index;
    final color = isActive ? AppColors.accent : AppColors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: () => _seleccionarPrincipal(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasNavItem() {
    final bool isActive = _mostrandoSecundaria;
    final color = isActive ? AppColors.accent : AppColors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: _abrirMenuMas,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              isActive ? _itemsMas[_indiceSecundario].label : 'Más',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior con la lista de pantallas secundarias. Devuelve
/// (mediante Navigator.pop) el índice elegido, o null si se cerró sin
/// elegir nada.
class _MenuMasSheet extends StatelessWidget {
  const _MenuMasSheet({required this.indiceActivo});
  final int? indiceActivo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const Text(
              'Más',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_itemsMas.length, (i) {
              final item = _itemsMas[i];
              final activo = indiceActivo == i;
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => Navigator.of(context).pop(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: activo ? AppColors.accent : AppColors.textPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: activo ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (activo)
                        const Icon(Icons.check, color: AppColors.accent, size: 18),
                    ],
                  ),
                ),
              );
            }),
            const Divider(color: AppColors.borderLight, height: 32),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () async {
                await AuthService.instance.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}