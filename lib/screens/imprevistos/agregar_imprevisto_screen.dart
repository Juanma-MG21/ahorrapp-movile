import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../models/imprevisto_model.dart';
import '../../models/categoria_model.dart';
import '../../services/imprevistos_service.dart';
import '../../core/network/api_client.dart';
import '../../widgets/neumorphic_widgets.dart';

class AgregarImprevistoScreen extends StatefulWidget {
  final ImprevistoModel? imprevistoParaEditar;
  const AgregarImprevistoScreen({super.key, this.imprevistoParaEditar});

  @override
  State<AgregarImprevistoScreen> createState() => _AgregarImprevistoScreenState();
}

class _AgregarImprevistoScreenState extends State<AgregarImprevistoScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  DateTime _fecha = DateTime.now();
  int? _idCategoria;

  List<CategoriaModel> _listaCategorias = [];
  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _showScrollIndicator = false;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final cats = await ImprevistosService.obtenerCategorias();
    if (mounted) {
      setState(() {
        _listaCategorias = cats;
        _isLoadingData = false;
        if (widget.imprevistoParaEditar != null) {
          final i = widget.imprevistoParaEditar!;
          _montoController.text = i.monto % 1 == 0 ? i.monto.toStringAsFixed(0) : i.monto.toStringAsFixed(2).replaceAll('.', ',');
          _descripcionController.text = i.descripcion ?? '';
          _fecha = i.fecha;
          _idCategoria = i.idCategoria;
          if (_idCategoria == null && i.categoriaNombre != null) {
            final sugerida = _listaCategorias.where((c) => c.nombre.toLowerCase() == i.categoriaNombre!.toLowerCase());
            if (sugerida.isNotEmpty) { _idCategoria = sugerida.first.id; }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  CategoriaModel? get _categoriaSeleccionada {
    if (_idCategoria == null) return null;
    try { return _listaCategorias.firstWhere((c) => c.id == _idCategoria); } catch (_) { return null; }
  }

  String _formatFecha(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  Future<void> _showNeumorphicSheet(Widget sheet) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeOut.transform(animation.value);
            return Stack(
              children: [
                GestureDetector(onTap: () => Navigator.of(context).pop(), child: Container(color: Colors.black.withValues(alpha: 0.4 * t))),
                Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t), child: const SizedBox.expand())),
                Positioned(left: 0, right: 0, bottom: 0, child: FractionalTranslation(translation: Offset(0, 1 - t), child: Material(type: MaterialType.transparency, child: sheet))),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalendarSheet() => _showNeumorphicSheet(_buildCalendarSheet());
  void _showCategorySheet() => _showNeumorphicSheet(_buildCategorySheet());

  void _guardar() async {
    String montoStr = _montoController.text.replaceAll('\$', '');
    if (montoStr.contains(',')) { montoStr = montoStr.replaceAll('.', '').replaceAll(',', '.'); } else { montoStr = montoStr.replaceAll('.', ''); }
    final monto = double.tryParse(montoStr) ?? 0.0;
    if (monto <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un monto positivo'))); return; }
    if (_descripcionController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La descripción es obligatoria'))); return; }
    setState(() => _isSaving = true);
    final cat = _categoriaSeleccionada;
    final imprevisto = ImprevistoModel(id: widget.imprevistoParaEditar?.id, idCategoria: cat?.id, descripcion: _descripcionController.text.trim(), monto: monto, fecha: _fecha);
    ImprevistoModel? resultado;
    try {
      if (imprevisto.id == null) {
        final nuevoId = await ImprevistosService.crearImprevisto(imprevisto);
        resultado = ImprevistoModel(id: nuevoId, idCategoria: imprevisto.idCategoria, descripcion: imprevisto.descripcion, monto: imprevisto.monto, fecha: imprevisto.fecha);
      } else {
        await ImprevistosService.actualizarImprevisto(imprevisto.id!, imprevisto);
        resultado = imprevisto;
      }
    } on ApiException catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error)); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocurrió un error inesperado'), backgroundColor: AppColors.error)); }
    }
    if (mounted) { setState(() => _isSaving = false); if (resultado != null) { Navigator.pop(context, resultado); } }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppModuleColors.imprevistos)));
    }
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
              const SizedBox(height: 26),
              _buildFormCard(),
              const SizedBox(height: 28),
              _buildGuardarButton(),
              const SizedBox(height: 12),
              const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Ahorrapp puede cometer errores. Verifica siempre la información antes de guardar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w600)))),
              const SizedBox(height: 20),
              _buildCancelarButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return NeumorphicHeader(
      title: widget.imprevistoParaEditar != null ? 'Editar imprevisto' : 'Registrar imprevisto',
      subtitle: widget.imprevistoParaEditar != null ? 'Modificar registro' : 'Nuevo imprevisto',
      onBack: () => Navigator.pop(context),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NeumorphicLabel(text: 'Monto', required: true),
        const SizedBox(height: 8),
        NeumorphicTextField(controller: _montoController, hint: '\$0', icon: Icons.payments_outlined, iconColor: AppModuleColors.imprevistos, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Descripción', required: true),
        const SizedBox(height: 8),
        NeumorphicTextField(controller: _descripcionController, hint: 'Ej: Reparación de tubería', icon: Icons.notes_rounded, iconColor: AppModuleColors.imprevistos),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Fecha del evento', required: true),
        const SizedBox(height: 8),
        _buildFechaField(),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Categoría'),
        const SizedBox(height: 8),
        _buildCategoriaField(),
      ],
    );
  }

  Widget _buildFechaField() {
    return NeumorphicActionField(onTap: _showCalendarSheet, icon: Icons.calendar_month, iconColor: AppModuleColors.imprevistos, value: _formatFecha(_fecha), hint: 'Seleccionar fecha');
  }

  Widget _buildCategoriaField() {
    final cat = _categoriaSeleccionada;
    return NeumorphicActionField(onTap: _showCategorySheet, icon: cat != null ? _getIconForCategory(cat.nombre) : Icons.category_outlined, iconColor: AppModuleColors.imprevistos, value: cat?.nombre, hint: 'Sin seleccionar');
  }

  Widget _buildCalendarSheet() {
    final year = _fecha.year;
    final month = _fecha.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = DateTime(year, month, 1).weekday - 1;
    const List<String> meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.navInactive, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('${meses[month - 1]} $year', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Row(children: ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))))).toList()),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = index - offset + 1;
                final dayDate = DateTime(year, month, day);
                final isSelected = day == _fecha.day;
                final isFuture = dayDate.isAfter(DateTime.now());
                return GestureDetector(
                  onTap: isFuture ? null : () { setState(() => _fecha = dayDate); Navigator.pop(context); },
                  child: Opacity(
                    opacity: isFuture ? 0.25 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFF8A8A), AppModuleColors.imprevistos])) : const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: Center(child: Text('$day', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.navInactive, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Seleccionar categoría', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scroll) {
                          if (scroll.metrics.extentAfter > 10) { if (!_showScrollIndicator) setSheetState(() => _showScrollIndicator = true); } else { if (_showScrollIndicator) setSheetState(() => _showScrollIndicator = false); }
                          return false;
                        },
                        child: ListView.separated(
                          controller: _categoryScrollController,
                          shrinkWrap: true,
                          itemCount: _listaCategorias.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            WidgetsBinding.instance.addPostFrameCallback((_) { if (_categoryScrollController.hasClients) { final hasMore = _categoryScrollController.position.extentAfter > 10; if (hasMore != _showScrollIndicator) setSheetState(() => _showScrollIndicator = hasMore); } });
                            return _buildCategoryCard(_listaCategorias[index]);
                          },
                        ),
                      ),
                    ),
                    if (_showScrollIndicator) Positioned(bottom: 0, child: _ArrowIndicator()),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoriaModel cat) {
    final isSelected = _idCategoria == cat.id;
    final icon = _getIconForCategory(cat.nombre);
    return GestureDetector(
      onTap: () { setState(() => _idCategoria = cat.id); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: AppModuleColors.imprevistos.withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppModuleColors.imprevistos.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppModuleColors.imprevistos, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              if (cat.descripcion != null) Text(cat.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return NeumorphicPrimaryButton(label: widget.imprevistoParaEditar != null ? 'Guardar cambios' : 'Registrar imprevisto', onTap: _guardar, color: AppModuleColors.imprevistos, isLoading: _isSaving);
  }

  Widget _buildCancelarButton() {
    return NeumorphicSecondaryButton(label: 'Cancelar', onTap: () => Navigator.pop(context));
  }

  IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Salud': return Icons.medical_services;
      case 'Hogar': return Icons.home_repair_service;
      case 'Vehículo': return Icons.directions_car;
      case 'Emergencia': return Icons.emergency;
      case 'Mascota': return Icons.pets;
      case 'Otros': return Icons.report_problem;
      default: return Icons.warning_amber_rounded;
    }
  }
}

class _ArrowIndicator extends StatefulWidget {
  @override
  State<_ArrowIndicator> createState() => _ArrowIndicatorState();
}

class _ArrowIndicatorState extends State<_ArrowIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
            child: const Icon(Icons.keyboard_arrow_down, color: AppModuleColors.imprevistos, size: 24),
          ),
        );
      },
    );
  }
}
