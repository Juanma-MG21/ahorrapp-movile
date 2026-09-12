import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/deuda_model.dart';
import '../../models/categoria_model.dart';
import '../../services/deudas_service.dart';
import '../../services/categorias_service.dart';
import '../../core/network/api_client.dart';

class AgregarDeudaScreen extends StatefulWidget {
  final DeudaModel? deudaParaEditar;
  const AgregarDeudaScreen({super.key, this.deudaParaEditar});

  @override
  State<AgregarDeudaScreen> createState() => _AgregarDeudaScreenState();
}

class _AgregarDeudaScreenState extends State<AgregarDeudaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuenteController = TextEditingController();
  final _montoController = TextEditingController();
  final _cuotasController = TextEditingController();
  final _descripcionController = TextEditingController();

  DateTime? _fechaFin;
  bool _isSaving = false;

  List<CategoriaModel> _categorias = [];
  int? _categoriaSeleccionada;
  bool _isLoadingCategorias = true;
  bool _showScrollIndicator = false;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.deudaParaEditar != null) {
      final d = widget.deudaParaEditar!;
      _fuenteController.text = d.fuente;
      // Muestra el monto completo (sin truncar decimales); solo omite el
      // ".00" cuando el valor es un entero exacto, para no perder precisión
      // en montos como 1500.50 al editar.
      _montoController.text = (d.monto % 1 == 0)
          ? d.monto.toStringAsFixed(0)
          : d.monto.toString();
      _cuotasController.text = d.cuotasTotal?.toString() ?? '';
      _descripcionController.text = d.descripcion ?? '';
      _fechaFin = d.fechaFin;
      _categoriaSeleccionada = d.idCategoria;
    }
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await CategoriasService.obtenerCategorias();
      if (!mounted) return;
      setState(() {
        _categorias = categorias.where((c) => c.activa).toList();
        _isLoadingCategorias = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategorias = false);
    }
  }

  @override
  void dispose() {
    _fuenteController.dispose();
    _montoController.dispose();
    _cuotasController.dispose();
    _descripcionController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  CategoriaModel? get _categoriaSeleccionadaModel {
    if (_categoriaSeleccionada == null) return null;
    try {
      return _categorias.firstWhere((c) => c.id == _categoriaSeleccionada);
    } catch (_) {
      return null;
    }
  }

  String _formatFecha(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  // Mismo patrón de bottom sheet con transición/blur que usan gastos,
  // ingresos, ahorros e imprevistos, para que el selector de fecha y el
  // de categoría se vean y se sientan igual en todos los módulos.
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(color: Colors.black.withValues(alpha: 0.4 * t)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - t),
                    child: Material(type: MaterialType.transparency, child: sheet),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCalendarSheet() => _showNeumorphicSheet(_buildCalendarSheet());
  void _showCategorySheet() => _showNeumorphicSheet(_buildCategorySheet());

  void _seleccionarFechaFin() => _showCalendarSheet();

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final deuda = DeudaModel(
      id: widget.deudaParaEditar?.id,
      fuente: _fuenteController.text.trim(),
      monto: double.parse(_montoController.text),
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      cuotasTotal: int.tryParse(_cuotasController.text),
      cuotasPagadas: widget.deudaParaEditar?.cuotasPagadas ?? 0,
      fechaFin: _fechaFin,
      fechaInicio: widget.deudaParaEditar?.fechaInicio ?? DateTime.now(),
      idCategoria: _categoriaSeleccionada,
      estado: widget.deudaParaEditar?.estado ?? 'pendiente',
    );

    try {
      if (deuda.id == null) {
        await DeudasService.crearDeuda(deuda);
      } else {
        await DeudasService.actualizarDeuda(deuda.id!, deuda);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 26),
                _buildFormCard(),
                const SizedBox(height: 28),
                _buildGuardarButton(),
                const SizedBox(height: 12),
                _buildCancelarButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _NeumorphicIcon(icon: Icons.arrow_back, size: 20, onTap: () => Navigator.pop(context)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deudaParaEditar != null ? 'Editar Deuda' : 'Nueva Deuda',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Registrar obligación financiera', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return _NeumorphicContainer(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Acreedor / Fuente', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _fuenteController,
            hint: 'Ej: Banco, Juan Pérez',
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 18),
          _buildLabel('Monto Total', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _montoController,
            hint: '\$0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
          ),
          const SizedBox(height: 18),
          _buildLabel('Descripción'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descripcionController,
            hint: 'Ej: Préstamo para el carro',
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          _buildLabel('Categoría'),
          const SizedBox(height: 8),
          _buildCategoriaField(),
          const SizedBox(height: 18),
          _buildLabel('Número de Cuotas'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _cuotasController,
            hint: 'Ej: 12',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          _buildLabel('Fecha Estimada de Fin'),
          const SizedBox(height: 8),
          _buildFechaFinField(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600))
          else
            const TextSpan(text: ' (Opcional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInsetBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return _buildInsetBox(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildCategoriaField() {
    final cat = _categoriaSeleccionadaModel;
    return _buildInsetBox(
      child: InkWell(
        onTap: _isLoadingCategorias ? null : _showCategorySheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (_isLoadingCategorias)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                )
              else if (cat != null) ...[
                Icon(_getIconForCategory(cat.nombre), color: _getColorForCategory(cat.nombre), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(cat.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              ] else
                const Expanded(child: Text('Sin categoría', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              if (!_isLoadingCategorias) const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaFinField() {
    return _buildInsetBox(
      child: InkWell(
        onTap: _seleccionarFechaFin,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text(
                _fechaFin == null ? 'Sin definir' : _formatFecha(_fechaFin!),
                style: TextStyle(color: _fechaFin == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14),
              ),
              const Spacer(),
              const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Mismo calendario propio (grid de 7 columnas dentro de un bottom sheet)
  // que usan gastos e ingresos, en vez del showDatePicker nativo de
  // Flutter (que se renderiza en claro y no respeta el tema oscuro).
  Widget _buildCalendarSheet() {
    final base = _fechaFin ?? DateTime.now();
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
                final isSelected = _fechaFin != null &&
                    day == _fechaFin!.day &&
                    month == _fechaFin!.month &&
                    year == _fechaFin!.year;
                return GestureDetector(
                  onTap: () { setState(() => _fechaFin = dayDate); Navigator.pop(context); },
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: isSelected
                        ? const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.error, Color(0xFFFF8A8A)]))
                        : const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                    child: Center(child: Text('$day', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
                  ),
                );
              },
            ),
            if (_fechaFin != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () { setState(() => _fechaFin = null); Navigator.pop(context); },
                  child: const Text('Quitar fecha', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Mismo bottom sheet con tarjetas de categoría (ícono + color + nombre)
  // que usan gastos, ingresos e imprevistos, en vez del DropdownButton
  // nativo que se veía completamente distinto al resto de los módulos.
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
                          itemCount: _categorias.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_categoryScrollController.hasClients) {
                                final hasMore = _categoryScrollController.position.extentAfter > 10;
                                if (hasMore != _showScrollIndicator) {
                                  setSheetState(() => _showScrollIndicator = hasMore);
                                }
                              }
                            });
                            if (index == 0) return _buildSinCategoriaCard();
                            return _buildCategoryCard(_categorias[index - 1]);
                          },
                        ),
                      ),
                    ),
                    if (_showScrollIndicator)
                      Positioned(
                        bottom: 0,
                        child: _ArrowIndicator(),
                      ),
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

  Widget _buildSinCategoriaCard() {
    final isSelected = _categoriaSeleccionada == null;
    return GestureDetector(
      onTap: () { setState(() => _categoriaSeleccionada = null); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: AppColors.error.withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.block, color: AppColors.textSecondary, size: 22)),
            const SizedBox(width: 14),
            const Text('Sin categoría', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoriaModel cat) {
    final isSelected = _categoriaSeleccionada == cat.id;
    final icon = _getIconForCategory(cat.nombre);
    final color = _getColorForCategory(cat.nombre);
    return GestureDetector(
      onTap: () { setState(() => _categoriaSeleccionada = cat.id); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: AppColors.error.withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (cat.descripcion != null) Text(cat.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.error, Color(0xFFFF8A8A)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.deudaParaEditar != null ? 'Guardar cambios' : 'Guardar Deuda', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCancelarButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(26)),
        child: const Center(child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600))),
      ),
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
      default: return Icons.account_balance;
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
      default: return AppColors.error;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: AppColors.error, size: 24),
          ),
        );
      },
    );
  }
}

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  const _NeumorphicContainer({required this.child, this.borderRadius = 16});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-4, -4), blurRadius: 12)]), child: child);
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
