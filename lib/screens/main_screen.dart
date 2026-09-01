import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import 'calendario/calendario_screen.dart';
import 'gastos/modulo_gastos.dart';
import 'home/home_screen.dart';
import 'ingresos/modulo_ingresos.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Empezamos en Gastos para coincidir con el estado inicial previo

  final List<Widget> _screens = [
    const HomeScreen(),
    const ModuloIngresos(),
    const ModuloGastos(),
    const Center(child: Text('Ahorros', style: TextStyle(color: AppColors.textPrimary))),
    const Center(child: Text('Más', style: TextStyle(color: AppColors.textPrimary))),
    const CalendarioScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, -4),
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
              _buildNavItem(Icons.savings_outlined, 'Ahorros', 3),
              _buildNavItem(Icons.more_horiz, 'Más', 4),
              _buildNavItem(Icons.calendar_month_outlined, 'Calendario', 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    final color = isActive ? AppColors.accent : AppColors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}