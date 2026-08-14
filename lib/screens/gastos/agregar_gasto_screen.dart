import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/gasto_model.dart';

class AgregarGastoScreen extends StatefulWidget {
  final GastoModel? gastoParaEditar;
  const AgregarGastoScreen({super.key, this.gastoParaEditar});

  @override
  State<AgregarGastoScreen> createState() => _AgregarGastoScreenState();
}

class _AgregarGastoScreenState extends State<AgregarGastoScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  DateTime _fecha = DateTime.now();
  String? _categoria;
  String _dependiente = 'Gasto propio';

  @override
  void initState() {
    super.initState();
    if (widget.gastoParaEditar != null) {
      final g = widget.gastoParaEditar!;
      _montoController.text = g.monto.toStringAsFixed(0);
      _descripcionController.text = g.descripcion == 'Sin descripción' ? '' : g.descripcion;
      _fecha = g.fecha;
      _categoria = g.categoriaNombre;
      _dependiente = g.responsableNombre;
    }
  }

  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  final List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Alimentación',
      'descripcion': 'Comidas, restaurantes y productos alimenticios',
      'icono': Icons.restaurant,
      'color': const Color(0xFFA8A2FF),
    },
    {
      'nombre': 'Ropa',
      'descripcion': 'Prendas de vestir y accesorios',
      'icono': Icons.checkroom,
      'color': const Color(0xFF4ADE80),
    },
    {
      'nombre': 'Hogar',
      'descripcion': 'Gastos relacionados con vivienda y mantenimiento',
      'icono': Icons.home,
      'color': const Color(0xFFFF8C4A),
    },
    {
      'nombre': 'Transporte',
      'descripcion': 'Movilidad, transporte público y combustible',
      'icono': Icons.directions_bus,
      'color': const Color(0xFF60A5FA),
    },
    {
      'nombre': 'Salud',
      'descripcion': 'Medicamentos, consultas y salud en general',
      'icono': Icons.medical_services,
      'color': const Color(0xFFFF6B6B),
    },
    {
      'nombre': 'Entretenimiento',
      'descripcion': 'Ocio, streaming y actividades recreativas',
      'icono': Icons.movie,
      'color': const Color(0xFFC084FC),
    },
  ];

  final List<Map<String, dynamic>> _dependientes = [
    {
      'nombre': 'Gasto propio',
      'descripcion': 'Gastos personales',
      'icono': Icons.person,
      'color': const Color(0xFF60A5FA),
    },
    {
      'nombre': 'Sofía • Hija',
      'descripcion': 'Hija',
      'icono': Icons.child_care,
      'color': const Color(0xFF60A5FA),
    },
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _categoriaSeleccionada {
    for (final c in _categorias) {
      if (c['nombre'] == _categoria) return c;
    }
    return null;
  }

  Map<String, dynamic> get _dependienteSeleccionado {
    for (final d in _dependientes) {
      if (d['nombre'] == _dependiente) return d;
    }
    return _dependientes.first;
  }

  String _formatFecha(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/${mm}/${date.year}';
  }

  // ---------- HOJA MODAL CON FONDO DIFUMINADO ----------
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
                // Oscurece y cierra al tocar fuera
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * t),
                  ),
                ),
                // Difumina el fondo
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8 * t, sigmaY: 8 * t),
                    child: const SizedBox.expand(),
                  ),
                ),
                // La hoja sube desde abajo
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - t),
                    child: Material(
                      type: MaterialType.transparency,
                      child: sheet,
                    ),
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

  void _crearGasto() {
    final montoStr = _montoController.text.replaceAll('\$', '').replaceAll(',', '').replaceAll('.', '');
    final monto = double.tryParse(montoStr) ?? 0.0;

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un monto válido')),
      );
      return;
    }

    final cat = _categoriaSeleccionada;
    final dep = _dependienteSeleccionado;

    final nuevoGasto = GastoModel(
      titulo: cat != null ? cat['nombre'] as String : 'General',
      subtitulo: '${dep['nombre']} • ${_formatFecha(_fecha)}',
      descripcion: _descripcionController.text.isEmpty ? 'Sin descripción' : _descripcionController.text,
      monto: monto,
      icono: cat != null ? cat['icono'] as IconData : Icons.shopping_cart,
      color: cat != null ? cat['color'] as Color : kAccentColor,
      fecha: _fecha,
      categoriaNombre: cat != null ? cat['nombre'] as String : 'General',
      responsableNombre: dep['nombre'] as String,
    );

    Navigator.pop(context, nuevoGasto);
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
              _buildCancelarButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    return Row(
      children: [
        _NeumorphicIcon(
          icon: Icons.arrow_back,
          size: 20,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.gastoParaEditar != null ? 'Editar gasto' : 'Agregar gasto',
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

  // ---------- FORMULARIO ----------
  Widget _buildFormCard() {
    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Monto', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _montoController,
            hint: '\$0',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 18),
          _buildLabel('Descripción'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descripcionController,
            hint: 'Ej: Almuerzo de trabajo',
          ),
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
          TextSpan(
            text: text,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: kNegativeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _buildInsetBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: kTextPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------- CAMPO FECHA (abre el calendario personalizado) ----------
  Widget _buildFechaField() {
    return _buildInsetBox(
      child: InkWell(
        onTap: _showCalendarSheet,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF4ADE80),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _formatFecha(_fecha),
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
              ),
              const Spacer(),
              Icon(Icons.expand_more, color: kTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- CAMPO CATEGORÍA (abre la hoja de categorías) ----------
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
                Icon(
                  cat['icono'] as IconData,
                  color: cat['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat['nombre'] as String,
                    style: const TextStyle(color: kTextPrimary, fontSize: 14),
                  ),
                ),
              ] else
                const Expanded(
                  child: Text(
                    'Sin seleccionar',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                ),
              Icon(Icons.expand_more, color: kTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- CAMPO DEPENDIENTE (abre la hoja de dependientes) ----------
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
              Icon(
                dep['icono'] as IconData,
                color: dep['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dep['nombre'] as String,
                  style: const TextStyle(color: kTextPrimary, fontSize: 14),
                ),
              ),
              Icon(Icons.expand_more, color: kTextSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HOJA: CALENDARIO ----------
  Widget _buildCalendarSheet() {
    final year = _fecha.year;
    final month = _fecha.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = DateTime(year, month, 1).weekday - 1; // Lunes = 0

    return Container(
      decoration: const BoxDecoration(
        color: kSecondaryBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNavbarInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_meses[month - 1]} $year',
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Solo días del mes actual',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              children: ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do']
                  .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = index - offset + 1;
                return _buildDayButton(day);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayButton(int day) {
    final isSelected = day == _fecha.day;
    return GestureDetector(
      onTap: () {
        setState(() {
          _fecha = DateTime(_fecha.year, _fecha.month, day);
        });
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: isSelected
            ? BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFD700), kAccentColor],
          ),
          boxShadow: [
            BoxShadow(
              color: kAccentColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        )
            : BoxDecoration(
          color: kBgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05060D),
              offset: Offset(2, 2),
              blurRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFF1A1D3A),
              offset: Offset(-2, -2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: isSelected ? Colors.black : kTextPrimary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- HOJA: SELECCIONAR CATEGORÍA ----------
  Widget _buildCategorySheet() {
    return Container(
      decoration: const BoxDecoration(
        color: kSecondaryBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNavbarInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seleccionar categoría',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildCategoryCard(_categorias[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final isSelected = _categoria == cat['nombre'];
    return GestureDetector(
      onTap: () {
        setState(() => _categoria = cat['nombre'] as String);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(
              color: kAccentColor.withValues(alpha: 0.6), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05060D),
              offset: Offset(3, 3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: const Color(0xFF1A1D3A),
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                cat['icono'] as IconData,
                color: cat['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['nombre'] as String,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cat['descripcion'] as String,
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- HOJA: SELECCIONAR DEPENDIENTE ----------
  Widget _buildDependentSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: kSecondaryBgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNavbarInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seleccionar dependiente',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _dependientes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildDependentCard(_dependientes[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentCard(Map<String, dynamic> dep) {
    final isSelected = _dependiente == dep['nombre'];
    return GestureDetector(
      onTap: () {
        setState(() => _dependiente = dep['nombre'] as String);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(
              color: kAccentColor.withValues(alpha: 0.6), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05060D),
              offset: Offset(3, 3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: const Color(0xFF1A1D3A),
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (dep['color'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                dep['icono'] as IconData,
                color: dep['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dep['nombre'] as String,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dep['descripcion'] as String,
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- BOTONES ----------
  Widget _buildCrearButton() {
    return GestureDetector(
      onTap: _crearGasto,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kAccentColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.gastoParaEditar != null ? 'Guardar cambios' : 'Crear gasto',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        decoration: BoxDecoration(
          color: kBgColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF05060D),
              offset: Offset(4, 4),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Color(0xFF1A1D3A),
              offset: Offset(-4, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- WIDGETS NEUMÓRFICOS ----------

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const _NeumorphicContainer({
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF05060D),
            offset: Offset(4, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Color(0xFF1A1D3A),
            offset: Offset(-4, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _NeumorphicIcon({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kBgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF05060D),
              offset: Offset(3, 3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0xFF1A1D3A),
              offset: Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: kTextSecondary,
          size: size,
        ),
      ),
    );
  }
}