import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/imprevisto_model.dart';
import '../../providers/presupuesto_provider.dart';
import '../../services/imprevistos_service.dart';
import '../../services/gastos_service.dart';
import '../../services/ingresos_service.dart';
import '../../services/widget_service.dart';
import 'agregar_imprevisto_screen.dart';

class ModuloImprevistos extends StatefulWidget {
  const ModuloImprevistos({super.key});

  @override
  State<ModuloImprevistos> createState() => _ModuloImprevistosState();
}

class _ModuloImprevistosState extends State<ModuloImprevistos>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  int? _expandedIndex;
  List<ImprevistoModel> _imprevistos = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  static const List<String> _mesesNom = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  late AnimationController _menuController;
  late List<Animation<double>> _itemAnimations;

  List<ImprevistoModel> get _filteredImprevistos {
    return _imprevistos.where((i) {
      final matchesDate = i.fecha.month == _selectedDate.month && i.fecha.year == _selectedDate.year;
      final matchesSearch = _searchQuery.isEmpty ||
          (i.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          i.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDate && matchesSearch;
    }).toList();
  }

  void _changeMonth(int delta) {
    final now = DateTime.now();
    final newDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + delta,
      1,
    );

    if (delta > 0) {
      if (newDate.year > now.year || (newDate.year == now.year && newDate.month > now.month)) {
        return;
      }
    }

    setState(() {
      _selectedDate = newDate;
    });
  }

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _itemAnimations = List.generate(1, (i) {
      return CurvedAnimation(
        parent: _menuController,
        curve: Interval(0.3 + i * 0.2, 1.0, curve: Curves.easeOutCubic),
      );
    });

    _loadImprevistos();
  }

  void _loadImprevistos() async {
    setState(() => _isLoading = true);
    final list = await ImprevistosService.obtenerImprevistos();
    setState(() {
      _imprevistos = list;
      _isLoading = false;
    });
    _updateWidget();
  }

  void _updateWidget() async {
    final now = DateTime.now();
    final gastos = await GastosService.obtenerGastos();
    double totalGastos = 0;
    for (var g in gastos.where((g) => g.fecha.month == now.month && g.fecha.year == now.year)) {
      totalGastos += g.monto;
    }

    final ingresos = await IngresosService.obtenerIngresos();
    double totalIngresos = 0;
    for (var i in ingresos.where((i) => i.fechaRegistro.month == now.month && i.fechaRegistro.year == now.year)) {
      totalIngresos += i.monto;
    }

    double totalImprevistos = 0;
    for (var imp in _imprevistos.where((imp) => imp.fecha.month == now.month && imp.fecha.year == now.year)) {
      totalImprevistos += imp.monto;
    }

    final double balance = totalIngresos - totalGastos - totalImprevistos;

    WidgetService.updateWidgetData(
      balance: _formatCurrency(balance),
      gastos: _formatCurrency(totalGastos + totalImprevistos),
      ingresos: _formatCurrency(totalIngresos),
      porcentaje: 0,
      fecha: '${_mesesNom[now.month - 1]} ${now.year}',
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _onOptionSelected(String metodo) async {
    _toggleMenu();
    if (metodo == 'Agregar manualmente') {
      final resultado = await Navigator.push<ImprevistoModel>(
        context,
        MaterialPageRoute(builder: (context) => const AgregarImprevistoScreen()),
      );
      if (resultado != null) _loadImprevistos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 30),
                  _buildListHeader(),
                  const SizedBox(height: 20),
                  _buildList(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: AnimatedBuilder(
                  animation: _menuController,
                  builder: (context, child) {
                    final t = _menuController.value;
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                      child: GestureDetector(
                        onTap: _toggleMenu,
                        child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    ignoring: !_isMenuOpen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMenuItem(
                          label: 'Agregar manualmente',
                          icon: Icons.edit,
                          animation: _itemAnimations[0],
                          onTap: () => _onOptionSelected('Agregar manualmente'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  _buildFAB(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.error, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFFFF8A8A), AppColors.error]),
        border: Border.all(color: Colors.white.withValues(alpha: _isMenuOpen ? 0.9 : 0), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggleMenu,
          child: Center(
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedDate.year == now.year && _selectedDate.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _NeumorphicIcon(icon: Icons.arrow_back_ios, size: 12, onTap: () => _changeMonth(-1)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mesesNom[_selectedDate.month - 1], style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('${_selectedDate.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(width: 12),
            if (!isCurrentMonth) _NeumorphicIcon(icon: Icons.arrow_forward_ios, size: 12, onTap: () => _changeMonth(1))
            else const SizedBox(width: 40),
          ],
        ),
        Row(
          children: [
            _NeumorphicIcon(icon: Icons.notifications_outlined, size: 22, onTap: () {}),
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF8A8A), AppColors.error])),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return _NeumorphicContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar imprevisto...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: AppColors.error, size: 20),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    String formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '${amount < 0 ? "-" : ""}\$$formatted';
  }

  Widget _buildSummaryCard() {
    final provider = context.watch<PresupuestoProvider>();
    final periodo = provider.periodoActivo;
    final double presupuestoImprevistos = periodo?.montoImprevistos ?? 0;

    double total = 0;
    for (var i in _filteredImprevistos) {
      total += i.monto;
    }

    final double disponible = presupuestoImprevistos - total;
    final double porcentaje = presupuestoImprevistos > 0 ? (total / presupuestoImprevistos).clamp(0.0, 1.0) : 0.0;

    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GASTO POR IMPREVISTOS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PRESUPUESTO MES', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(presupuestoImprevistos), style: const TextStyle(color: AppPresupuestoColors.imprevistos, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(_formatCurrency(total), style: const TextStyle(color: AppPresupuestoColors.imprevistos, fontSize: 32, fontWeight: FontWeight.bold))),
              const Icon(Icons.warning_amber_rounded, color: AppPresupuestoColors.imprevistos, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(porcentaje, AppPresupuestoColors.imprevistos),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(porcentaje * 100).toStringAsFixed(0)}% utilizado', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text('Disponible: ${_formatCurrency(disponible)}', style: TextStyle(color: disponible >= 0 ? AppPresupuestoColors.imprevistos : AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
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
          widthFactor: porcentaje,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Imprevistos del mes', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${_filteredImprevistos.length} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildList() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: AppColors.error)));
    final filtered = _filteredImprevistos.reversed.toList();
    if (filtered.isEmpty) return Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [Icon(Icons.receipt_long, color: AppColors.textSecondary.withValues(alpha: 0.3), size: 64), const SizedBox(height: 16), const Text('No hay imprevistos registrados', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))])));
    return Column(children: List.generate(filtered.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildCard(filtered[index], index))));
  }

  Widget _buildCard(ImprevistoModel item, int index) {
    final isExpanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: _NeumorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(item.icono, color: item.color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.titulo, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(item.subtitulo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
                  Text('-${_formatCurrency(item.monto)}', style: const TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  AnimatedRotation(turns: isExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20)),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    Row(children: [_buildDetailItem('CATEGORÍA', item.titulo), _buildDetailItem('FECHA', '${item.fecha.day.toString().padLeft(2, '0')}/${item.fecha.month.toString().padLeft(2, '0')}/${item.fecha.year}')]),
                    const SizedBox(height: 18),
                    Row(children: [_buildDetailItem('DESCRIPCIÓN', item.descripcion ?? 'Sin descripción'), _buildDetailItem('MONTO', '-${_formatCurrency(item.monto)}', color: AppColors.error)]),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton(label: 'Editar', icon: Icons.edit_outlined, color: AppColors.error, onTap: () async {
                          final resultado = await Navigator.push<ImprevistoModel>(context, MaterialPageRoute(builder: (context) => AgregarImprevistoScreen(imprevistoParaEditar: item)));
                          if (resultado != null) _loadImprevistos();
                        })),
                        const SizedBox(width: 16),
                        Expanded(child: _buildActionButton(label: 'Eliminar', icon: Icons.delete_outline, color: AppColors.error, onTap: () => _mostrarConfirmacion(item))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacion(ImprevistoModel item) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Confirmar eliminación', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: const Text('¿Seguro de que quieres eliminar este registro?', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (item.id != null) {
                  final success = await ImprevistosService.eliminarImprevisto(item.id!);
                  if (success) _loadImprevistos();
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.2), foregroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)), const SizedBox(height: 5), Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)]));
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4), width: 1)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))])));
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
