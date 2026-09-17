import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/cuenta_service.dart';
import 'widgets/seccion_card.dart';

final RegExp _nombreRegex = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s'-]+$");
final RegExp _emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$");

String _limpiarTextoNombre(String valor) =>
    valor.replaceAll(RegExp(r"[^A-Za-zÀ-ÖØ-öø-ÿ\s'-]"), '');

/// Formulario para editar los datos personales (nombre, apellido,
/// correo). Espejo de la sección "Mis datos" de Micuenta.jsx, pero en
/// su propia pantalla para mantener la vista raíz de Cuenta liviana.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({
    super.key,
    required this.nombreActual,
    required this.apellidoActual,
    required this.emailActual,
  });

  final String nombreActual;
  final String apellidoActual;
  final String emailActual;

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nombreCtrl =
      TextEditingController(text: widget.nombreActual);
  late final TextEditingController _apellidoCtrl =
      TextEditingController(text: widget.apellidoActual);
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.emailActual);

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
      setState(() => _error = 'El nombre y el apellido solo pueden contener letras');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() => _guardando = true);
    try {
      final mensaje = await CuentaService.instance.actualizarMiPerfil(
        nombre: nombre,
        apellido: apellido,
        email: email,
      );

      // Actualiza el usuario cacheado para que el resto de la app
      // (avatar, saludo, etc.) refleje el cambio sin recargar sesión.
      final actual = await AuthService.instance.getCurrentUser();
      if (actual != null) {
        final actualizado = Usuario(
          id: actual.id,
          nombre: nombre,
          apellido: apellido,
          email: email,
          roles: actual.roles,
        );
        await AuthService.instance.cacheUsuario(actualizado);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: CuentaColors.success),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error al actualizar tus datos');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _decoracion(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: CuentaColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: CuentaColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CuentaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CuentaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CuentaColors.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuentaColors.background,
      appBar: AppBar(
        backgroundColor: CuentaColors.background,
        elevation: 0,
        title: const Text('Editar mis datos',
            style: TextStyle(color: CuentaColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: CuentaColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: CuentaColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CuentaColors.danger.withValues(alpha: 0.35)),
                ),
                child: Text(_error!, style: const TextStyle(color: CuentaColors.danger, fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: CuentaColors.textPrimary),
              decoration: _decoracion('Nombre'),
              onChanged: (v) {
                final limpio = _limpiarTextoNombre(v);
                if (limpio != v) {
                  _nombreCtrl.value = TextEditingValue(
                    text: limpio,
                    selection: TextSelection.collapsed(offset: limpio.length),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _apellidoCtrl,
              style: const TextStyle(color: CuentaColors.textPrimary),
              decoration: _decoracion('Apellido'),
              onChanged: (v) {
                final limpio = _limpiarTextoNombre(v);
                if (limpio != v) {
                  _apellidoCtrl.value = TextEditingValue(
                    text: limpio,
                    selection: TextSelection.collapsed(offset: limpio.length),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: CuentaColors.textPrimary),
              decoration: _decoracion('Correo electrónico'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CuentaColors.accent,
                  foregroundColor: const Color(0xFF0D1526),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1526)),
                      )
                    : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
