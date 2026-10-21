import '../../services/auth_service.dart';
import '../../widgets/voice_entry_dialog.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/sync_state_badge.dart';
import '../../widgets/offline_query_banner.dart';
import '../../services/offline_query_service.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/design_tokens.dart';
import '../../models/ingreso_model.dart';
import '../../services/ingresos_service.dart';
import '../../services/widget_service.dart';
import '../../services/local_parser_service.dart';
import 'agregar_ingreso_screen.dart';

class ModuloIngresos extends StatefulWidget {
  final stt.SpeechToText? speechInstance;
  const ModuloIngresos({super.key, this.speechInstance});

  @override
  State<ModuloIngresos> createState() => _ModuloIngresosState();
}

class _ModuloIngresosState extends State<ModuloIngresos>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isMenuOpen = false;
  int? _expandedIndex;
  List<IngresoModel> _ingresos = [];
  bool _isLoading = true;
  int _loadVersion = 0;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  late stt.SpeechToText _speech;

  static const List<String> _mesesNom = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  late AnimationController _menuController;
  late List<Animation<double>> _itemAnimations;

  List<IngresoModel> get _filteredIngresos {
    return _ingresos.where((i) {
      final matchesDate = i.fechaRegistro.month == _selectedDate.month && i.fechaRegistro.year == _selectedDate.year;
      final matchesSearch = _searchQuery.isEmpty ||
          (i.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          i.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (i.fuente?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesDate && matchesSearch;
    }).toList();
  }

  void _changeMonth(int delta) {
    final now = DateTime.now();
    final newDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + delta,
      1,
    );

    if (delta > 0) {
      if (newDate.year > now.year || (newDate.year == now.year && newDate.month > now.month)) {
        return;
      }
    }

    setState(() {
      _selectedDate = newDate;
    });
  }

  @override
  void initState() {
    super.initState();
    OfflineSyncService.instance.changes.addListener(_reloadLocal);
    WidgetsBinding.instance.addObserver(this);
    _speech = widget.speechInstance ?? stt.SpeechToText();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _itemAnimations = List.generate(2, (i) {
      return CurvedAnimation(
        parent: _menuController,
        curve: Interval(0.3 + i * 0.2, 1.0, curve: Curves.easeOutCubic),
      );
    });

    _loadIngresos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadIngresos();
  }

  void _loadIngresos() async {
    if (!mounted) return;
    final loadVersion = ++_loadVersion;
    setState(() => _isLoading = true);
    try {
      final list = await IngresosService.obtenerIngresos();
      if (!mounted || loadVersion != _loadVersion) return;
      setState(() => _ingresos = list);
      _updateWidget();
    } catch (error) {
      if (!mounted || loadVersion != _loadVersion) return;
      List<IngresoModel> local = [];
      try { local = await OfflineQueryService.instance.localList('/movimientos/ingresos', IngresoModel.fromJson); } catch (_) { /* El aviso de consulta conserva el fallo. */ }
      if (!mounted || loadVersion != _loadVersion) return;
      setState(() => _ingresos = local);
    } finally {
      if (mounted && loadVersion == _loadVersion) setState(() => _isLoading = false);
    }
  }

  void _updateWidget() {
    WidgetService.refresh();
  }


  Future<void> _reloadLocal() async {
    final version = ++_loadVersion;
    try {
      final rows = await OfflineQueryService.instance.localList('/movimientos/ingresos', IngresoModel.fromJson);
      if (!mounted || version != _loadVersion) return;
      setState(() { _ingresos = rows; _isLoading = false; });
      _updateWidget();
    } catch (_) { /* La consulta principal presenta el error de almacenamiento. */ }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuController.dispose();
    OfflineSyncService.instance.changes.removeListener(_reloadLocal);
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _onOptionSelected(String metodo) async {
    _toggleMenu();
    if (metodo == 'Agregar manualmente') {
      final resultado = await Navigator.push<IngresoModel>(
        context,
        MaterialPageRoute(builder: (context) => const AgregarIngresoScreen()),
      );
      if (resultado != null) _loadIngresos();
    }
    if (metodo == 'Registro por voz') {
      _startListening();
    }
  }

  bool _voiceOpen = false;
  Future<void> _startListening() async {
    if (_voiceOpen) return;
    _voiceOpen = true;
    final auth = AuthService.instance;
    final version = auth.sessionVersion;
    try {
      final text = await showDialog<String>(context: context,
        builder: (_) => VoiceEntryDialog(speech: _speech, income: true));
      if (!mounted || text == null || !identical(auth, AuthService.instance) || version != auth.sessionVersion) return;
      final parsed = LocalParserService.parseIngreso(text);
      final resultado = await Navigator.push<IngresoModel>(context, MaterialPageRoute(
        builder: (_) => AgregarIngresoScreen(ingresoParaEditar: parsed)));
      if (mounted && resultado != null) _loadIngresos();
    } finally {
      _voiceOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  OfflineQueryBanner(
                      resource: '/movimientos/ingresos',
                      onRetry: _loadIngresos),
                  const SizedBox(height: 30),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 30),
                  _buildIngresosListHeader(),
                  const SizedBox(height: 20),
                  _buildIngresosList(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: AnimatedBuilder(
                  animation: _menuController,
                  builder: (context, child) {
                    final t = _menuController.value;
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                      child: GestureDetector(
                        onTap: _toggleMenu,
                        child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    ignoring: !_isMenuOpen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMenuItem(
                          label: 'Agregar manualmente',
                          icon: Icons.edit,
                          animation: _itemAnimations[1],
                          onTap: () => _onOptionSelected('Agregar manualmente'),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          label: 'Registro por voz',
                          icon: Icons.mic,
                          animation: _itemAnimations[0],
                          onTap: () => _onOptionSelected('Registro por voz'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  _buildFAB(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFF4ADE80), size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF4ADE80), Color(0xFF34D399)]),
        border: Border.all(color: Colors.white.withValues(alpha: _isMenuOpen ? 0.9 : 0), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggleMenu,
          child: Center(
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: const Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedDate.year == now.year && _selectedDate.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _NeumorphicIcon(icon: Icons.arrow_back_ios, size: 12, onTap: () => _changeMonth(-1)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_mesesNom[_selectedDate.month - 1], style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('${_selectedDate.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(width: 12),
            if (!isCurrentMonth) _NeumorphicIcon(icon: Icons.arrow_forward_ios, size: 12, onTap: () => _changeMonth(1))
            else const SizedBox(width: 40),
          ],
        ),
        Row(
          children: [
            _NeumorphicIcon(icon: Icons.notifications_outlined, size: 22, onTap: () {}),
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF34D399)])),
              child: const Icon(Icons.person, color: Colors.black, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return _NeumorphicContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar ingreso o fuente...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Color(0xFF4ADE80), size: 20),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    String formatted = amount.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return '${amount < 0 ? "-" : ""}\$$formatted';
  }

  Widget _buildSummaryCard() {
    if (OfflineQueryService.instance.statuses.value['/movimientos/ingresos']?.source == QuerySource.unavailable && _ingresos.isEmpty) {
      return const SizedBox.shrink();
    }
    double totalIngresos = 0;
    for (var i in _filteredIngresos) {
      totalIngresos += i.monto;
    }
    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL INGRESOS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(_formatCurrency(totalIngresos), style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 32, fontWeight: FontWeight.bold))),
              const Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngresosListHeader() {
    if (OfflineQueryService.instance.statuses.value['/movimientos/ingresos']?.source == QuerySource.unavailable && _ingresos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Ingresos del mes', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${_filteredIngresos.length} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildIngresosList() {
    if (OfflineQueryService.instance.statuses.value['/movimientos/ingresos']?.source == QuerySource.unavailable && _ingresos.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: Color(0xFF4ADE80))));
    final filtered = _filteredIngresos.reversed.toList();
    if (filtered.isEmpty) return Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [Icon(Icons.receipt_long, color: AppColors.textSecondary.withValues(alpha: 0.3), size: 64), const SizedBox(height: 16), const Text('No hay ingresos registrados', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))])));
    return Column(children: List.generate(filtered.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [SyncStateBadge(state: filtered[index].syncState, error: filtered[index].syncError), _buildIngresoCard(filtered[index], index)]))));
  }

  Widget _buildIngresoCard(IngresoModel ingreso, int index) {
    final isExpanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: _NeumorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: ingreso.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(ingreso.icono, color: ingreso.color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(ingreso.titulo, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(ingreso.subtitulo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
                  Text('+${_formatCurrency(ingreso.monto)}', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  AnimatedRotation(turns: isExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20)),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    Row(children: [_buildDetailItem('CATEGORÍA', ingreso.titulo), _buildDetailItem('FECHA', '${ingreso.fechaRegistro.day.toString().padLeft(2, '0')}/${ingreso.fechaRegistro.month.toString().padLeft(2, '0')}/${ingreso.fechaRegistro.year}')]),
                    const SizedBox(height: 18),
                    Row(children: [_buildDetailItem('FUENTE', ingreso.fuente ?? 'No especificada'), _buildDetailItem('MONTO', '+${_formatCurrency(ingreso.monto)}', color: const Color(0xFF4ADE80))]),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton(label: ingreso.canCorrect ? 'Corregir' : 'Editar', icon: Icons.edit_outlined, color: const Color(0xFF4ADE80), onTap: () async {
                          if (!ingreso.isSynced && !ingreso.canCorrect) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincroniza este registro antes de editarlo.'))); return;
                          }
                          final resultado = await Navigator.push<IngresoModel>(context, MaterialPageRoute(builder: (context) => AgregarIngresoScreen(ingresoParaEditar: ingreso)));
                          if (resultado != null) _loadIngresos();
                        })),
                        const SizedBox(width: 16),
                        Expanded(child: _buildActionButton(label: 'Eliminar', icon: Icons.delete_outline, color: AppColors.error, onTap: () { if (ingreso.isSynced) { _mostrarConfirmacion(ingreso); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincroniza antes de eliminar.'))); } })),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacion(IngresoModel ingreso) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Confirmar eliminación', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: const Text('¿Seguro de que quieres eliminar este ingreso?', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (ingreso.id != null) {
                  bool success = false;
                  try {
                    success = await IngresosService.eliminarIngreso(ingreso.id!);
                  } catch (error) {
                    if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('$error')));
                  }
                  if (!mounted) return;
                  if (success) _loadIngresos();
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.2), foregroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)), const SizedBox(height: 5), Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)]));
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4), width: 1)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))])));
  }
}

class _NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  const _NeumorphicContainer({required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(borderRadius), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(4, 4), blurRadius: 12), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-4, -4), blurRadius: 12)]), child: child);
  }
}

class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _NeumorphicIcon({required this.icon, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8)]), child: Icon(icon, color: AppColors.textSecondary, size: size)));
  }
}
