import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/imprevisto_model.dart';
import '../../models/categoria_model.dart';
import '../../services/imprevistos_service.dart';
import '../../core/network/api_client.dart';

class AgregarImprevistoScreen extends StatefulWidget {
  final ImprevistoModel? imprevistoParaEditar;

  const AgregarImprevistoScreen({
    super.key,
    this.imprevistoParaEditar,
  });

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
          _montoController.text = i.monto % 1 == 0
              ? i.monto.toStringAsFixed(0)
              : i.monto.toStringAsFixed(2).replaceAll('.', ',');
          _descripcionController.text = i.descripcion ?? '';
          _fecha = i.fecha;
          _idCategoria = i.idCategoria;

          if (_idCategoria == null && i.categoriaNombre != null) {
            final sugerida = _listaCategorias.where(
              (c) => c.nombre.toLowerCase() == i.categoriaNombre!.toLowerCase(),
            );
            if (sugerida.isNotEmpty) {
              _idCategoria = sugerida.first.id;
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  CategoriaModel? get _categoriaSeleccionada {
    if (_idCategoria == null) return null;
    try {
      return _listaCategorias.firstWhere((c) => c.id == _idCategoria);
    } catch (_) {
      return null;
    }
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(color: Colors.black.withOpacity(0.4 * t)),
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

  void _guardar() async {
    String montoStr = _montoController.text.replaceAll('\$', '');
    if (montoStr.contains(',')) {
      montoStr = montoStr.replaceAll('.', '').replaceAll(',', '.');
    } else {
      montoStr = montoStr.replaceAll('.', '');
    }

    final monto = double.tryParse(montoStr) ?? 0.0;
    
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un monto positivo')));
      return;
    }

    if (_descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La descripción es obligatoria')));
      return;
    }

    setState(() => _isSaving = true);
    final cat = _categoriaSeleccionada;

    final imprevisto = ImprevistoModel(
      id: widget.imprevistoParaEditar?.id,
      idCategoria: cat?.id,
      descripcion: _descripcionController.text.trim(),
      monto: monto,
      fecha: _fecha,
    );

    ImprevistoModel? resultado;
    try {
      if (imprevisto.id == null) {
        final nuevoId = await ImprevistosService.crearImprevisto(imprevisto);
        resultado = ImprevistoModel(
          id: nuevoId,
          idCategoria: imprevisto.idCategoria,
          descripcion: imprevisto.descripcion,
          monto: imprevisto.monto,
          fecha: imprevisto.fecha,
        );
      } else {
        await ImprevistosService.actualizarImprevisto(imprevisto.id!, imprevisto);
        resultado = imprevisto;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado'), backgroundColor: AppColors.error),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (resultado != null) {
        Navigator.pop(context, resultado);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.error)),
      );
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ahorrapp puede cometer errores. Verifica siempre la información antes de guardar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
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
    return Row(
      children: [
        _NeumorphicIcon(icon: Icons.arrow_back, size: 20, onTap: () => Navigator.pop(context)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.imprevistoParaEditar != null ? 'Editar imprevisto' : 'Registrar imprevisto',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              widget.imprevistoParaEditar != null ? 'Modificar registro' : 'Nuevo imprevisto',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Monto', required: true),
          const SizedBox(height: 8),
          _buildTextField(controller: _montoController, hint: '\$0', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 18),
          _buildLabel('Descripción', required: true),
          const SizedBox(height: 8),
          _buildTextField(controller: _descripcionController, hint: 'Ej: Reparación de tubería'),
          const SizedBox(height: 18),
          _buildLabel('Fecha del evento', required: true),
          const SizedBox(height: 8),
          _buildFechaField(),
          const SizedBox(height: 18),
          _buildLabel('Categoría'),
          const SizedBox(height: 8),
          _buildCategoriaField(),
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
            const TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInsetBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.35)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return _buildInsetBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFechaField() {
    return _buildInsetBox(
      child: InkWell(
        onTap: _showCalendarSheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text(_formatFecha(_fecha), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              const Spacer(),
              const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaField() {
    final cat = _categoriaSeleccionada;
    return _buildInsetBox(
      child: InkWell(
        onTap: _showCategorySheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (cat != null) ...[
                Icon(_getIconForCategory(cat.nombre), color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(cat.nombre, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
              ] else
                const Expanded(child: Text('Sin seleccionar', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
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
                      decoration: isSelected
                          ? const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFF8A8A), AppColors.error]))
                          : const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
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
            const Text('Seleccionar categoría', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _listaCategorias.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildCategoryCard(_listaCategorias[index]),
              ),
            ),
          ],
        ),
      ),
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
          border: isSelected ? Border.all(color: AppColors.error.withOpacity(0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.error, size: 22)),
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
          gradient: const LinearGradient(colors: [Color(0xFFFF8A8A), AppColors.error]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 20)],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.imprevistoParaEditar != null ? 'Guardar cambios' : 'Registrar imprevisto', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  const _NeumorphicContainer({required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12)]),
      child: child,
    );
  }
}

class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _NeumorphicIcon({required this.icon, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)]),
        child: Icon(icon, color: AppColors.textSecondary, size: size),
      ),
    );
  }
}