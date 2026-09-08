import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/ingreso_model.dart';
import '../../models/categoria_model.dart';
import '../../services/ingresos_service.dart';
import '../../core/network/api_client.dart';

class AgregarIngresoScreen extends StatefulWidget {
  final IngresoModel? ingresoParaEditar;
  final String? textoDetectadoQr;

  const AgregarIngresoScreen({
    super.key,
    this.ingresoParaEditar,
    this.textoDetectadoQr,
  });

  @override
  State<AgregarIngresoScreen> createState() => _AgregarIngresoScreenState();
}

class _AgregarIngresoScreenState extends State<AgregarIngresoScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fuenteController = TextEditingController();

  DateTime _fecha = DateTime.now();
  int? _idCategoria;

  List<CategoriaModel> _listaCategorias = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.textoDetectadoQr != null) {
      _descripcionController.text = widget.textoDetectadoQr!;
    }
  }

  void _loadInitialData() async {
    final cats = await IngresosService.obtenerCategorias();

    if (mounted) {
      setState(() {
        _listaCategorias = cats;
        _isLoadingData = false;

        if (widget.ingresoParaEditar != null) {
          final i = widget.ingresoParaEditar!;
          _montoController.text = i.monto % 1 == 0
              ? i.monto.toStringAsFixed(0)
              : i.monto.toStringAsFixed(2).replaceAll('.', ',');
          _descripcionController.text = i.descripcion ?? '';
          _fuenteController.text = i.fuente ?? '';
          _fecha = i.fechaRegistro;
          _idCategoria = i.idCategoria;

          // Si el ID es nulo pero tenemos nombre (de la IA), intentamos el match
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
    _fuenteController.dispose();
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

  void _guardarIngreso() async {
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

    final ingreso = IngresoModel(
      id: widget.ingresoParaEditar?.id,
      idCategoria: cat?.id,
      descripcion: _descripcionController.text.isEmpty ? null : _descripcionController.text,
      fuente: _fuenteController.text.isEmpty ? null : _fuenteController.text,
      monto: monto,
      fechaRegistro: _fecha,
    );

    IngresoModel? resultado;
    try {
      if (ingreso.id == null) {
        final nuevoId = await IngresosService.crearIngreso(ingreso);
        resultado = IngresoModel(
          id: nuevoId,
          idCategoria: ingreso.idCategoria,
          descripcion: ingreso.descripcion,
          fuente: ingreso.fuente,
          monto: ingreso.monto,
          fechaRegistro: ingreso.fechaRegistro,
        );
      } else {
        await IngresosService.actualizarIngreso(ingreso.id!, ingreso);
        resultado = ingreso;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado'), backgroundColor: Colors.redAccent),
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
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
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
              if (widget.textoDetectadoQr != null) _buildAvisoQr(),
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
              widget.ingresoParaEditar != null ? 'Editar ingreso' : 'Agregar ingreso',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              widget.ingresoParaEditar != null ? 'Modificar registro' : 'Nuevo ingreso',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvisoQr() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.qr_code_2, color: Color(0xFF4ADE80), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Información recuperada del QR. Verifica los campos.',
              style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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
          _buildTextField(controller: _descripcionController, hint: 'Ej: Pago de nómina'),
          const SizedBox(height: 18),
          _buildLabel('Fuente'),
          const SizedBox(height: 8),
          _buildTextField(controller: _fuenteController, hint: 'Ej: Empresa XYZ'),
          const SizedBox(height: 18),
          _buildLabel('Fecha de registro', required: true),
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
              const Icon(Icons.calendar_month, color: Color(0xFF4ADE80), size: 20),
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
                Icon(_getIconForCategory(cat.nombre), color: _getColorForCategory(cat.nombre), size: 20),
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
                          ? const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF4ADE80), Color(0xFF34D399)]))
                          : const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                      child: Center(child: Text('$day', style: TextStyle(color: isSelected ? Colors.black : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.6), width: 1.5) : null,
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
      onTap: _isSaving ? null : _guardarIngreso,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF34D399)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Text(widget.ingresoParaEditar != null ? 'Guardar cambios' : 'Guardar ingreso', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
      case 'Salario': return Icons.payments;
      case 'Venta': return Icons.sell;
      case 'Regalo': return Icons.card_giftcard;
      case 'Inversión': return Icons.trending_up;
      case 'Bonificación': return Icons.redeem;
      case 'Reembolso': return Icons.settings_backup_restore;
      case 'Honorarios': return Icons.work;
      case 'Arriendo': return Icons.apartment;
      case 'Otros': return Icons.more_horiz;
      default: return Icons.account_balance_wallet;
    }
  }

  Color _getColorForCategory(String nombre) {
    switch (nombre) {
      case 'Salario': return const Color(0xFF4ADE80);
      case 'Venta': return const Color(0xFF34D399);
      case 'Regalo': return const Color(0xFFF472B6);
      case 'Inversión': return const Color(0xFF60A5FA);
      case 'Bonificación': return const Color(0xFFFBBF24);
      case 'Reembolso': return const Color(0xFFA8A2FF);
      case 'Honorarios': return const Color(0xFFC084FC);
      case 'Arriendo': return const Color(0xFFFF8C4A);
      case 'Otros': return const Color(0xFF94A3B8);
      default: return const Color(0xFF2DD4BF);
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