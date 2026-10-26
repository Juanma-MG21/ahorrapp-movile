import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/notificacion_model.dart';
import '../../services/notificaciones_api_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lista = await NotificacionesApiService.obtenerNotificaciones();
      if (!mounted) return;
      setState(() {
        _notificaciones = lista;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las notificaciones';
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarLeida(NotificacionModel n) async {
    if (n.leida) return;
    final ok = await NotificacionesApiService.marcarLeida(n.id);
    if (!ok || !mounted) return;
    setState(() {
      _notificaciones = _notificaciones
          .map((x) => x.id == n.id ? x.copyWith(leida: true) : x)
          .toList();
    });
  }

  Future<void> _marcarTodas() async {
    final ok = await NotificacionesApiService.marcarTodasLeidas();
    if (!ok || !mounted) return;
    setState(() {
      _notificaciones =
          _notificaciones.map((x) => x.copyWith(leida: true)).toList();
    });
  }

  void _archivar(NotificacionModel n) {
    setState(() => _notificaciones.removeWhere((x) => x.id == n.id));
    NotificacionesApiService.archivar(n.id).then((ok) {
      if (!ok) _cargar();
    });
  }

  String _formatFecha(DateTime f) {
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final min = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year}  $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    final hayNoLeidas = _notificaciones.any((n) => !n.leida);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hayNoLeidas)
            TextButton(
              onPressed: _marcarTodas,
              child: const Text(
                'Marcar todas',
                style: TextStyle(color: Color(0xFF4ADE80), fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: const Color(0xFF4ADE80),
      child: _buildLista(),
    );
  }

  Widget _buildLista() {
    if (_error != null) {
      return _mensajeCentrado(Icons.error_outline_rounded, _error!);
    }

    if (_notificaciones.isEmpty) {
      return _mensajeCentrado(
        Icons.notifications_none_rounded,
        'No tienes notificaciones',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: _notificaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildItem(_notificaciones[index]),
    );
  }

  Widget _mensajeCentrado(IconData icono, String texto) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icono, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 64),
        const SizedBox(height: 16),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildItem(NotificacionModel n) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _archivar(n),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.archive_outlined, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: () => _marcarLeida(n),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.leida
                  ? Colors.transparent
                  : n.color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: n.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(n.icono, color: n.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.mensaje,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: n.leida ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatFecha(n.fecha),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.leida)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: n.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}