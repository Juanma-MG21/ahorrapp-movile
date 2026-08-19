// lib/screens/agregar_ingreso_screen.dart
//
// Formulario "Agregar ingreso", estilo calcado de tus imágenes 3 y 5:
// inputs hundidos (neumorphism), selector de categoría tipo lista,
// selector de fecha con calendario, y botón principal amarillo con glow.
//
// Si viene de la pantalla de QR, el campo "Descripción" se prellena con
// el texto detectado (el usuario lo puede editar libremente).

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/ingreso_model.dart';
import '../services/ingresos_services.dart';

class AgregarIngresoScreen extends StatefulWidget {
  /// Texto crudo leído del QR (null si se entra sin escanear).
  final String? textoDetectadoQr;

  const AgregarIngresoScreen({super.key, this.textoDetectadoQr});

  @override
  State<AgregarIngresoScreen> createState() => _AgregarIngresoScreenState();
}

class _AgregarIngresoScreenState extends State<AgregarIngresoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _fuenteCtrl = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();
  List<CategoriaModel> _categorias = [];
  int? _categoriaSeleccionada;

  bool _cargandoCategorias = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.textoDetectadoQr != null) {
      _descripcionCtrl.text = widget.textoDetectadoQr!;
    }
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final categorias = await IngresosService.obtenerCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      _cargandoCategorias = false;
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    _fuenteCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // Forzamos tema oscuro también en el date picker nativo
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) {
      setState(() => _fechaSeleccionada = seleccion);
    }
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    final montoTexto = _montoCtrl.text.trim().replaceAll(',', '.');
    final monto = double.tryParse(montoTexto);
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido mayor a 0');
      return;
    }

    setState(() => _guardando = true);
    try {
      await IngresosService.crearIngreso(
        IngresoModel(
          monto: monto,
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          fuente: _fuenteCtrl.text.trim().isEmpty ? null : _fuenteCtrl.text.trim(),
          fechaRegistro: _fechaSeleccionada,
          idCategoria: _categoriaSeleccionada,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso guardado correctamente')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.textoDetectadoQr != null) _buildAvisoQr(),
                      _buildLabel('Monto *'),
                      _buildInputMonto(),
                      _buildLabel('Descripción'),
                      _buildInputTexto(
                        controller: _descripcionCtrl,
                        hint: 'Ej: Pago de nómina',
                      ),
                      _buildLabel('Fuente'),
                      _buildInputTexto(
                        controller: _fuenteCtrl,
                        hint: 'Ej: Empresa XYZ',
                      ),
                      _buildLabel('Fecha *'),
                      _buildSelectorFecha(),
                      _buildLabel('Categoría'),
                      _buildSelectorCategoria(),
                      if (_error != null) _buildError(),
                      const SizedBox(height: 28),
                      _buildBotonGuardar(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: clayRaised(radius: AppRadius.pill),
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar ingreso',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Nuevo ingreso',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoQr() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.qr_code_2, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se autocompletó la descripción con el texto del QR. Revisa y ajusta los campos.',
              style: TextStyle(color: AppColors.success, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInputMonto() {
    return Container(
      decoration: claySunken(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _montoCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: r'$0',
          hintStyle: TextStyle(color: AppColors.textMuted),
          prefixText: r'$ ',
          prefixStyle: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildInputTexto({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: claySunken(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildSelectorFecha() {
    final fechaTexto =
        '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/'
        '${_fechaSeleccionada.month.toString().padLeft(2, '0')}/'
        '${_fechaSeleccionada.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: _elegirFecha,
      child: Container(
        decoration: claySunken(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text(fechaTexto, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCategoria() {
    if (_cargandoCategorias) {
      return Container(
        decoration: claySunken(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        ),
      );
    }

    return Container(
      decoration: claySunken(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _categoriaSeleccionada,
          isExpanded: true,
          dropdownColor: AppColors.surfaceAlt,
          iconEnabledColor: AppColors.textSecondary,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          hint: const Text('Sin seleccionar', style: TextStyle(color: AppColors.textMuted)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
            ..._categorias.map(
                  (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
            ),
          ],
          onChanged: (valor) => setState(() => _categoriaSeleccionada = valor),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: _guardando ? null : _guardar,
        child: Container(
          decoration: clayGlow(),
          alignment: Alignment.center,
          child: _guardando
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87),
          )
              : const Text(
            'Guardar ingreso',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}