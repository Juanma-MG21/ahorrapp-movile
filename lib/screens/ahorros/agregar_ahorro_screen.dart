import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/ahorro_model.dart';
import '../../models/categoria_model.dart';
import '../../services/ahorros_service.dart';
import '../../services/categorias_service.dart';
import '../../widgets/neumorphic_widgets.dart';

class AgregarAhorroScreen extends StatefulWidget {
  final AhorroModel? ahorroParaEditar;
  const AgregarAhorroScreen({super.key, this.ahorroParaEditar});

  @override
  State<AgregarAhorroScreen> createState() => _AgregarAhorroScreenState();
}

class _AgregarAhorroScreenState extends State<AgregarAhorroScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  DateTime? _fechaLimite;
  int? _selectedCategoriaId;
  List<CategoriaModel> _categorias = [];
  bool _isSaving = false;
  bool _showScrollIndicator = false;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    if (widget.ahorroParaEditar != null) {
      _nombreController.text = widget.ahorroParaEditar!.nombre;
      _montoController.text = widget.ahorroParaEditar!.montoObjetivo.toStringAsFixed(0);
      _descripcionController.text = widget.ahorroParaEditar!.descripcion ?? '';
      _fechaLimite = widget.ahorroParaEditar!.fechaLimite;
      _selectedCategoriaId = widget.ahorroParaEditar!.idCategoria;
    }
  }

  void _loadCategorias() async {
    try {
      final cats = await CategoriasService.obtenerCategorias();
      setState(() {
        _categorias = cats;
      });
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  CategoriaModel? get _categoriaSeleccionada {
    if (_selectedCategoriaId == null) return null;
    try {
      return _categorias.firstWhere((c) => c.id == _selectedCategoriaId);
    } catch (_) {
      return null;
    }
  }

  String _formatFecha(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  void _guardar() async {
    final nombre = _nombreController.text.trim();
    final monto = double.tryParse(_montoController.text) ?? 0;

    if (nombre.isEmpty || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un nombre y monto válido (>0)')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ahorro = AhorroModel(
      id: widget.ahorroParaEditar?.id,
      nombre: nombre,
      montoObjetivo: monto,
      montoActual: widget.ahorroParaEditar?.montoActual ?? 0,
      fechaLimite: _fechaLimite,
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      idCategoria: _selectedCategoriaId,
      estado: widget.ahorroParaEditar?.estado ?? 'Activo',
    );

    try {
      if (ahorro.id == null) {
        await AhorrosService.crearAhorro(ahorro);
      } else {
        await AhorrosService.actualizarAhorro(ahorro.id!, ahorro);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
              const SizedBox(height: 26),
              _buildFormCard(),
              const SizedBox(height: 28),
              _buildGuardarButton(),
              const SizedBox(height: 20),
              _buildCancelarButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return NeumorphicHeader(
      title: widget.ahorroParaEditar != null ? 'Editar Meta' : 'Nueva Meta',
      subtitle: 'Registrar objetivo de ahorro',
      onBack: () => Navigator.pop(context),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NeumorphicLabel(text: 'Nombre de la meta', required: true),
        const SizedBox(height: 8),
        NeumorphicTextField(
          controller: _nombreController,
          hint: 'Ej: Viaje a la playa',
          icon: Icons.badge_outlined,
          iconColor: AppModuleColors.ahorros,
        ),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Monto objetivo', required: true),
        const SizedBox(height: 8),
        NeumorphicTextField(
          controller: _montoController,
          hint: '\$0',
          icon: Icons.payments_outlined,
          iconColor: AppModuleColors.ahorros,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Categoría'),
        const SizedBox(height: 8),
        _buildCategoriaField(),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Descripción'),
        const SizedBox(height: 8),
        NeumorphicTextField(
          controller: _descripcionController,
          hint: 'Ej: Para el retiro del 2024',
          icon: Icons.notes_rounded,
          iconColor: AppModuleColors.ahorros,
          maxLines: 3,
        ),
        const SizedBox(height: 18),
        const NeumorphicLabel(text: 'Fecha límite (opcional)'),
        const SizedBox(height: 8),
        _buildFechaField(),
      ],
    );
  }

  Widget _buildCategoriaField() {
    final cat = _categoriaSeleccionada;
    return NeumorphicActionField(
      onTap: _showCategorySheet,
      icon: cat != null ? _getIconForCategory(cat.nombre) : Icons.savings_outlined,
      iconColor: cat != null ? _getColorForCategory(cat.nombre) : AppModuleColors.ahorros,
      value: cat?.nombre,
      hint: 'Seleccionar categoría',
    );
  }

  Widget _buildFechaField() {
    return NeumorphicActionField(
      onTap: _showCalendarSheet,
      icon: Icons.calendar_today,
      iconColor: AppModuleColors.ahorros,
      value: _fechaLimite == null ? null : _formatFecha(_fechaLimite!),
      hint: 'Seleccionar fecha',
    );
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

  void _showCategorySheet() => _showNeumorphicSheet(_buildCategorySheet());
  void _showCalendarSheet() => _showNeumorphicSheet(_buildCalendarSheet());

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
                          if (scroll.metrics.extentAfter > 10) {
                            if (!_showScrollIndicator) setSheetState(() => _showScrollIndicator = true);
                          } else {
                            if (_showScrollIndicator) setSheetState(() => _showScrollIndicator = false);
                          }
                          return false;
                        },
                        child: ListView.separated(
                          controller: _categoryScrollController,
                          shrinkWrap: true,
                          itemCount: _categorias.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_categoryScrollController.hasClients) {
                                final hasMore = _categoryScrollController.position.extentAfter > 10;
                                if (hasMore != _showScrollIndicator) setSheetState(() => _showScrollIndicator = hasMore);
                              }
                            });
                            return _buildCategoryCard(_categorias[index]);
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
    final isSelected = _selectedCategoriaId == cat.id;
    final icon = _getIconForCategory(cat.nombre);
    final color = _getColorForCategory(cat.nombre);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoriaId = cat.id);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: AppModuleColors.ahorros.withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
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

  Widget _buildCalendarSheet() {
    final base = _fechaLimite ?? DateTime.now();
    final year = base.year;
    final month = base.month;
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
                final isSelected = _fechaLimite != null && day == _fechaLimite!.day && month == _fechaLimite!.month && year == _fechaLimite!.year;
                final isPast = dayDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
                return GestureDetector(
                  onTap: isPast ? null : () { setState(() => _fechaLimite = dayDate); Navigator.pop(context); },
                  child: Opacity(
                    opacity: isPast ? 0.25 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: isSelected ? const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFFD700), AppModuleColors.ahorros])) : const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: Center(child: Text('$day', style: TextStyle(color: isSelected ? Colors.black : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
                    ),
                  ),
                );
              },
            ),
            if (_fechaLimite != null) ...[
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () { setState(() => _fechaLimite = null); Navigator.pop(context); }, child: const Text('Quitar fecha', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return NeumorphicPrimaryButton(
      label: 'Guardar Meta',
      onTap: _guardar,
      color: AppModuleColors.ahorros,
      isLoading: _isSaving,
    );
  }

  Widget _buildCancelarButton() {
    return NeumorphicSecondaryButton(
      label: 'Cancelar',
      onTap: () => Navigator.pop(context),
    );
  }

  IconData _getIconForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación': return Icons.restaurant;
      case 'Transporte': return Icons.directions_bus;
      case 'Salud': return Icons.medical_services;
      case 'Educación': return Icons.school;
      case 'Entretenimiento': return Icons.movie;
      case 'Servicios': return Icons.home;
      default: return Icons.savings_outlined;
    }
  }

  Color _getColorForCategory(String nombre) {
    switch (nombre) {
      case 'Alimentación': return const Color(0xFFA8A2FF);
      case 'Transporte': return const Color(0xFF60A5FA);
      case 'Salud': return const Color(0xFFFF6B6B);
      case 'Educación': return const Color(0xFF4ADE80);
      case 'Entretenimiento': return const Color(0xFFC084FC);
      case 'Servicios': return const Color(0xFFFF8C4A);
      default: return AppModuleColors.ahorros;
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
            child: const Icon(Icons.keyboard_arrow_down, color: AppModuleColors.ahorros, size: 24),
          ),
        );
      },
    );
  }
}
