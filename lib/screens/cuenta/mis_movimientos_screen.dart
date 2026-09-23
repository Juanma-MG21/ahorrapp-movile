import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

import '../../models/movimiento.dart';
import '../../services/cuenta_service.dart';
import 'widgets/movimiento_tile.dart';
import 'widgets/seccion_card.dart';

/// Vista completa (pantalla dedicada, no el resumen embebido) de
/// "Mis movimientos": todo lo que el usuario ha registrado —ahorros,
/// ingresos, gastos, deudas e imprevistos— agrupado por fecha, igual
/// que un extracto de movimientos de una billetera.
///
/// Se abre desde "Mi cuenta" con el botón "Ver todos". Vive en su
/// propia pantalla para no saturar la vista principal de cuenta.
class MisMovimientosScreen extends StatefulWidget {
  const MisMovimientosScreen({super.key});

  @override
  State<MisMovimientosScreen> createState() => _MisMovimientosScreenState();
}

class _MisMovimientosScreenState extends State<MisMovimientosScreen> {
  late Future<List<Movimiento>> _futureMovimientos;

  @override
  void initState() {
    super.initState();
    _futureMovimientos = CuentaService.instance.getMovimientos();
  }

  Future<void> _recargar() async {
    setState(() {
      _futureMovimientos = CuentaService.instance.getMovimientos();
    });
    await _futureMovimientos;
  }

  String _tituloGrupo(DateTime fecha) {
    final hoy = DateTime.now();
    final esHoy = fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
    final ayer = hoy.subtract(const Duration(days: 1));
    final esAyer = fecha.year == ayer.year && fecha.month == ayer.month && fecha.day == ayer.day;

    if (esHoy) return 'Hoy';
    if (esAyer) return 'Ayer';

    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]}${fecha.year != hoy.year ? ' de ${fecha.year}' : ''}';
  }

  Map<String, List<Movimiento>> _agrupar(List<Movimiento> movimientos) {
    final Map<String, List<Movimiento>> grupos = {};
    for (final mov in movimientos) {
      final fecha = mov.fecha;
      final clave = fecha == null ? 'Sin fecha' : _tituloGrupo(fecha);
      grupos.putIfAbsent(clave, () => []).add(mov);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mis movimientos',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Movimiento>>(
          future: _futureMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            final movimientos = snapshot.data ?? [];

            if (movimientos.isEmpty) {
              return RefreshIndicator(
                color: AppColors.accent,
                onRefresh: _recargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Todavía no tienes movimientos registrados',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            final grupos = _agrupar(movimientos);
            final claves = grupos.keys.toList();

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _recargar,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: claves.length,
                itemBuilder: (context, index) {
                  final clave = claves[index];
                  final items = grupos[clave]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SeccionCard(
                      title: clave,
                      children: [for (final mov in items) MovimientoTile(movimiento: mov)],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
