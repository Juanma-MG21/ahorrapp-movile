import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../models/emergencia_model.dart';
import '../../services/emergencia_service.dart';

class ModuloEmergencia extends StatefulWidget {
  const ModuloEmergencia({super.key});

  @override
  State<ModuloEmergencia> createState() => _ModuloEmergenciaState();
}

class _ModuloEmergenciaState extends State<ModuloEmergencia> {
  FondoEmergenciaModel? _fondo;
  List<MovimientoEmergenciaModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final fondo = await EmergenciaService.obtenerFondo();
      final movimientos = fondo != null
          ? await EmergenciaService.obtenerMovimientos()
          : <MovimientoEmergenciaModel>[];
      if (!mounted) return;
      setState(() {
        _fondo = fondo;
        _movimientos = movimientos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el fondo de emergencia: $e')),
      );
    }
  }

  String _formatCurrency(double amount) {
    final parte = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\$$parte';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _cargar,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      if (_fondo == null) _buildSinFondo() else ...[
                        _buildResumen(_fondo!),
                        const SizedBox(height: 20),
                        _buildAcciones(),
                        const SizedBox(height: 30),
                        const Text('Historial',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildHistorial(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fondo de Emergencia',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Un colchón para los imprevistos grandes',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildSinFondo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: clayRaised(),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, color: AppPresupuestoColors.emergencia, size: 48),
          const SizedBox(height: 14),
          const Text(
            'Todavía no tienes un fondo de emergencia configurado',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Define una meta a la que quieras llegar de forma acumulativa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => _mostrarDialogoMeta(esNuevo: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: const Text('Crear fondo de emergencia', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(FondoEmergenciaModel fondo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayRaised(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SALDO ACUMULADO',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              InkWell(
                onTap: () => _mostrarDialogoMeta(esNuevo: false),
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 14),
                    SizedBox(width: 4),
                    Text('Editar meta', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_formatCurrency(fondo.saldoActual),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _buildProgressBar(fondo.progreso),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(fondo.progreso * 100).toStringAsFixed(1)}% de la meta',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('Meta: ${_formatCurrency(fondo.meta)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double porcentaje) {
    return Container(
      height: 10,
      decoration: BoxDecoration(color: AppColors.inset, borderRadius: BorderRadius.circular(10)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: porcentaje.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppPresupuestoColors.emergencia,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarDialogoMovimiento(esAporte: true),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Aportar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarDialogoMovimiento(esAporte: false),
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Retirar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorial() {
    if (_movimientos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Todavía no hay movimientos registrados', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: _movimientos.map((m) {
        final esAporte = m.esAporte;
        final color = esAporte ? AppColors.success : AppColors.error;
        final fecha = m.fechaRegistro != null ? DateFormat('dd/MM/yyyy').format(m.fechaRegistro!) : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: clayRaised(radius: AppRadius.sm),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(esAporte ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(esAporte ? 'Aporte' : 'Retiro',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (m.descripcion != null && m.descripcion!.isNotEmpty)
                      Text(m.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    if (fecha.isNotEmpty)
                      Text(fecha, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${esAporte ? '+' : '-'}${_formatCurrency(m.monto)}',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _mostrarDialogoMeta({required bool esNuevo}) async {
    final controller = TextEditingController(
      text: esNuevo ? '' : _fondo?.meta.toStringAsFixed(0) ?? '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          esNuevo ? 'Meta del fondo' : 'Editar meta',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Monto objetivo',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final meta = double.tryParse(controller.text);
              if (meta == null || meta < 0) return;
              try {
                if (esNuevo) {
                  await EmergenciaService.crearFondo(meta);
                } else {
                  await EmergenciaService.actualizarMeta(meta);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.background),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoMovimiento({required bool esAporte}) async {
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          esAporte ? 'Registrar aporte' : 'Registrar retiro',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Monto',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Descripción (opcional)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text);
              if (monto == null || monto <= 0) return;
              final descripcion = descripcionController.text.trim();
              try {
                if (esAporte) {
                  await EmergenciaService.registrarAporte(
                    monto,
                    descripcion: descripcion.isEmpty ? null : descripcion,
                  );
                } else {
                  await EmergenciaService.registrarRetiro(
                    monto,
                    descripcion: descripcion.isEmpty ? null : descripcion,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _cargar();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: esAporte ? AppColors.success : AppColors.error,
              foregroundColor: AppColors.background,
            ),
            child: Text(esAporte ? 'Aportar' : 'Retirar'),
          ),
        ],
      ),
    );
  }
}
