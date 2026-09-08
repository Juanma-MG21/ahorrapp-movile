import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/presupuestos_parsing.dart';
import '../../models/periodo_presupuesto_model.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';
import 'perfil_presupuesto_form_sheet.dart';

/// Colores por categoría. AppColors/AppCategoryColors no traen un color
/// dedicado para "deudas" ni "emergencia", así que se reutilizan los
/// tonos semánticos/de categoría ya existentes en el design system en
/// vez de inventar nuevos.
class _CategoriaVisual {
  const _CategoriaVisual(this.label, this.color);
  final String label;
  final Color color;
}

const Map<String, _CategoriaVisual> _categorias = {
  'gastos': _CategoriaVisual('Gastos', AppColors.blue),
  'deudas': _CategoriaVisual('Deudas', AppCategoryColors.almuerzo),
  'imprevistos': _CategoriaVisual('Imprevistos', AppColors.accent),
  'ahorros': _CategoriaVisual('Ahorros', AppColors.success),
  'emergencia': _CategoriaVisual('Emergencia', AppColors.error),
};

class ModuloPresupuestos extends StatefulWidget {
  const ModuloPresupuestos({super.key});

  @override
  State<ModuloPresupuestos> createState() => _ModuloPresupuestosState();
}

class _ModuloPresupuestosState extends State<ModuloPresupuestos> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Presupuestos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<PresupuestoProvider>(
        builder: (context, provider, _) {
          if (provider.status == PresupuestoLoadStatus.loading &&
              provider.perfiles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (provider.status == PresupuestoLoadStatus.error &&
              provider.perfiles.isEmpty) {
            return _ErrorState(
              message: provider.errorMessage ?? 'Ocurrió un error',
              onRetry: provider.cargar,
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: provider.refrescar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (provider.errorMessage != null) ...[
                  _InlineErrorBanner(message: provider.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (provider.periodoActivo == null)
                  _SinPeriodoActivoCard(provider: provider)
                else
                  _PeriodoActivoCard(
                    periodo: provider.periodoActivo!,
                    provider: provider,
                  ),
                const SizedBox(height: 24),
                _PerfilesHeader(provider: provider),
                const SizedBox(height: 12),
                ...provider.perfiles.map(
                  (perfil) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PerfilCard(perfil: perfil, provider: provider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Estados vacíos / error ───────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}

class _SinPeriodoActivoCard extends StatelessWidget {
  const _SinPeriodoActivoCard({required this.provider});
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayRaised(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No tienes un período activo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.perfilActivo == null
                ? 'Activa un perfil de presupuesto y luego abre un nuevo período.'
                : 'Abre un nuevo período para "${provider.perfilActivo!.nombre}" indicando el ingreso estimado.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.perfilActivo == null || provider.accionEnCurso
                  ? null
                  : () => _mostrarDialogoAbrirPeriodo(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: const Text(
                'Abrir período',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Header de período activo ───────────────────────────

class _PeriodoActivoCard extends StatelessWidget {
  const _PeriodoActivoCard({required this.periodo, required this.provider});
  final PeriodoPresupuesto periodo;
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    final rango = periodo.fechaInicio != null && periodo.fechaFin != null
        ? '${formatFechaCorta(periodo.fechaInicio!)} - ${formatFechaCorta(periodo.fechaFin!)}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayRaised(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: periodo.abierto
                                ? AppColors.success
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PERÍODO ACTIVO',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rango,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(abierto: periodo.abierto),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: claySunken(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingreso estimado',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMonto(periodo.ingresoEstimado),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ToggleResumenButton(
            expandido: provider.resumenExpandido,
            onTap: provider.toggleResumen,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _ResumenExpandido(periodo: periodo, provider: provider),
            ),
            crossFadeState: provider.resumenExpandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.abierto});
  final bool abierto;

  @override
  Widget build(BuildContext context) {
    final color = abierto ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        abierto ? 'Abierto' : 'Cerrado',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ToggleResumenButton extends StatelessWidget {
  const _ToggleResumenButton({required this.expandido, required this.onTap});
  final bool expandido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expandido ? 'Ocultar resumen' : 'Ver resumen',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.accent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenExpandido extends StatelessWidget {
  const _ResumenExpandido({required this.periodo, required this.provider});
  final PeriodoPresupuesto periodo;
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INGRESOS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _IngresoColumna(
              label: 'Estimado',
              valor: formatMonto(periodo.ingresoEstimado),
              color: AppColors.accent,
            ),
            _IngresoColumna(
              label: 'Real',
              valor: formatMonto(periodo.ingresoReal),
              color: AppColors.textPrimary,
            ),
            _IngresoColumna(
              label: 'Saldo ant.',
              valor: formatMonto(periodo.saldoAnterior),
              color: AppColors.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'DISTRIBUCIÓN',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        _CategoriaBar(
          categoriaKey: 'gastos',
          porcentaje: periodo.porcentajeDe(periodo.montoGastos),
          monto: periodo.montoGastos,
        ),
        _CategoriaBar(
          categoriaKey: 'deudas',
          porcentaje: periodo.porcentajeDe(periodo.montoDeudas),
          monto: periodo.montoDeudas,
        ),
        _CategoriaBar(
          categoriaKey: 'imprevistos',
          porcentaje: periodo.porcentajeDe(periodo.montoImprevistos),
          monto: periodo.montoImprevistos,
        ),
        _CategoriaBar(
          categoriaKey: 'ahorros',
          porcentaje: periodo.porcentajeDe(periodo.montoAhorros),
          monto: periodo.montoAhorros,
        ),
        _CategoriaBar(
          categoriaKey: 'emergencia',
          porcentaje: periodo.porcentajeDe(periodo.montoEmergencia),
          monto: periodo.montoEmergencia,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.accionEnCurso
                    ? null
                    : () => _mostrarDialogoAjustarIngreso(context, provider, periodo),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: const Text('Ajustar ingreso'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: !periodo.abierto || provider.accionEnCurso
                    ? null
                    : () => _mostrarDialogoCerrarPeriodo(context, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: const Text('Cerrar período'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IngresoColumna extends StatelessWidget {
  const _IngresoColumna({
    required this.label,
    required this.valor,
    required this.color,
  });
  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso horizontal para una categoría. `monto` es opcional:
/// en el resumen del período se muestra "40% - $800.000"; en el detalle
/// de un perfil (que no está atado a montos de un período) solo se
/// muestra el porcentaje.
class _CategoriaBar extends StatelessWidget {
  const _CategoriaBar({
    required this.categoriaKey,
    required this.porcentaje,
    this.monto,
  });

  final String categoriaKey;
  final double porcentaje;
  final double? monto;

  @override
  Widget build(BuildContext context) {
    final visual = _categorias[categoriaKey]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visual.label,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              Text(
                monto != null
                    ? '${porcentaje.round()}% · ${formatMonto(monto!)}'
                    : '${porcentaje.round()}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (porcentaje / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.inset,
              valueColor: AlwaysStoppedAnimation(visual.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Perfiles de presupuesto ───────────────────────────

class _PerfilesHeader extends StatelessWidget {
  const _PerfilesHeader({required this.provider});
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Perfiles de presupuesto',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => mostrarFormularioPerfil(context, provider: provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: AppColors.success, size: 16),
                SizedBox(width: 4),
                Text(
                  'Nuevo perfil',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfilCard extends StatelessWidget {
  const _PerfilCard({required this.perfil, required this.provider});
  final Presupuesto perfil;
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    final expandido = provider.perfilExpandidoId == perfil.idPresupuesto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayRaised(
        border: perfil.activo
            ? Border.all(color: AppColors.success.withValues(alpha: 0.5))
            : null,
      ),
      child: InkWell(
        onTap: () => provider.togglePerfilExpandido(perfil.idPresupuesto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          perfil.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (perfil.activo) const _MiniBadge(texto: 'ACTIVO', color: AppColors.success),
                    ],
                  ),
                ),
                Icon(
                  expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Corte: día ${perfil.diaCorte}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (!expandido) ...[
              const SizedBox(height: 6),
              Text(
                'Gastos ${perfil.porcentajeGastos.round()}%  ·  '
                'Deudas ${perfil.porcentajeDeudas.round()}%  ·  '
                'Imprevistos ${perfil.porcentajeImprevistos.round()}%  ·  '
                'Ahorros ${perfil.porcentajeAhorros.round()}%  ·  '
                'Emergencia ${perfil.porcentajeEmergencia.round()}%',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _PerfilDetalle(perfil: perfil, provider: provider),
              ),
              crossFadeState:
                  expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PerfilDetalle extends StatelessWidget {
  const _PerfilDetalle({required this.perfil, required this.provider});
  final Presupuesto perfil;
  final PresupuestoProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          perfil.descripcion?.isNotEmpty == true
              ? perfil.descripcion!
              : 'Sin descripción.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _CategoriaBar(categoriaKey: 'gastos', porcentaje: perfil.porcentajeGastos),
        _CategoriaBar(categoriaKey: 'deudas', porcentaje: perfil.porcentajeDeudas),
        _CategoriaBar(
            categoriaKey: 'imprevistos', porcentaje: perfil.porcentajeImprevistos),
        _CategoriaBar(categoriaKey: 'ahorros', porcentaje: perfil.porcentajeAhorros),
        _CategoriaBar(
            categoriaKey: 'emergencia', porcentaje: perfil.porcentajeEmergencia),
        const SizedBox(height: 4),
        Row(
          children: [
            if (!perfil.activo) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: provider.accionEnCurso
                      ? null
                      : () => _activarPerfil(context, provider, perfil),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text(
                    'Activar perfil',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    mostrarFormularioPerfil(context, provider: provider, perfil: perfil),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: const Text('Editar ›'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _activarPerfil(
  BuildContext context,
  PresupuestoProvider provider,
  Presupuesto perfil,
) async {
  final ok = await provider.activarPerfil(perfil.idPresupuesto);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Perfil "${perfil.nombre}" activado' : (provider.errorMessage ?? 'Error'),
      ),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ),
  );
}

// ─────────────────────────── Diálogos ───────────────────────────

Future<void> _mostrarDialogoAbrirPeriodo(
  BuildContext context,
  PresupuestoProvider provider,
) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DialogoMonto(
      titulo: 'Abrir nuevo período',
      etiqueta: 'Ingreso estimado',
      controller: controller,
      textoConfirmar: 'Abrir período',
    ),
  );
  if (ok != true) return;
  final valor = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '.'));
  if (valor == null || valor < 0) return;
  final exito = await provider.abrirPeriodo(valor);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(exito ? 'Período abierto' : (provider.errorMessage ?? 'Error')),
      backgroundColor: exito ? AppColors.success : AppColors.error,
    ),
  );
}

Future<void> _mostrarDialogoAjustarIngreso(
  BuildContext context,
  PresupuestoProvider provider,
  PeriodoPresupuesto periodo,
) async {
  final controller =
      TextEditingController(text: periodo.ingresoEstimado.round().toString());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DialogoMonto(
      titulo: 'Ajustar ingreso estimado',
      etiqueta: 'Nuevo ingreso estimado',
      controller: controller,
      textoConfirmar: 'Guardar',
    ),
  );
  if (ok != true) return;
  final valor = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '.'));
  if (valor == null || valor < 0) return;
  final exito = await provider.ajustarIngreso(valor);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        exito ? 'Ingreso ajustado y montos recalculados' : (provider.errorMessage ?? 'Error'),
      ),
      backgroundColor: exito ? AppColors.success : AppColors.error,
    ),
  );
}

Future<void> _mostrarDialogoCerrarPeriodo(
  BuildContext context,
  PresupuestoProvider provider,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Cerrar período', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text(
        'Esta acción no se puede deshacer. Se calculará el ingreso real y el período pasará a estado "cerrado".',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cerrar período', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmar != true) return;
  final exito = await provider.cerrarPeriodo();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(exito ? 'Período cerrado' : (provider.errorMessage ?? 'Error')),
      backgroundColor: exito ? AppColors.success : AppColors.error,
    ),
  );
}

class _DialogoMonto extends StatelessWidget {
  const _DialogoMonto({
    required this.titulo,
    required this.etiqueta,
    required this.controller,
    required this.textoConfirmar,
  });

  final String titulo;
  final String etiqueta;
  final TextEditingController controller;
  final String textoConfirmar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(titulo, style: const TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixText: '\$ ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoConfirmar, style: const TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }
}