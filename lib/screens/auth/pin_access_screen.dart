import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Modo en el que se abre [PinAccessScreen]:
///  - [manage]: se usa desde la pantalla de Inicio para registrar un PIN
///    nuevo o editar (cambiar) el que ya existe. Siempre resuelve con
///    Navigator.pop(true) al terminar con éxito, o pop(false) si el
///    usuario cancela.
///  - [confirm]: segunda verificación para una acción sensible ya en
///    curso (cambiar contraseña, editar datos personales, etc.) sobre
///    una sesión ya autenticada. Si el usuario no tiene PIN configurado
///    todavía, lo configura ahí mismo como parte del flujo. Ofrece
///    "Usar huella en su lugar" cuando el usuario ya activó la
///    biometría, para no obligarlo a teclear el PIN.
enum PinAccessMode { manage, confirm }

/// Helper para pantallas fuera de auth/ (ej. Mi Cuenta) que necesitan
/// confirmar un cambio sensible (contraseña, correo, datos personales)
/// con el PIN antes de ejecutar la acción. La propia pantalla ofrece
/// "Usar huella en su lugar" si el usuario ya la activó. Devuelve
/// true solo si el usuario confirmó correctamente.
Future<bool> confirmarConPin(BuildContext context) async {
  final confirmado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const PinAccessScreen(mode: PinAccessMode.confirm),
    ),
  );
  return confirmado == true;
}

/// Pantalla de PIN. Se usa con push + await:
///
///   final ok = await Navigator.of(context).push<bool>(
///     MaterialPageRoute(
///       builder: (_) => const PinAccessScreen(mode: PinAccessMode.confirm),
///     ),
///   );
///   if (ok == true) { ...continuar con la acción sensible... }
///
/// No navega a '/home': siempre resuelve con Navigator.pop(true/false).
class PinAccessScreen extends StatefulWidget {
  const PinAccessScreen({super.key, this.mode = PinAccessMode.confirm});

  final PinAccessMode mode;

  @override
  State<PinAccessScreen> createState() => _PinAccessScreenState();
}

enum _Paso {
  cargando,
  verificarActual, // modo manage con PIN ya existente: pide el PIN actual antes de dejar editarlo
  definirNuevo, // primera captura de un PIN nuevo (setup o edición)
  confirmarNuevo, // segunda captura, debe coincidir con la primera
  confirmarAccion, // modo confirm con PIN ya existente: solo valida
}

class _PinAccessScreenState extends State<PinAccessScreen> {
  String _pin = '';
  final int _pinLength = 4;
  String _primeraCaptura = '';
  _Paso _paso = _Paso.cargando;
  String _statusMessage = 'Cargando...';
  bool _biometriaDisponible = false;

  bool get _esGestion => widget.mode == PinAccessMode.manage;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    if (!await AuthService.instance.hasSession()) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Inicia sesión con tu correo y contraseña';
      });
      return;
    }

    final hasPin = await AuthService.instance.hasPinSet();
    final biometria = await AuthService.instance.isBiometricEnabled();

    if (!mounted) return;

    setState(() {
      _biometriaDisponible = biometria && !_esGestion;
      if (!hasPin) {
        _paso = _Paso.definirNuevo;
        _statusMessage = _esGestion
            ? 'Crea un PIN de 4 dígitos'
            : 'Configura un PIN para confirmar acciones sensibles';
      } else if (_esGestion) {
        _paso = _Paso.verificarActual;
        _statusMessage = 'Ingresa tu PIN actual para editarlo';
      } else {
        _paso = _Paso.confirmarAccion;
        _statusMessage = 'Confirma la acción con tu PIN';
      }
    });
  }

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += number);
      if (_pin.length == _pinLength) {
        _procesarPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _procesarPin() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // Chequeo defensivo: la sesión pudo expirar mientras el usuario
    // tecleaba el PIN.
    if (!await AuthService.instance.hasSession()) {
      setState(() {
        _pin = '';
        _statusMessage = 'Tu sesión ya no está disponible';
      });
      return;
    }

    switch (_paso) {
      case _Paso.verificarActual:
        final valido = await AuthService.instance.verifyPin(_pin);
        if (!mounted) return;
        if (valido) {
          setState(() {
            _pin = '';
            _paso = _Paso.definirNuevo;
            _statusMessage = 'Ingresa tu nuevo PIN';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN incorrecto'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _pin = '');
        }
        break;

      case _Paso.definirNuevo:
        setState(() {
          _primeraCaptura = _pin;
          _pin = '';
          _paso = _Paso.confirmarNuevo;
          _statusMessage = 'Confirma tu nuevo PIN';
        });
        break;

      case _Paso.confirmarNuevo:
        if (_pin == _primeraCaptura) {
          await AuthService.instance.savePin(_pin);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN guardado correctamente')),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _pin = '';
            _primeraCaptura = '';
            _paso = _Paso.definirNuevo;
            _statusMessage = 'Los PIN no coinciden. Intenta de nuevo';
          });
        }
        break;

      case _Paso.confirmarAccion:
        final valido = await AuthService.instance.verifyPin(_pin);
        if (!mounted) return;
        if (valido) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN Incorrecto'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _pin = '');
        }
        break;

      case _Paso.cargando:
        break;
    }
  }

  Future<void> _usarHuella() async {
    final ok = await AuthService.instance.authenticateBiometric();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo confirmar con biometría'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          _buildTopBar(context),
          const SizedBox(height: 40),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 50),
          _buildPinIndicators(),
          const SizedBox(height: 60),
          _buildNumpad(),
          if (_biometriaDisponible) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _usarHuella,
              icon: const Icon(Icons.fingerprint_rounded, color: AppColors.accent),
              label: const Text(
                'Usar huella en su lugar',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        bool isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.accent : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.accent : AppColors.textMuted,
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) return const SizedBox.shrink();
        if (index == 10) {
          return _NumberButton(label: '0', onTap: () => _onNumberPressed('0'));
        }
        if (index == 11) {
          return IconButton(
            onPressed: _onBackspace,
            icon: const Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 24,
            ),
          );
        }
        String number = (index + 1).toString();
        return _NumberButton(
          label: number,
          onTap: () => _onNumberPressed(number),
        );
      },
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumberButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(4, 4),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
