import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/design_tokens.dart';
import '../../models/ingreso_model.dart';
import '../../services/ingresos_service.dart';
import '../../services/supabase_service.dart';
import '../../services/widget_service.dart';
import '../../services/voice_parser_ingreso_service.dart';
import 'agregar_ingreso_screen.dart';

class ModuloIngresos extends StatefulWidget {
  const ModuloIngresos({super.key});

  @override
  State<ModuloIngresos> createState() => _ModuloIngresosState();
}

class _ModuloIngresosState extends State<ModuloIngresos>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  int? _expandedIndex;
  List<IngresoModel> _ingresos = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isModalShowing = false;
  String _lastWords = '';

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
          i.categoriaNombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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
    _speech = stt.SpeechToText();
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

  void _loadIngresos() async {
    setState(() => _isLoading = true);
    final list = await IngresosService.obtenerIngresos();
    setState(() {
      _ingresos = list;
      _isLoading = false;
    });
    _updateWidget();
  }

  void _updateWidget() async {
    final now = DateTime.now();
    final gastos = await SupabaseService.fetchGastos();
    double totalGastos = 0;
    for (var g in gastos.where((g) => g.fecha.month == now.month && g.fecha.year == now.year)) {
      totalGastos += g.monto;
    }

    double totalIngresos = 0;
    for (var i in _ingresos.where((i) => i.fechaRegistro.month == now.month && i.fechaRegistro.year == now.year)) {
      totalIngresos += i.monto;
    }

    final double balance = totalIngresos - totalGastos;

    WidgetService.updateWidgetData(
      balance: _formatCurrency(balance),
      gastos: _formatCurrency(totalGastos),
      ingresos: _formatCurrency(totalIngresos),
      porcentaje: 0,
      fecha: '${_mesesNom[now.month - 1]} ${now.year}',
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
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

      if (resultado != null) {
        setState(() {
          _ingresos.insert(0, resultado);
        });
        _updateWidget();
      }
    }
    if (metodo == 'Registro por voz') {
      _startListening();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'notListening' || val == 'done') {
          if (mounted && _isListening) {
            _stopListeningAndProcess();
          } else if (mounted && _isModalShowing && _lastWords.isEmpty) {
            _closeVoiceModal();
          }
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _isProcessing = false;
          });
          _closeVoiceModal();
        }
      },
    );

    if (!mounted) return;

    if (available) {
      setState(() {
        _isListening = true;
        _isProcessing = false;
        _lastWords = '';
      });
      _showVoiceModal();
      _speech.listen(
        onResult: (val) => setState(() {
          _lastWords = val.recognizedWords;
        }),
        listenOptions: stt.SpeechListenOptions(
          localeId: 'es_CO',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El reconocimiento de voz no está disponible')),
      );
    }
  }

  void _closeVoiceModal() {
    if (mounted && _isModalShowing) {
      _isModalShowing = false;
      Navigator.of(context).pop();
    }
  }

  void _stopListeningAndProcess() {
    setState(() => _isListening = false);

    if (_lastWords.isNotEmpty) {
      setState(() => _isProcessing = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _closeVoiceModal();
          _processVoiceResult(_lastWords);
          setState(() => _isProcessing = false);
        }
      });
    } else {
      _closeVoiceModal();
    }
  }

  void _processVoiceResult(String text) async {
    final IngresoModel parsedIngreso = VoiceParserIngresoService.parse(text);

    final resultado = await Navigator.push<IngresoModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarIngresoScreen(ingresoParaEditar: parsedIngreso),
      ),
    );

    if (resultado != null) {
      setState(() {
        _ingresos.insert(0, resultado);
      });
      _updateWidget();
    }
  }

  void _showVoiceModal() {
    _isModalShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeOut.transform(animation.value);
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    _speech.stop();
                    _closeVoiceModal();
                  },
                  child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                    child: const SizedBox.expand(),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * t,
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildVoiceCard(),
                      ),
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

  Widget _buildVoiceCard() {
    String mainText = 'Escuchando tu voz...';
    if (_isProcessing) mainText = 'Detectando audio…';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoicePulseButton(
            isListening: _isListening,
            isProcessing: _isProcessing,
          ),
          const SizedBox(height: 22),
          Text(
            mainText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_lastWords.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _lastWords,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            )
          else if (!_isProcessing)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Di algo como: ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const TextSpan(
                    text: '"Recibí un millón de pesos de salario"',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Ahorrapp puede cometer errores. Verifica siempre la información antes de guardar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          if (!_isProcessing)
            GestureDetector(
              onTap: () {
                _speech.stop();
                _closeVoiceModal();
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8),
                    BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8),
                    BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8),
                  ],
                ),
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
        boxShadow: [
          BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
          Text(
            'TOTAL INGRESOS',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatCurrency(totalIngresos),
                  style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 32),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_mesesNom[_selectedDate.month - 1]} ${_selectedDate.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tendencia positiva', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text('${_filteredIngresos.length} registros', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngresosListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Ingresos del mes', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${_filteredIngresos.length} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildIngresosList() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: Color(0xFF4ADE80))));
    final filtered = _filteredIngresos.reversed.toList();
    if (filtered.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Column(children: [
        Icon(Icons.receipt_long, color: AppColors.textSecondary.withValues(alpha: 0.3), size: 64),
        const SizedBox(height: 16),
        Text('No hay ingresos en ${_mesesNom[_selectedDate.month - 1]}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ])));
    }
    return Column(children: List.generate(filtered.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildIngresoCard(filtered[index], index))));
  }

  Widget _buildIngresoCard(IngresoModel ingreso, int index) {
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: _NeumorphicContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ingreso.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ingreso.icono,
                      color: ingreso.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingreso.titulo,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ingreso.subtitulo,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${_formatCurrency(ingreso.monto)}',
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildDetailItem('CATEGORÍA', ingreso.categoriaNombre),
                        _buildDetailItem('FECHA', '${ingreso.fechaRegistro.day.toString().padLeft(2, '0')}/${ingreso.fechaRegistro.month.toString().padLeft(2, '0')}/${ingreso.fechaRegistro.year}'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildDetailItem('FUENTE', ingreso.fuente ?? 'No especificada'),
                        _buildDetailItem('MONTO', '+${_formatCurrency(ingreso.monto)}', color: const Color(0xFF4ADE80)),
                      ],
                    ),
                    if (ingreso.descripcion != null && ingreso.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildDetailItem('DESCRIPCIÓN', ingreso.descripcion!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Editar',
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF4ADE80),
                            onTap: () async {
                              final resultado = await Navigator.push<IngresoModel>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AgregarIngresoScreen(ingresoParaEditar: ingreso),
                                ),
                              );

                              if (resultado != null) {
                                setState(() {
                                  final idx = _ingresos.indexWhere((i) => i.id == ingreso.id);
                                  if (idx != -1) _ingresos[idx] = resultado;
                                  _expandedIndex = null;
                                });
                                _updateWidget();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Eliminar',
                            icon: Icons.delete_outline,
                            color: AppColors.error,
                            onTap: () => _mostrarConfirmacion(ingreso),
                          ),
                        ),
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
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (ingreso.id != null) {
                  final success = await IngresosService.eliminarIngreso(ingreso.id!);
                  if (success) {
                    setState(() {
                      _ingresos.removeWhere((i) => i.id == ingreso.id);
                      _expandedIndex = null;
                    });
                    _updateWidget();
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.2), foregroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.error, width: 1))),
              child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]));
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4), width: 1), boxShadow: const [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 6), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 6)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}

