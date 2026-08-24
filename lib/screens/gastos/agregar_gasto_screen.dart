import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../models/gasto_model.dart';
import '../../models/categoria_model.dart';
import '../../models/dependiente_model.dart';
import '../../services/supabase_service.dart';

class AgregarGastoScreen extends StatefulWidget {
  final GastoModel? gastoParaEditar;
  const AgregarGastoScreen({super.key, this.gastoParaEditar});

  @override
  State<AgregarGastoScreen> createState() => _AgregarGastoScreenState();
}

class _AgregarGastoScreenState extends State<AgregarGastoScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _fecha = DateTime.now();
  int? _idCategoria;
  int? _idDependiente;
  
  List<CategoriaModel> _listaCategorias = [];
  List<DependienteModel> _listaDependientes = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final cats = await SupabaseService.fetchCategorias();
    final deps = await SupabaseService.fetchDependientes();
    
    if (mounted) {
      setState(() {
        _listaCategorias = cats;
        _listaDependientes = deps;
        _isLoadingData = false;
        
        if (widget.gastoParaEditar != null) {
          final g = widget.gastoParaEditar!;
          _montoController.text = g.monto % 1 == 0 
              ? g.monto.toStringAsFixed(0) 
              : g.monto.toStringAsFixed(2).replaceAll('.', ',');
          _descriptionController.text = g.description == 'Sin descripción' ? '' : g.description;
          _fecha = g.fecha;
          _idCategoria = g.idCategoria;
          _idDependiente = g.idDependientes;
        } else if (_listaDependientes.isNotEmpty) {
          _idDependiente = _listaDependientes.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descriptionController.dispose();
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

  DependienteModel? get _dependienteSeleccionado {
    if (_idDependiente == null) return null;
    try {
      return _listaDependientes.firstWhere((d) => d.id == _idDependiente);
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
  void _showDependentSheet() => _showNeumorphicSheet(_buildDependentSheet());

  void _crearGasto() async {
    String montoStr = _montoController.text.replaceAll('\$', '');
    if (montoStr.contains(',')) {
      montoStr = montoStr.replaceAll('.', '').replaceAll(',', '.');
    } else {
      montoStr = montoStr.replaceAll('.', '');
    }
    
    final monto = double.tryParse(montoStr) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un monto válido')));
      return;
    }

    setState(() => _isSaving = true);
    final cat = _categoriaSeleccionada;
    final dep = _dependienteSeleccionado;

    final gasto = GastoModel(
      id: widget.gastoParaEditar?.id,
      idSalida: widget.gastoParaEditar?.idSalida,
      idCategoria: cat?.id,
      idDependientes: dep?.id,
      description: _descriptionController.text.isEmpty ? 'Sin descripción' : _descriptionController.text,
      monto: monto,
      fecha: _fecha,
    );

    GastoModel? resultado;
    if (gasto.id == null) {
      resultado = await SupabaseService.insertGasto(gasto);
    } else {
      resultado = await SupabaseService.updateGasto(gasto);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (resultado != null) {
        Navigator.pop(context, resultado);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar en Supabase')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: kBgColor,
        body: Center(child: CircularProgressIndicator(color: kAccentColor)),
      );
    }
    return Scaffold(
      backgroundColor: kBgColor,
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
              _buildCrearButton(),
              const SizedBox(height: 12),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ahorrapp puede cometer errores. Verifica siempre la información antes de guardar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kNegativeColor, fontSize: 10, fontWeight: FontWeight.w600),
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
              widget.gastoParaEditar != null ? 'Editar gasto' : 'Agregar gasto',
              style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              widget.gastoParaEditar != null ? 'Modificar registro' : 'Registro manual',
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
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
          _buildLabel('Descripción'),
          const SizedBox(height: 8),
          _buildTextField(controller: _descriptionController, hint: 'Ej: Almuerzo de trabajo'),
          const SizedBox(height: 18),
          _buildLabel('Fecha de registro', required: true),
          const SizedBox(height: 8),
          _buildFechaField(),
          const SizedBox(height: 18),
          _buildLabel('Categoría'),
          const SizedBox(height: 8),
          _buildCategoriaField(),
          const SizedBox(height: 18),
          _buildLabel('Dependiente'),
          const SizedBox(height: 8),
          _buildDependienteField(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          if (required)
            TextSpan(text: ' *', style: const TextStyle(color: kNegativeColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInsetBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: kInsetBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return _buildInsetBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: kTextPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
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
              const Icon(Icons.calendar_month, color: Color(0xFF4ADE80), size: 20),
              const SizedBox(width: 10),
              Text(_formatFecha(_fecha), style: const TextStyle(color: kTextPrimary, fontSize: 14)),
              const Spacer(),
              const Icon(Icons.expand_more, color: kTextSecondary, size: 20),
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
                Icon(_getIconForCategory(cat.nombre), color: _getColorForCategory(cat.nombre), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(cat.nombre, style: const TextStyle(color: kTextPrimary, fontSize: 14))),
              ] else
                const Expanded(child: Text('Sin seleccionar', style: TextStyle(color: kTextSecondary, fontSize: 14))),
              const Icon(Icons.expand_more, color: kTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDependienteField() {
    final dep = _dependienteSeleccionado;
    return _buildInsetBox(
      child: InkWell(
        onTap: _showDependentSheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(dep?.nombre ?? 'Sin seleccionar', style: const TextStyle(color: kTextPrimary, fontSize: 14))),
              const Icon(Icons.expand_more, color: kTextSecondary, size: 20),
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
      decoration: const BoxDecoration(color: kSecondaryBgColor, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kNavbarInactive, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('${meses[month - 1]} $year', style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            Row(children: ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: kTextSecondary, fontSize: 11))))).toList()),
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
                        ? BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFFFFD700), kAccentColor]))
                        : BoxDecoration(color: kBgColor, shape: BoxShape.circle),
                      child: Center(child: Text('$day', style: TextStyle(color: isSelected ? Colors.black : kTextPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
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
      decoration: const BoxDecoration(color: kSecondaryBgColor, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kNavbarInactive, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Seleccionar categoría', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _listaCategorias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final color = _getColorForCategory(cat.nombre);
    return GestureDetector(
      onTap: () { setState(() => _idCategoria = cat.id); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: kAccentColor.withValues(alpha: 0.6), width: 1.5) : null,
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
                  Text(cat.nombre, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (cat.descripcion != null) Text(cat.descripcion!, style: const TextStyle(color: kTextSecondary, fontSize: 11), maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentSheet() {
    return Container(
      decoration: const BoxDecoration(color: kSecondaryBgColor, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kNavbarInactive, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Seleccionar dependiente', style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              itemCount: _listaDependientes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildDependentCard(_listaDependientes[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentCard(DependienteModel dep) {
    final isSelected = _idDependiente == dep.id;
    return GestureDetector(
      onTap: () { setState(() => _idDependiente = dep.id); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: kAccentColor.withValues(alpha: 0.6), width: 1.5) : null,
          boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Text(dep.nombre, style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCrearButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _crearGasto,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: kAccentColor.withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: Center(
          child: _isSaving 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(widget.gastoParaEditar != null ? 'Guardar cambios' : 'Crear gasto', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
        decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(26)),
        child: const Center(child: Text('Cancelar', style: TextStyle(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600))),
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
      default: return Icons.shopping_cart;
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
      default: return kAccentColor;
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
      decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12)]),
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
        decoration: const BoxDecoration(color: kBgColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)]),
        child: Icon(icon, color: kTextSecondary, size: size),
      ),
    );
  }
}
