import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/design_tokens.dart';
import '../../models/gasto_model.dart';
import '../../services/voice_parser_service.dart';
import '../../services/widget_service.dart';
import '../../services/gastos_service.dart';
import 'agregar_gasto_screen.dart';

import '../../services/qr_parser_service.dart';
import '../qr_scanner_screen.dart';

class ModuloGastos extends StatefulWidget {
  const ModuloGastos({super.key});

  @override
  State<ModuloGastos> createState() => _ModuloGastosState();
}

class _ModuloGastosState extends State<ModuloGastos>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  int? _expandedIndex;
  List<GastoModel> _gastos = [];
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

  List<GastoModel> get _filteredGastos {
    return _gastos.where((g) {
      final matchesDate = g.fecha.month == _selectedDate.month && g.fecha.year == _selectedDate.year;
      final matchesSearch = _searchQuery.isEmpty ||
          g.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
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

    // No permitir navegar a meses futuros
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

    // Animación escalonada: primero aparece la opción más cercana al botón
    _itemAnimations = List.generate(3, (i) {
      return CurvedAnimation(
        parent: _menuController,
        curve: Interval(0.3 + i * 0.2, 1.0, curve: Curves.easeOutCubic),
      );
    });

    _loadGastos();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateWidget();
    });
  }

  void _loadGastos() async {
    setState(() => _isLoading = true);
    final list = await GastosService.obtenerGastos();
    setState(() {
      _gastos = list;
      _isLoading = false;
    });
    _updateWidget();
  }

  void _updateWidget() {
    double totalGastos = 0;
    final now = DateTime.now();
    final gastosMes = _gastos
        .where((g) => g.fecha.month == now.month && g.fecha.year == now.year)
        .toList();

    for (var g in gastosMes) {
      totalGastos += g.monto;
    }

    const double presupuesto = 0;
    final double balance = presupuesto - totalGastos;
    final double porcentaje =
    presupuesto > 0 ? (totalGastos / presupuesto * 100).clamp(0, 100) : 0;

    WidgetService.updateWidgetData(
      balance: _formatCurrency(balance),
      gastos: _formatCurrency(totalGastos),
      ingresos: _formatCurrency(0),
      porcentaje: porcentaje.toInt(),
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
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AgregarGastoScreen()),
      );

      if (resultado == true) {
        // Recargamos desde el backend en vez de armar el card a mano:
        // crearMovimiento no devuelve el nombre de categoría/dependiente.
        _loadGastos();
      }
    }
    if (metodo == 'Registro por voz') {
      _startListening();
    }

    if (metodo == 'Escanear QR') {
      final String? textoQr = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
      );

      if (textoQr != null && textoQr.trim().isNotEmpty) {
        _processQrResult(textoQr);
      }
    }

  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('Speech Status: $val');
        if (val == 'notListening' || val == 'done') {
          if (mounted && _isListening) {
            _stopListeningAndProcess();
          } else if (mounted && _isModalShowing && _lastWords.isEmpty) {
            // Si el motor se detiene por timeout y no hay palabras, cerramos el modal
            _closeVoiceModal();
          }
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
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
          pauseFor: const Duration(seconds: 3), // Reducido para mayor velocidad
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
    setState(() {
      _isListening = false;
    });

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
    final GastoModel parsedGasto = VoiceParserService.parse(text);

    // Abrir formulario con los datos pre-llenados
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarGastoScreen(gastoParaEditar: parsedGasto),
      ),
    );

    if (resultado == true) {
      _loadGastos();
    }
  }

  void _processQrResult(String textoQr) async {
    final GastoModel parsedGasto = QrParserService.parse(textoQr);

    // Abrir formulario con los datos pre-llenados, igual que en voz
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarGastoScreen(gastoParaEditar: parsedGasto),
      ),
    );

    if (resultado == true) {
      _loadGastos();
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
                // Oscurece y cierra al tocar fuera
                GestureDetector(
                  onTap: () {
                    _speech.stop();
                    _closeVoiceModal();
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45 * t),
                  ),
                ),
                // Difumina el fondo
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Tarjeta centrada con efecto de escala
                Center(
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * t,
                      child: Material(
                        type: MaterialType.transparency,
                        child: StatefulBuilder(
                            builder: (context, setModalState) {
                              return _buildVoiceCard(setModalState);
                            }
                        ),
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

  Widget _buildVoiceCard(StateSetter setModalState) {
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
                    text: '"Diez mil pesos en una empanada"',
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
          // Botón Cancelar
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
                    BoxShadow(
                      color: Color(0xFF05060D),
                      offset: Offset(3, 3),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Color(0xFF1A1D3A),
                      offset: Offset(-3, -3),
                      blurRadius: 8,
                    ),
                  ],
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
                  _buildExpensesListHeader(),
                  const SizedBox(height: 20),
                  _buildExpensesList(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            // --- FONDO DIFUMINADO + OSCURO CUANDO EL MENÚ ESTÁ ABIERTO ---
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: AnimatedBuilder(
                  animation: _menuController,
                  builder: (context, child) {
                    final t = _menuController.value;
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10 * t,
                        sigmaY: 10 * t,
                      ),
                      child: GestureDetector(
                        onTap: _toggleMenu, // tocar el fondo cierra el menú
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45 * t),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // --- MENÚ DESPLEGABLE + FAB ---
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
                          animation: _itemAnimations[2],
                          onTap: () => _onOptionSelected('Agregar manualmente'),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          label: 'Escanear QR',
                          icon: Icons.photo_camera,
                          animation: _itemAnimations[1],
                          onTap: () => _onOptionSelected('Escanear QR'),
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

  // ---------- MENÚ: OPCIÓN (ETIQUETA + BOTÓN CIRCULAR) ----------
  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.4, 0),
        end: Offset.zero,
      ).animate(animation),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF05060D),
                      offset: Offset(3, 3),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Color(0xFF1A1D3A),
                      offset: Offset(-3, -3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FAB (ROTA A "×" Y GANA ANILLO BLANCO) ----------
  Widget _buildFAB() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFD700), AppColors.accent],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: _isMenuOpen ? 0.9 : 0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggleMenu,
          child: Center(
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0, // 45°: el "+" se vuelve "×"
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedDate.year == now.year && _selectedDate.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _NeumorphicIcon(
              icon: Icons.arrow_back_ios,
              size: 12,
              onTap: () => _changeMonth(-1),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mesesNom[_selectedDate.month - 1],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedDate.year}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            if (!isCurrentMonth)
              _NeumorphicIcon(
                icon: Icons.arrow_forward_ios,
                size: 12,
                onTap: () => _changeMonth(1),
              )
            else
              const SizedBox(width: 40), // Espacio equivalente al icono para mantener alineación
          ],
        ),
        Row(
          children: [
            _NeumorphicIcon(
              icon: Icons.notifications_outlined,
              size: 22,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay notificaciones')),
                );
              },
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil de usuario')),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFF8C00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar gasto o categoría...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: AppColors.accent, size: 20),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount % 1 == 0) {
      String integerPart = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return '\$$integerPart';
    } else {
      String formatted = amount.toStringAsFixed(2);
      List<String> parts = formatted.split('.');
      String integerPart = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return '\$$integerPart,${parts[1]}';
    }
  }

  // ---------- TARJETA RESUMEN (DINÁMICA) ----------
  Widget _buildSummaryCard() {
    double totalGastos = 0;
    final filtered = _filteredGastos;
    for (var g in filtered) {
      totalGastos += g.monto;
    }
    const double presupuesto = 0;
    final double disponible = presupuesto - totalGastos;
    final double porcentaje = presupuesto > 0 ? (totalGastos / presupuesto).clamp(0.0, 1.0) : 0.0;

    return _NeumorphicContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Columna izquierda ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL GASTOS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(totalGastos),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_mesesNom[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // --- Columna derecha ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PRESUPUESTO',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatCurrency(presupuesto),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(porcentaje),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(porcentaje * 100).toStringAsFixed(0)}% utilizado',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '${filtered.length} registros',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Disponible: ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: _formatCurrency(disponible),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BARRA DE PROGRESO ----------
  Widget _buildProgressBar(double porcentaje) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: porcentaje,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFFFD700)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- LISTA DE GASTOS ----------
  Widget _buildExpensesListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Gastos del mes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${_filteredGastos.length} total',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final filtered = _filteredGastos.reversed.toList();
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.receipt_long, color: AppColors.textSecondary.withValues(alpha: 0.3), size: 64),
              const SizedBox(height: 16),
              Text(
                'No hay gastos en ${_mesesNom[_selectedDate.month - 1]}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(filtered.length, (index) {
        final expense = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildExpenseCard(expense, index),
        );
      }),
    );
  }

  Widget _buildExpenseCard(GastoModel expense, int index) {
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: expense.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      expense.icono,
                      color: expense.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.titulo,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.subtitulo,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${_formatCurrency(expense.monto)}',
                    style: const TextStyle(
                      color: AppColors.error,
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
                        _buildDetailItem('CATEGORÍA', expense.titulo),
                        _buildDetailItem('FECHA', '${expense.fecha.day.toString().padLeft(2, '0')}/${expense.fecha.month.toString().padLeft(2, '0')}/${expense.fecha.year}'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildDetailItem('DESCRIPCIÓN', expense.description),
                        _buildDetailItem('MONTO', '-${_formatCurrency(expense.monto)}', color: AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildDetailItem('RESPONSABLE', expense.responsableNombre),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Editar',
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF4ADE80),
                            onTap: () async {
                              final resultado = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AgregarGastoScreen(gastoParaEditar: expense),
                                ),
                              );

                              if (resultado == true) {
                                setState(() => _expandedIndex = null);
                                _loadGastos();
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
                            onTap: () {
                              _mostrarDialogoConfirmacion(context, expense);
                            },
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

  void _mostrarDialogoConfirmacion(BuildContext context, GastoModel expense) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Confirmar eliminación',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '¿Seguro de que quieres eliminar este gasto?',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (expense.id != null) {
                  final success = await GastosService.eliminarGasto(expense.id!);
                  if (success) {
                    setState(() => _expandedIndex = null);
                    _loadGastos();
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.2),
                foregroundColor: AppColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.error, width: 1),
                ),
              ),
              child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF05060D),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: const Color(0xFF1A1D3A),
              offset: const Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- WIDGETS NEUMÓRFICOS ----------

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
    // Si está procesando, mostramos un estado de carga circular neumórfico
    if (widget.isProcessing) {
      return SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 28),
            ),
          ],
        ),
      );
    }

    return AnimatedScale(
      scale: widget.isListening ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillos que pulsan hacia afuera (solo cuando escucha)
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
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: opacity),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

            // Botón central con el micrófono
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: widget.isListening
                      ? [const Color(0xFFFFE082), AppColors.accent]
                      : [const Color(0xFFFFD700), AppColors.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: widget.isListening ? 0.6 : 0.4),
                    blurRadius: widget.isListening ? 35 : 25,
                    spreadRadius: widget.isListening ? 4 : 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.black,
                  size: 40
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- WIDGETS NEUMÓRFICOS ----------

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
        boxShadow: [
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
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF05060D),
              offset: Offset(3, 3),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0xFF1A1D3A),
              offset: Offset(-3, -3),
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