// ---------- BOTÓN DE MICRÓFONO CON ANILLOS PULSANTES ----------

class _VoicePulseButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  const _VoicePulseButton({required this.isListening, required this.isProcessing});

  @override
  State<_VoicePulseButton> createState() => _VoicePulseButtonState();
}

class _VoicePulseButtonState extends State<_VoicePulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProcessing) {
      return SizedBox(
        width: 150, height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(color: Color(0xFF4ADE80), strokeWidth: 3)),
            Container(width: 60, height: 60, decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Color(0xFF4ADE80), size: 28)),
          ],
        ),
      );
    }

    return AnimatedScale(
      scale: widget.isListening ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        width: 150, height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final t = (_pulseController.value + i * 0.33) % 1.0;
                    final scale = 1.0 + 0.8 * t;
                    final opacity = (1 - t) * 0.5;
                    return Transform.scale(
                      scale: scale,
                      child: Container(width: 96, height: 96, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: opacity), width: 2))),
                    );
                  },
                );
              }),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: widget.isListening ? [const Color(0xFFD1FAE5), const Color(0xFF4ADE80)] : [const Color(0xFF4ADE80), const Color(0xFF34D399)]),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: widget.isListening ? 0.6 : 0.4), blurRadius: widget.isListening ? 35 : 25, spreadRadius: widget.isListening ? 4 : 2),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(widget.isListening ? Icons.mic : Icons.mic_none, color: Colors.black, size: 40),
            ),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8), BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8)]), child: Icon(icon, color: AppColors.textSecondary, size: size)),
    );
  }
}