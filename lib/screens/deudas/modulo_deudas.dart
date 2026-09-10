import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/deuda_model.dart';
import '../../providers/presupuesto_provider.dart';
import '../../services/deudas_service.dart';
import 'agregar_deuda_screen.dart';

class ModuloDeudas extends StatefulWidget {
  const ModuloDeudas({super.key});

  @override
  State<ModuloDeudas> createState() => _ModuloDeudasState();
}

class _ModuloDeudasState extends State<ModuloDeudas> {
  List<DeudaModel> _deudas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeudas();
  }

  void _loadDeudas() async {
    setState(() => _isLoading = true);
    try {
      final list = await DeudasService.obtenerDeudas();
      setState(() {
        _deudas = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
              _buildDeudasList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarDeudaScreen()),
          );
          if (result == true) _loadDeudas();
        },
        backgroundColor: AppColors.error,
        child: const Icon(Icons.add, color: Colors.white),
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
            Text('Mis Deudas', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Controla tus obligaciones', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        _NeumorphicIcon(icon: Icons.refresh, size: 20, onTap: _loadDeudas),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final provider = context.watch<PresupuestoProvider>();
    final periodo = provider.periodoActivo;
    final double presupuestoDeudas = periodo?.montoDeudas ?? 0;

    double totalDeuda = 0;
    double totalPendiente = 0;
    for (var d in _deudas) {
      totalDeuda += d.monto;
      totalPendiente += d.montoRestante;
    }
    
    // El progreso en deudas puede ser complejo. 
    // Usaremos el progreso real del pago de deudas para la barra superior, 
    // pero compararemos contra el presupuesto mensual asignado si es necesario.
    final double progresoGeneral = totalDeuda > 0 ? (1 - (totalPendiente / totalDeuda)) : 0;

    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SALDO TOTAL PENDIENTE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PRESUPUESTO MES', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(presupuestoDeudas), style: const TextStyle(color: AppPresupuestoColors.deudas, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(totalPendiente), style: const TextStyle(color: AppPresupuestoColors.deudas, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildProgressBar(progresoGeneral, AppPresupuestoColors.deudas),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progresoGeneral * 100).toStringAsFixed(1)}% pagado', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('Total: ${_formatCurrency(totalDeuda)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    return const Text('Lista de Deudas', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildDeudasList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.error));
    if (_deudas.isEmpty) return const Center(child: Text('No tienes deudas registradas', style: TextStyle(color: AppColors.textSecondary)));
    
    return Column(
      children: _deudas.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildDeudaCard(d),
      )).toList(),
    );
  }

  Widget _buildDeudaCard(DeudaModel deuda) {
    return _NeumorphicContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1),borderRadius: BorderRadius.circular(12),),
                child: Icon(deuda.icono, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deuda.fuente, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(deuda.cuotasTexto, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(_formatCurrency(deuda.montoRestante), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(deuda.progresoCuotas, AppColors.error),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(deuda.progresoCuotas * 100).toStringAsFixed(0)}% amortizado', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                    onPressed: () => _confirmarPagoCuota(deuda),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                    onPressed: () async {
                       final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AgregarDeudaScreen(deudaParaEditar: deuda)),
                      );
                      if (result == true) _loadDeudas();
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

  void _confirmarPagoCuota(DeudaModel deuda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Registrar pago', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('¿Confirmas el pago de la siguiente cuota a ${deuda.fuente}?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await DeudasService.pagarCuota(deuda);
              if (context.mounted) {
                Navigator.pop(context);
                _loadDeudas();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmar'),
          ),
        ],
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
