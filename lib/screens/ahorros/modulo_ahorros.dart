import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/ahorro_model.dart';
import '../../providers/presupuesto_provider.dart';
import '../../services/ahorros_service.dart';
import 'agregar_ahorro_screen.dart';

class ModuloAhorros extends StatefulWidget {
  const ModuloAhorros({super.key});

  @override
  State<ModuloAhorros> createState() => _ModuloAhorrosState();
}

class _ModuloAhorrosState extends State<ModuloAhorros> {
  List<AhorroModel> _ahorros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAhorros();
  }

  void _loadAhorros() async {
    setState(() => _isLoading = true);
    try {
      final list = await AhorrosService.obtenerAhorros();
      setState(() {
        _ahorros = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando ahorros: $e');
      setState(() {
        _ahorros = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar metas: $e')),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    String integerPart = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '\$$integerPart';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSummaryCard(),
              const SizedBox(height: 30),
              _buildSectionHeader(),
              const SizedBox(height: 20),
              _buildAhorrosList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarAhorroScreen()),
          );
          if (result == true) _loadAhorros();
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis Ahorros', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Gestiona tus metas financieras', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        _NeumorphicIcon(icon: Icons.refresh, size: 20, onTap: _loadAhorros),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final provider = context.watch<PresupuestoProvider>();
    final periodo = provider.periodoActivo;
    final double presupuestoAhorros = periodo?.montoAhorros ?? 0;

    double totalAhorrado = 0;
    double totalObjetivo = 0;
    for (var a in _ahorros) {
      totalAhorrado += a.montoActual;
      totalObjetivo += a.montoObjetivo;
    }
    final double progresoGeneral = totalObjetivo > 0 ? (totalAhorrado / totalObjetivo) : 0;

    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL AHORRADO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('META MES', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(presupuestoAhorros), style: const TextStyle(color: AppPresupuestoColors.ahorros, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(totalAhorrado), style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildProgressBar(progresoGeneral, AppPresupuestoColors.ahorros),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progresoGeneral * 100).toStringAsFixed(1)}% del objetivo total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('Meta Global: ${_formatCurrency(totalObjetivo)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double porcentaje, Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(10)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: porcentaje.clamp(0.0, 1.0),
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Text('Metas de Ahorro', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildAhorrosList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (_ahorros.isEmpty) return const Center(child: Text('No tienes metas de ahorro aún', style: TextStyle(color: AppColors.textSecondary)));
    
    return Column(
      children: _ahorros.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildAhorroCard(a),
      )).toList(),
    );
  }

  Widget _buildAhorroCard(AhorroModel ahorro) {
    return _NeumorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppPresupuestoColors.ahorros.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.savings, color: AppPresupuestoColors.ahorros, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ahorro.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Faltan ${_formatCurrency(ahorro.restante)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(_formatCurrency(ahorro.montoActual), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(ahorro.progreso, AppPresupuestoColors.ahorros),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(ahorro.progreso * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 20),
                    onPressed: () => _mostrarDialogoAbono(ahorro),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                    onPressed: () async {
                       final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AgregarAhorroScreen(ahorroParaEditar: ahorro)),
                      );
                      if (result == true) _loadAhorros();
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAbono(AhorroModel ahorro) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Registrar Abono', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Monto a abonar',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                final monto = double.tryParse(controller.text);
                if (monto != null && monto > 0 && ahorro.id != null) {
                  try {
                    await AhorrosService.registrarAbono(ahorro, monto);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadAhorros();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saldo actualizado con éxito')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al abonar: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
              child: const Text('Abonar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  const _NeumorphicContainer({required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-4, -4), blurRadius: 12)]), child: child);
  }
}

class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _NeumorphicIcon({required this.icon, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8)]), child: Icon(icon, color: AppColors.textSecondary, size: size)));
  }
}
