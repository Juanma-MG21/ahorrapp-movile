import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/network/api_client.dart';
import '../../models/ahorro_model.dart';
import '../../services/ahorros_service.dart';

class AgregarAhorroScreen extends StatefulWidget {
  final AhorroModel? ahorroParaEditar;
  const AgregarAhorroScreen({super.key, this.ahorroParaEditar});

  @override
  State<AgregarAhorroScreen> createState() => _AgregarAhorroScreenState();
}

class _AgregarAhorroScreenState extends State<AgregarAhorroScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  DateTime? _fechaLimite;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.ahorroParaEditar != null) {
      _nombreController.text = widget.ahorroParaEditar!.nombre;
      _montoController.text = widget.ahorroParaEditar!.montoObjetivo.toStringAsFixed(0);
      _fechaLimite = widget.ahorroParaEditar!.fechaLimite;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
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
    return Row(
      children: [
        _NeumorphicIcon(icon: Icons.arrow_back, size: 20, onTap: () => Navigator.pop(context)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ahorroParaEditar != null ? 'Editar Meta' : 'Nueva Meta',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Registrar objetivo de ahorro', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
          _buildLabel('Nombre de la meta', required: true),
          const SizedBox(height: 8),
          _buildTextField(controller: _nombreController, hint: 'Ej: Viaje a la playa'),
          const SizedBox(height: 18),
          _buildLabel('Monto objetivo', required: true),
          const SizedBox(height: 8),
          _buildTextField(controller: _montoController, hint: '\$0', keyboardType: TextInputType.number),
          const SizedBox(height: 18),
          _buildLabel('Fecha límite (opcional)'),
          const SizedBox(height: 8),
          _buildFechaField(),
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

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFechaField() {
    return Container(
      decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _fechaLimite ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(primary: AppColors.accent, onPrimary: Colors.black, surface: AppColors.surface, onSurface: AppColors.textPrimary),
              ),
              child: child!,
            ),
          );
          if (date != null) setState(() => _fechaLimite = date);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(_fechaLimite == null ? 'Seleccionar fecha' : _formatFecha(_fechaLimite!), style: TextStyle(color: _fechaLimite == null ? AppColors.textSecondary : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuardarButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF8C00)]), borderRadius: BorderRadius.circular(28)),
        child: Center(
          child: _isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text('Guardar Meta', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCancelarButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Center(child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
    );
  }
}

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  const _NeumorphicContainer({required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12)]), child: child);
  }
}

class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _NeumorphicIcon({required this.icon, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8)]), child: Icon(icon, color: AppColors.textSecondary, size: size)));
  }
}
