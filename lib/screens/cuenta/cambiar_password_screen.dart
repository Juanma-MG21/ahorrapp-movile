import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

import '../../core/network/api_client.dart';
import '../../services/cuenta_service.dart';
import '../auth/pin_access_screen.dart';
import 'widgets/seccion_card.dart';

/// Formulario de cambio de contraseña, en su propia pantalla (igual
/// criterio que EditarPerfilScreen: mantener "Mi cuenta" como un
/// listado de accesos cortos, no un formulario largo).
class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    final actual = _actualCtrl.text;
    final nueva = _nuevaCtrl.text;
    final confirmar = _confirmarCtrl.text;

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (nueva.length < 8) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (nueva != confirmar) {
      setState(() => _error = 'Las contraseñas nuevas no coinciden');
      return;
    }

    // Confirmación con PIN (o huella, si el usuario ya la activó) antes
    // de aplicar el cambio, igual que el resto de acciones sensibles de
    // la cuenta.
    final confirmado = await confirmarConPin(context);
    if (!mounted || !confirmado) return;

    setState(() => _guardando = true);
    try {
      final mensaje = await CuentaService.instance.cambiarMiPassword(
        passwordActual: actual,
        passwordNueva: nueva,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.success),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al cambiar la contraseña');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Cambiar contraseña',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Debes confirmar tu contraseña actual para poder cambiarla.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _actualCtrl,
              obscureText: !_verActual,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _decoracion(
                'Contraseña actual',
                suffix: IconButton(
                  icon: Icon(_verActual ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted, size: 19),
                  onPressed: () => setState(() => _verActual = !_verActual),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nuevaCtrl,
              obscureText: !_verNueva,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _decoracion(
                'Nueva contraseña',
                suffix: IconButton(
                  icon: Icon(_verNueva ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted, size: 19),
                  onPressed: () => setState(() => _verNueva = !_verNueva),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmarCtrl,
              obscureText: !_verNueva,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _decoracion('Confirmar nueva contraseña'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                      )
                    : const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }
}
