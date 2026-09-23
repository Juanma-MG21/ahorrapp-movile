import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

import '../../core/network/api_client.dart';
import '../../models/usuario_admin.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../cuenta/widgets/seccion_card.dart';

final RegExp _nombreRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s'-]+$");
final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$");

/// Panel de usuarios — equivalente móvil de PanelUsuarios.jsx.
/// Solo admin/superuser llegan aquí (el acceso ya se filtró desde
/// "Mi cuenta" -> "Panel de administración"). Un superuser además
/// puede cambiar el rol de cada usuario; un admin solo edita datos.
class PanelUsuariosScreen extends StatefulWidget {
  const PanelUsuariosScreen({super.key});

  @override
  State<PanelUsuariosScreen> createState() => _PanelUsuariosScreenState();
}

class _PanelUsuariosScreenState extends State<PanelUsuariosScreen> {
  List<UsuarioAdmin> _usuarios = [];
  bool _cargando = true;
  String? _error;
  bool _esSuperusuario = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuarioActual = await AuthService.instance.getCurrentUser();
      final roles = usuarioActual?.roles;
      _esSuperusuario = roles is List && roles.map((r) => '$r'.toLowerCase()).contains('superuser');

      final usuarios = await AdminService.instance.getUsuarios();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al obtener usuarios';
        _cargando = false;
      });
    }
  }

  Future<void> _editarUsuario(UsuarioAdmin usuario) async {
    final actualizado = await showModalBottomSheet<UsuarioAdmin>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarUsuarioSheet(usuario: usuario, esSuperusuario: _esSuperusuario),
    );

    if (actualizado != null) {
      setState(() {
        _usuarios = _usuarios.map((u) => u.id == actualizado.id ? actualizado : u).toList();
      });
    }
  }

  Future<void> _confirmarEliminar(UsuarioAdmin usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar usuario', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Seguro deseas eliminar a ${usuario.nombre} ${usuario.apellido}?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await AdminService.instance.eliminarUsuario(usuario.id);
      if (!mounted) return;
      setState(() => _usuarios = _usuarios.where((u) => u.id != usuario.id).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar al usuario'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Usuarios registrados',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: _cargar,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text('${_usuarios.length} cuentas activas',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    if (_usuarios.isEmpty && _error == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('No hay usuarios registrados.', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    for (final usuario in _usuarios) ...[
                      _UsuarioCard(
                        usuario: usuario,
                        onEditar: () => _editarUsuario(usuario),
                        onEliminar: () => _confirmarEliminar(usuario),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  const _UsuarioCard({required this.usuario, required this.onEditar, required this.onEliminar});

  final UsuarioAdmin usuario;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(usuario.iniciales,
                      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${usuario.nombre} ${usuario.apellido}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    Text('ID ${usuario.id} · ${usuario.cargo ?? 'sin rol'}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderLight),
          Row(
            children: [
              const Icon(Icons.mail_outline, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(usuario.email,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.textSecondary),
                  label: const Text('Editar', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                  label: const Text('Borrar', style: TextStyle(color: AppColors.error, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet de edición: nombre, apellido, email y (solo superuser)
/// selector de rol. Se resuelve con el UsuarioAdmin actualizado o null
/// si se canceló.
class _EditarUsuarioSheet extends StatefulWidget {
  const _EditarUsuarioSheet({required this.usuario, required this.esSuperusuario});

  final UsuarioAdmin usuario;
  final bool esSuperusuario;

  @override
  State<_EditarUsuarioSheet> createState() => _EditarUsuarioSheetState();
}

class _EditarUsuarioSheetState extends State<_EditarUsuarioSheet> {
  late final _nombreCtrl = TextEditingController(text: widget.usuario.nombre);
  late final _apellidoCtrl = TextEditingController(text: widget.usuario.apellido);
  late final _emailCtrl = TextEditingController(text: widget.usuario.email);
  late int? _rolId = widget.usuario.idRol;

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (nombre.isEmpty || apellido.isEmpty || email.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (!_nombreRegex.hasMatch(nombre) || !_nombreRegex.hasMatch(apellido)) {
      setState(() => _error = 'El nombre y apellido solo pueden contener letras');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() => _guardando = true);
    try {
      await AdminService.instance.actualizarUsuario(
        id: widget.usuario.id,
        nombre: nombre,
        apellido: apellido,
        email: email,
      );

      // Solo un superuser puede tocar el rol, y solo si realmente cambió.
      if (widget.esSuperusuario && _rolId != null && _rolId != widget.usuario.idRol) {
        await AdminService.instance.actualizarRolUsuario(id: widget.usuario.id, idRol: _rolId!);
      }

      if (!mounted) return;
      final nuevoCargo = widget.esSuperusuario && _rolId != null
          ? kRolesDisponibles.firstWhere((r) => r.id == _rolId, orElse: () => kRolesDisponibles.first).nombre
          : widget.usuario.cargo;

      Navigator.of(context).pop(widget.usuario.copyWith(
        nombre: nombre,
        apellido: apellido,
        email: email,
        idRol: _rolId,
        cargo: nuevoCargo,
      ));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al actualizar el usuario');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Editar usuario',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 14),
              ],
              TextField(controller: _nombreCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: _decoracion('Nombre')),
              const SizedBox(height: 12),
              TextField(controller: _apellidoCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: _decoracion('Apellido')),
              const SizedBox(height: 12),
              TextField(controller: _emailCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: _decoracion('Correo electrónico')),
              if (widget.esSuperusuario) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _rolId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: _decoracion('Rol'),
                  items: kRolesDisponibles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre))).toList(),
                  onChanged: (v) => setState(() => _rolId = v),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _guardando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
