import 'package:flutter/material.dart';

// import'../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';

/// Abre el formulario de crear/editar perfil como bottom sheet.
/// Si `perfil` es null, es modo "crear"; si no, precarga sus valores
/// y llama a editarPerfil al guardar.
Future<void> mostrarFormularioPerfil(
  BuildContext context, {
  required PresupuestoProvider provider,
  Presupuesto? perfil,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.only(top: 40), // Baja la vista 40 pixeles
      child: _PerfilFormSheet(provider: provider, perfil: perfil),
    ),
  );
}

class _PerfilFormSheet extends StatefulWidget {
  const _PerfilFormSheet({required this.provider, this.perfil});
  final PresupuestoProvider provider;
  final Presupuesto? perfil;

  @override
  State<_PerfilFormSheet> createState() => _PerfilFormSheetState();
}

class _PerfilFormSheetState extends State<_PerfilFormSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _diaCorteCtrl;
  late final TextEditingController _gastosCtrl;
  late final TextEditingController _deudasCtrl;
  late final TextEditingController _imprevistosCtrl;
  late final TextEditingController _ahorrosCtrl;
  late final TextEditingController _emergenciaCtrl;

  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.perfil != null;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _diaCorteCtrl = TextEditingController(text: (p?.diaCorte ?? 1).toString());
    _gastosCtrl = TextEditingController(text: (p?.porcentajeGastos ?? 40).round().toString());
    _deudasCtrl = TextEditingController(text: (p?.porcentajeDeudas ?? 20).round().toString());
    _imprevistosCtrl =
        TextEditingController(text: (p?.porcentajeImprevistos ?? 15).round().toString());
    _ahorrosCtrl = TextEditingController(text: (p?.porcentajeAhorros ?? 10).round().toString());
    _emergenciaCtrl =
        TextEditingController(text: (p?.porcentajeEmergencia ?? 15).round().toString());

    for (final c in [
      _gastosCtrl,
      _deudasCtrl,
      _imprevistosCtrl,
      _ahorrosCtrl,
      _emergenciaCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _diaCorteCtrl.dispose();
    _gastosCtrl.dispose();
    _deudasCtrl.dispose();
    _imprevistosCtrl.dispose();
    _ahorrosCtrl.dispose();
    _emergenciaCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  double get _suma =>
      _num(_gastosCtrl) +
      _num(_deudasCtrl) +
      _num(_imprevistosCtrl) +
      _num(_ahorrosCtrl) +
      _num(_emergenciaCtrl);

  bool get _sumaValida => (_suma - 100).abs() < 0.01;

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final diaCorte = int.tryParse(_diaCorteCtrl.text.trim());

    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }
    if (diaCorte == null || diaCorte < 1 || diaCorte > 31) {
      setState(() => _error = 'El día de corte debe estar entre 1 y 31');
      return;
    }
    if (!_sumaValida) {
      setState(() => _error = 'Los porcentajes deben sumar 100 (actual: ${_suma.round()})');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final bool ok;
    if (_esEdicion) {
      ok = await widget.provider.editarPerfil(
        id: widget.perfil!.idPresupuesto,
        nombre: nombre,
        descripcion: _descripcionCtrl.text.trim(),
        diaCorte: diaCorte,
        porcentajeGastos: _num(_gastosCtrl),
        porcentajeDeudas: _num(_deudasCtrl),
        porcentajeImprevistos: _num(_imprevistosCtrl),
        porcentajeAhorros: _num(_ahorrosCtrl),
        porcentajeEmergencia: _num(_emergenciaCtrl),
      );
    } else {
      ok = await widget.provider.crearPerfil(
        nombre: nombre,
        descripcion: _descripcionCtrl.text.trim(),
        diaCorte: diaCorte,
        porcentajeGastos: _num(_gastosCtrl),
        porcentajeDeudas: _num(_deudasCtrl),
        porcentajeImprevistos: _num(_imprevistosCtrl),
        porcentajeAhorros: _num(_ahorrosCtrl),
        porcentajeEmergencia: _num(_emergenciaCtrl),
      );
    }

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion ? 'Perfil actualizado' : 'Perfil creado'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _guardando = false;
        _error = widget.provider.errorMessage ?? 'Ocurrió un error al guardar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(
                _esEdicion ? 'Editar perfil' : 'Nuevo perfil',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _Campo(
                label: 'NOMBRE DEL PERFIL',
                controller: _nombreCtrl,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _Campo(
                label: 'DESCRIPCIÓN (OPCIONAL)',
                controller: _descripcionCtrl,
                maxLines: 2,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              _Campo(
                label: 'DÍA DE CORTE (1-31)',
                controller: _diaCorteCtrl,
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DISTRIBUCIÓN DE PORCENTAJES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _sumaValida ? AppColors.successSoft : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SUMA: ${_suma.round()}%',
                      style: TextStyle(
                        color: _sumaValida ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SeccionPorcentajes(
                children: [
                  _CampoPorcentaje(label: 'Gastos', controller: _gastosCtrl, color: AppPresupuestoColors.gastos),
                  _CampoPorcentaje(label: 'Deudas', controller: _deudasCtrl, color: AppPresupuestoColors.deudas),
                  _CampoPorcentaje(label: 'Imprevistos', controller: _imprevistosCtrl, color: AppPresupuestoColors.imprevistos),
                  _CampoPorcentaje(label: 'Ahorros', controller: _ahorrosCtrl, color: AppPresupuestoColors.ahorros),
                  _CampoPorcentaje(label: 'Emergencia', controller: _emergenciaCtrl, color: AppPresupuestoColors.emergencia),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60, // Aumentado de 54 a 60
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    elevation: 4, // Añadida elevación para que "se vea más"
                    shadowColor: AppColors.accent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                        )
                      : Text(
                          _esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR PERFIL',
                          style: const TextStyle(
                            fontSize: 16, // Tamaño de letra aumentado
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.accent),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: AppColors.background.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SeccionPorcentajes extends StatelessWidget {
  const _SeccionPorcentajes({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _CampoPorcentaje extends StatelessWidget {
  const _CampoPorcentaje({
    required this.label,
    required this.controller,
    required this.color,
  });
  final String label;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixText: '%',
                suffixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceAlt.withValues(alpha: 0.5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}