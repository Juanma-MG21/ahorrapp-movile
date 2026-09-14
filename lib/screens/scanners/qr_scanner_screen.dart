import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/scanner/scanner_shared_ui.dart';
import'../../core/theme/design_tokens.dart';


class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _linternaEncendida = false;
  bool _yaDevolvioResultado = false; // evita hacer pop() dos veces

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture captura) {
    if (_yaDevolvioResultado) return;
    final codigos = captura.barcodes;
    if (codigos.isEmpty) return;

    final valor = codigos.first.rawValue;
    if (valor == null || valor.trim().isEmpty) return;

    _yaDevolvioResultado = true;
    Navigator.of(context).pop(valor);
  }

  Future<void> _alternarLinterna() async {
    await _controller.toggleTorch();
    if (mounted) setState(() => _linternaEncendida = !_linternaEncendida);
  }

  Future<void> _elegirDeGaleria() async {
    final picker = ImagePicker();
    final XFile? archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo == null) return;

    final BarcodeCapture? resultado = await _controller.analyzeImage(archivo.path);
    if (!mounted) return;

    final codigos = resultado?.barcodes ?? [];

    if (codigos.isEmpty || codigos.first.rawValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un código QR en esa imagen')),
      );
      return;
    }

    if (_yaDevolvioResultado) return;
    _yaDevolvioResultado = true;
    Navigator.of(context).pop(codigos.first.rawValue!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScannerHeader(
              label: 'ESCANEAR QR',
              title: 'Escanear QR',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScannerCornerFrame(
                child: MobileScanner(controller: _controller, onDetect: _onDetect),
              ),
            ),
            const SizedBox(height: 20),
            const ScannerInstructionText(
              antes: 'Apunta la cámara al código QR del ',
              resaltado: 'recibo o comprobante',
              despues: ' para registrar el gasto automáticamente.',
            ),
            const SizedBox(height: 24),
            _buildBotonesInferiores(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesInferiores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScannerRoundAction(
          icono: Icons.photo_library_outlined,
          etiqueta: 'Galería',
          onTap: _elegirDeGaleria,
        ),
        const SizedBox(width: 28),
        ScannerRoundAction(
          icono: _linternaEncendida ? Icons.flash_on : Icons.flash_off,
          etiqueta: 'Linterna',
          activo: _linternaEncendida,
          onTap: _alternarLinterna,
        ),
      ],
    );
  }
}