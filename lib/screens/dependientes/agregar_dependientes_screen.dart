import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/network/api_client.dart';
import '../../models/dependiente_model.dart';
import '../../services/dependiente_services.dart';

class AgregarDependienteScreen extends StatefulWidget {
  final DependienteModel? dependienteParaEditar;

  const AgregarDependienteScreen({
    super.key,
    this.dependienteParaEditar,
  });

  @override
  State<AgregarDependienteScreen> createState() =>
      _AgregarDependienteScreenState();
}

class _AgregarDependienteScreenState
    extends State<AgregarDependienteScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _relacionController = TextEditingController();
  final TextEditingController _ocupacionController = TextEditingController();
  final TextEditingController _pesoEconomicoController =
      TextEditingController();

  DateTime? _fechaNacimiento;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final dependiente = widget.dependienteParaEditar;

    if (dependiente != null) {
      _nombreController.text = dependiente.nombre;
      _relacionController.text = dependiente.relacion ?? '';
      _ocupacionController.text = dependiente.ocupacion ?? '';

      _fechaNacimiento = dependiente.fechaNacimiento;

      _pesoEconomicoController.text =
          dependiente.pesoEconomico?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _relacionController.dispose();
    _ocupacionController.dispose();
    _pesoEconomicoController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // FECHA
  // ─────────────────────────────────────────────

  String _formatFecha(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');

    return '$dd/$mm/${fecha.year}';
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
    );

    if (fecha != null) {
      setState(() {
        _fechaNacimiento = fecha;
      });
    }
  }

  // ─────────────────────────────────────────────
  // SHEET NEUMÓRFICO
  // ─────────────────────────────────────────────

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
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * t),
                  ),
                ),

                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 8 * t,
                      sigmaY: 8 * t,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),

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

  // ─────────────────────────────────────────────
  // GUARDAR
  // ─────────────────────────────────────────────

  Future<void> _guardarDependiente() async {
    final nombre = _nombreController.text.trim();
    final relacion = _relacionController.text.trim();
    final ocupacion = _ocupacionController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre del dependiente'),
        ),
      );
      return;
    }

    final pesoEconomico =
        int.tryParse(_pesoEconomicoController.text.trim());

    if (_pesoEconomicoController.text.trim().isNotEmpty &&
        pesoEconomico == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El peso económico debe ser un número entero'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dependiente = DependienteModel(
      id: widget.dependienteParaEditar?.id,
      nombre: nombre,
      relacion: relacion.isEmpty ? null : relacion,
      ocupacion: ocupacion.isEmpty ? null : ocupacion,
      fechaNacimiento: _fechaNacimiento,
      pesoEconomico: pesoEconomico,
    );

    try {
      DependienteModel? resultado;

      if (dependiente.id == null) {
        final nuevoId =
            await DependientesService.crearDependiente(dependiente);

        resultado = DependienteModel(
          id: nuevoId,
          nombre: dependiente.nombre,
          relacion: dependiente.relacion,
          ocupacion: dependiente.ocupacion,
          fechaNacimiento: dependiente.fechaNacimiento,
          pesoEconomico: dependiente.pesoEconomico,
        );
      } else {
        await DependientesService.actualizarDependiente(
          dependiente.id!,
          dependiente,
        );

        resultado = dependiente;
      }

      if (!mounted) return;

      setState(() => _isSaving = false);

      Navigator.pop(context, resultado);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

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

              const SizedBox(height: 12),

              _buildCancelarButton(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

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
              widget.dependienteParaEditar != null
                  ? 'Editar dependiente'
                  : 'Agregar dependiente',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              widget.dependienteParaEditar != null
                  ? 'Modificar información'
                  : 'Registrar nuevo dependiente',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FORMULARIO
  // ─────────────────────────────────────────────

  Widget _buildFormCard() {
    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(
            'Nombre completo',
            required: true,
          ),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _nombreController,
            hint: 'Ej: Juan Pérez',
          ),

          const SizedBox(height: 18),

          _buildLabel('Relación'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _relacionController,
            hint: 'Ej: Hijo, madre, padre...',
          ),

          const SizedBox(height: 18),

          _buildLabel('Ocupación'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _ocupacionController,
            hint: 'Ej: Estudiante, empleado...',
          ),

          const SizedBox(height: 18),

          _buildLabel('Fecha de nacimiento'),

          const SizedBox(height: 8),

          _buildFechaField(),

          const SizedBox(height: 18),

          _buildLabel('Peso económico'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _pesoEconomicoController,
            hint: 'Ej: 50',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TEXT FIELD
  // ─────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _buildInsetBox(
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInsetBox({
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.35),
        ),
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────────
  // FECHA
  // ─────────────────────────────────────────────

  Widget _buildFechaField() {
    final texto = _fechaNacimiento != null
        ? _formatFecha(_fechaNacimiento!)
        : 'Seleccionar fecha';

    return _buildInsetBox(
      child: InkWell(
        onTap: _seleccionarFechaNacimiento,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF60A5FA),
                size: 20,
              ),

              const SizedBox(width: 10),

              Text(
                texto,
                style: TextStyle(
                  color: _fechaNacimiento != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.expand_more,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTÓN GUARDAR
  // ─────────────────────────────────────────────

  Widget _buildGuardarButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _guardarDependiente,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF818CF8),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF60A5FA).withOpacity(0.35),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.dependienteParaEditar != null
                      ? 'Guardar cambios'
                      : 'Guardar dependiente',
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

  // ─────────────────────────────────────────────
  // CANCELAR
  // ─────────────────────────────────────────────

  Widget _buildCancelarButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// CONTENEDOR NEUMÓRFICO
// ═══════════════════════════════════════════════

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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
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

// ═══════════════════════════════════════════════
// ICONO NEUMÓRFICO
// ═══════════════════════════════════════════════

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
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF05060D),
              offset: Offset(3, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: size,
        ),
      ),
    );
  }
}
