import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class PinAccessScreen extends StatefulWidget {
  const PinAccessScreen({super.key});

  @override
  State<PinAccessScreen> createState() => _PinAccessScreenState();
}

class _PinAccessScreenState extends State<PinAccessScreen> {
  String _pin = '';
  final int _pinLength = 4;
  bool _isSettingPin = false;
  String _firstPinEntry = '';
  String _statusMessage = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await AuthService.instance.hasPinSet();
    setState(() {
      _isSettingPin = !hasPin;
      _statusMessage = _isSettingPin ? 'Configura tu nuevo PIN' : 'Ingresa tu código de seguridad';
    });
  }

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += number);
      if (_pin.length == _pinLength) {
        _processPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _processPin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (_isSettingPin) {
      if (_firstPinEntry.isEmpty) {
        setState(() {
          _firstPinEntry = _pin;
          _pin = '';
          _statusMessage = 'Confirma tu nuevo PIN';
        });
      } else {
        if (_pin == _firstPinEntry) {
          await AuthService.instance.savePin(_pin);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN configurado con éxito')));
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          setState(() {
            _pin = '';
            _firstPinEntry = '';
            _statusMessage = 'Los PIN no coinciden. Intenta de nuevo';
          });
        }
      }
    } else {
      final isValid = await AuthService.instance.verifyPin(_pin);
      if (isValid) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Incorrecto'), backgroundColor: AppColors.error));
        setState(() => _pin = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          _buildTopBar(context),
          const SizedBox(height: 40),
          const Text('AhorrApp', style: TextStyle(color: AppColors.accent, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _buildPinIndicators(),
          const SizedBox(height: 60),
          _buildNumpad(),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al Login', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold)),
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
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          style: IconButton.styleFrom(backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
          width: 18, height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.accent : Colors.transparent,
            border: Border.all(color: isFilled ? AppColors.accent : AppColors.textMuted, width: 2),
            boxShadow: isFilled ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)] : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.6, mainAxisSpacing: 16, crossAxisSpacing: 16),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) return const SizedBox.shrink();
        if (index == 10) return _NumberButton(label: '0', onTap: () => _onNumberPressed('0'));
        if (index == 11) return IconButton(onPressed: _onBackspace, icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 24));
        String number = (index + 1).toString();
        return _NumberButton(label: number, onTap: () => _onNumberPressed(number));
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(4, 4), blurRadius: 8)],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
