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
    super.dispose();
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => _fechaFin = fecha);
    }
  }

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
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
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
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
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
        children: [
          _buildTextField(
            label: 'Acreedor / Fuente',
            controller: _fuenteController,
            hint: 'Ej: Banco, Juan Pérez',
            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Monto Total',
            controller: _montoController,
            hint: '\$0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Descripción (Opcional)',
            controller: _descripcionController,
            hint: 'Ej: Préstamo para el carro',
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          _buildCategoriaDropdown(),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Número de Cuotas (Opcional)',
            controller: _cuotasController,
            hint: 'Ej: 12',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          _buildFechaFinPicker(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(14)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categoría (Opcional)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isLoadingCategorias
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _categoriaSeleccionada,
                    isExpanded: true,
                    dropdownColor: AppColors.background,
                    style: const TextStyle(color: AppColors.textPrimary),
                    hint: const Text('Sin categoría', style: TextStyle(color: AppColors.textSecondary)),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin categoría'),
                      ),
                      ..._categorias.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.nombre),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoriaSeleccionada = value),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFechaFinPicker() {
    final texto = _fechaFin != null
        ? '${_fechaFin!.day.toString().padLeft(2, '0')}/${_fechaFin!.month.toString().padLeft(2, '0')}/${_fechaFin!.year}'
        : 'Sin definir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fecha Estimada de Fin (Opcional)', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _seleccionarFechaFin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  texto,
                  style: TextStyle(
                    color: _fechaFin != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuardarButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.error, Color(0xFFFF8A8A)]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Guardar Deuda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
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