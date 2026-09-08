import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PerfilFormSheet(provider: provider, perfil: perfil),
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(
                _esEdicion ? 'Editar perfil' : 'Nuevo perfil',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _Campo(label: 'Nombre', controller: _nombreCtrl),
              const SizedBox(height: 12),
              _Campo(label: 'Descripción (opcional)', controller: _descripcionCtrl, maxLines: 2),
              const SizedBox(height: 12),
              _Campo(
                label: 'Día de corte (1-31)',
                controller: _diaCorteCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PORCENTAJES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Suma: ${_suma.round()}%',
                    style: TextStyle(
                      color: _sumaValida ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _CampoPorcentaje(label: 'Gastos', controller: _gastosCtrl),
              _CampoPorcentaje(label: 'Deudas', controller: _deudasCtrl),
              _CampoPorcentaje(label: 'Imprevistos', controller: _imprevistosCtrl),
              _CampoPorcentaje(label: 'Ahorros', controller: _ahorrosCtrl),
              _CampoPorcentaje(label: 'Emergencia', controller: _emergenciaCtrl),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _esEdicion ? 'Guardar cambios' : 'Crear perfil',
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _CampoPorcentaje extends StatelessWidget {
  const _CampoPorcentaje({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(suffixText: '%'),
            ),
          ),
        ],
      ),
    );
  }
}