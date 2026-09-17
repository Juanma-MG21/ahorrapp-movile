import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/periodo_presupuesto_model.dart';
import '../../models/reportes/informe_completo.dart';
import '../../services/reportes_service.dart';
import '../../core/utils/pdf/reporte_pdf_builder.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ReportesService _reportesService = ReportesService();

  static final DateFormat _formatoCorto = DateFormat('dd/MM/yyyy');

  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  List<PeriodoPresupuesto> _periodos = [];
  bool _cargandoPeriodos = true;

  int? _idPeriodoSeleccionado;

  InformeCompleto? _informe;
  bool _cargandoInforme = false;
  bool _generandoPDF = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fechaInicio = DateTime(ahora.year, ahora.month, 1);
    _fechaFin = DateTime(ahora.year, ahora.month, ahora.day);
    _cargarPeriodos();
  }

  Future<void> _cargarPeriodos() async {
    try {
      final periodos = await _reportesService.getPeriodosDisponibles();
      if (!mounted) return;
      setState(() => _periodos = periodos);
    } catch (_) {
      // El presupuesto es opcional: si falla la carga, el selector
      // queda vacío pero el resto de la pantalla sigue funcionando.
      if (!mounted) return;
      setState(() => _periodos = []);
    } finally {
      if (mounted) setState(() => _cargandoPeriodos = false);
    }
  }

  /// Un renglón por presupuesto: de cada uno se toma el período abierto
  /// si existe, o si no, el cerrado más reciente por fecha fin. Igual
  /// que "presupuestosUnicos" en la versión web.
  List<PeriodoPresupuesto> get _presupuestosUnicos {
    final porPresupuesto = <int, PeriodoPresupuesto>{};

    for (final p in _periodos) {
      final idPresupuesto = p.idPresupuesto;
      if (idPresupuesto == null) continue;

      final actual = porPresupuesto[idPresupuesto];
      if (actual == null) {
        porPresupuesto[idPresupuesto] = p;
        continue;
      }

      final actualGana = actual.abierto ||
          (!p.abierto &&
              (actual.fechaFin ?? DateTime(0))
                      .compareTo(p.fechaFin ?? DateTime(0)) >=
                  0);

      if (!actualGana) porPresupuesto[idPresupuesto] = p;
    }

    final lista = porPresupuesto.values.toList()
      ..sort(
        (a, b) => (a.perfilNombre ?? '').compareTo(b.perfilNombre ?? ''),
      );
    return lista;
  }

  Future<void> _seleccionarFecha({required bool esInicio}) async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (seleccionada == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = seleccionada;
      } else {
        _fechaFin = seleccionada;
      }
    });
  }

  Future<void> _consultarInforme() async {
    setState(() => _error = null);

    if (_fechaInicio.isAfter(_fechaFin)) {
      setState(() {
        _error =
            'La fecha de inicio no puede ser posterior a la fecha de fin.';
      });
      return;
    }

    setState(() => _cargandoInforme = true);

    try {
      final informe = await _reportesService.obtenerInformeCompleto(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        idPeriodo: _idPeriodoSeleccionado,
      );
      if (!mounted) return;
      setState(() => _informe = informe);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No fue posible obtener la información del informe.',
      );
    } finally {
      if (mounted) setState(() => _cargandoInforme = false);
    }
  }

  Future<void> _descargarPDF() async {
  
    final informe = _informe;
    if (informe == null) {
      setState(() => _error = 'Primero debes consultar el informe.');
      return;
    }

    setState(() {
      _error = null;
      _generandoPDF = true;
    });

    try {
      
      await ReportePdfBuilder.generarYCompartir(informe);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No fue posible generar el PDF.');
    } finally {
      if (mounted) setState(() => _generandoPDF = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final informe = _informe;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes financieros')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Consulta y descarga un informe completo de tu información '
              'financiera.',
            ),
            const SizedBox(height: 16),
            _tarjetaFiltros(),
            const SizedBox(height: 16),
            if (_error != null) _bannerError(_error!),
            if (informe == null && !_cargandoInforme) _tarjetaEstadoInicial(),
            if (_cargandoInforme)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (informe != null) ...[
              const SizedBox(height: 8),
              Text(
                'Información incluida',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...informe.disponibilidad.entries.map(
                (e) => _filaDisponibilidad(e.key, e.value),
              ),
              const SizedBox(height: 24),
              _tarjetaDescargarPDF(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tarjetaFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Periodo del informe',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _campoFecha(
                    etiqueta: 'Fecha inicial',
                    fecha: _fechaInicio,
                    onTap: () => _seleccionarFecha(esInicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campoFecha(
                    etiqueta: 'Fecha final',
                    fecha: _fechaFin,
                    onTap: () => _seleccionarFecha(esInicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _selectorPresupuesto(),
            const SizedBox(height: 4),
            Text(
              'Se usará el período abierto de ese presupuesto, o si no '
              'hay uno, el último cerrado.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _cargandoInforme ? null : _consultarInforme,
                  child: Text(
                    _cargandoInforme ? 'Consultando...' : 'Consultar informe',
                  ),
                ),
                OutlinedButton(
                  onPressed: (_informe == null || _generandoPDF)
                      ? null
                      : _descargarPDF,
                  child: Text(
                    _generandoPDF ? 'Generando PDF...' : 'Descargar PDF',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoFecha({
    required String etiqueta,
    required DateTime fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        child: Text(_formatoCorto.format(fecha)),
      ),
    );
  }

  Widget _selectorPresupuesto() {
    final opciones = _presupuestosUnicos;

    return DropdownButtonFormField<int?>(
      value: _idPeriodoSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Presupuesto',
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(
            _cargandoPeriodos ? 'Cargando...' : 'Ninguno (opcional)',
          ),
        ),
        ...opciones.map((p) {
          final inicioTexto = p.fechaInicio != null
              ? _formatoCorto.format(p.fechaInicio!)
              : '?';
          final finTexto =
              p.fechaFin != null ? _formatoCorto.format(p.fechaFin!) : '?';
          final estadoTexto = p.abierto ? '(en curso)' : '(último cerrado)';

          return DropdownMenuItem<int?>(
            value: p.idPeriodo,
            child: Text(
              '${p.perfilNombre ?? 'Presupuesto'} — '
              '$inicioTexto → $finTexto $estadoTexto',
            ),
          );
        }),
      ],
      onChanged: _cargandoPeriodos
          ? null
          : (valor) => setState(() => _idPeriodoSeleccionado = valor),
    );
  }

  Widget _bannerError(String mensaje) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(mensaje, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _tarjetaEstadoInicial() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Genera tu informe financiero',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el periodo que deseas consultar y presiona '
              '"Consultar informe".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaDisponibilidad(String titulo, bool disponible) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo),
          Text(
            disponible ? 'Disponible' : 'Sin datos',
            style: TextStyle(
              color: disponible ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDescargarPDF() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Informe listo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'El informe contiene el resumen, distribución financiera, '
              'ahorros, deudas, imprevistos, fondo de emergencia, '
              'presupuesto y evolución disponibles para el periodo '
              'seleccionado.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generandoPDF ? null : _descargarPDF,
              child: Text(
                _generandoPDF
                    ? 'Generando PDF...'
                    : 'Descargar informe completo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}