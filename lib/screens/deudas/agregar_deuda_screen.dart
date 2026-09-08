import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/deuda_model.dart';
import '../../services/deudas_service.dart';
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
  final _tasaController = TextEditingController();
  final _cuotasController = TextEditingController();
  DateTime? _fechaFin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.deudaParaEditar != null) {
      final d = widget.deudaParaEditar!;
      _fuenteController.text = d.fuente;
      _montoController.text = d.monto.toStringAsFixed(0);
      _tasaController.text = d.tasaInteres.toString();
      _cuotasController.text = d.cuotasTotal?.toString() ?? '';
      _fechaFin = d.fechaFin;
    }
  }

  @override
  void dispose() {
    _fuenteController.dispose();
    _montoController.dispose();
    _tasaController.dispose();
    _cuotasController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final deuda = DeudaModel(
      id: widget.deudaParaEditar?.id,
      fuente: _fuenteController.text.trim(),
      monto: double.parse(_montoController.text),
      tasaInteres: double.tryParse(_tasaController.text) ?? 0.0,
      cuotasTotal: int.tryParse(_cuotasController.text),
      cuotasPagadas: widget.deudaParaEditar?.cuotasPagadas ?? 0,
      fechaFin: _fechaFin,
      fechaInicio: widget.deudaParaEditar?.fechaInicio ?? DateTime.now(),
      estado: widget.deudaParaEditar?.estado ?? 'pendiente',
    );

    try {
      if (deuda.id == null) {
        await DeudasService.crearDeuda(deuda);
      } else {
        await DeudasService.actualizarDeuda(deuda.id!, deuda);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
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
            keyboardType: TextInputType.number,
            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Monto inválido' : null,
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Tasa de Interés (%)',
            controller: _tasaController,
            hint: '0.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val != null && val < 0) return 'La tasa no puede ser negativa'; // RF-06
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildTextField(
            label: 'Número de Cuotas (Opcional)',
            controller: _cuotasController,
            hint: 'Ej: 12',
            keyboardType: TextInputType.number,
          ),
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
