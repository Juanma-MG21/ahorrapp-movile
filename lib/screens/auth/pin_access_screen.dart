import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'auth_gate.dart';

class PinAccessScreen extends StatefulWidget {
  const PinAccessScreen({super.key});

  @override
  State<PinAccessScreen> createState() => _PinAccessScreenState();
}

class _PinAccessScreenState extends State<PinAccessScreen> {
  String _pin = '';
  final int _pinLength = 4;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    // Simulación de verificación
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_pin == '1234') { // PIN de prueba
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Correcto. Bienvenido!')),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Incorrecto. Intenta de nuevo.')),
      );
      setState(() {
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF12213C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'AhorrApp',
            style: TextStyle(
              color: AppTheme.amber,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ingresa tu PIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Usa tu código de seguridad para entrar',
            style: TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 50),
          
          // Indicadores de PIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              bool isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppTheme.amber : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? AppTheme.amber : const Color(0xFF334057),
                    width: 2,
                  ),
                  boxShadow: isFilled ? [
                    BoxShadow(
                      color: AppTheme.amber.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 60),
          
          // Teclado Numérico
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index == 9) return const SizedBox.shrink();
              
              if (index == 10) {
                return _NumberButton(
                  label: '0',
                  onTap: () => _onNumberPressed('0'),
                );
              }
              
              if (index == 11) {
                return IconButton(
                  onPressed: _onBackspace,
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                );
              }
              
              String number = (index + 1).toString();
              return _NumberButton(
                label: number,
                onTap: () => _onNumberPressed(number),
              );
            },
          ),
          
          const SizedBox(height: 40),

          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
            ),
            child: const Text(
              'Ingresar con contraseña',
              style: TextStyle(
                color: AppTheme.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151222),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2A2640)),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
