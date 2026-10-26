import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../services/notificaciones_api_service.dart';

class NotificacionesBell extends StatefulWidget {
  const NotificacionesBell({super.key});

  @override
  State<NotificacionesBell> createState() => _NotificacionesBellState();
}

class _NotificacionesBellState extends State<NotificacionesBell> {
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarConteo();
  }

  Future<void> _cargarConteo() async {
    final count = await NotificacionesApiService.obtenerNoLeidasCount();
    if (!mounted) return;
    setState(() => _noLeidas = count);
  }

  Future<void> _abrir() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
    );
    // Al volver, el usuario pudo leer o archivar: se actualiza el número.
    _cargarConteo();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _abrir,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                BoxShadow(
                  color: Color(0xFF1A1D3A),
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (_noLeidas > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  _noLeidas > 99 ? '99+' : '$_noLeidas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}