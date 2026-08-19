import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import 'agregar_ingreso_screen.dart';

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
  bool _yaNavego = false; // evita abrir el formulario dos veces

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Se llama cada vez que la cámara detecta algo parecido a un QR.
  void _onDetect(BarcodeCapture captura) {
    if (_yaNavego) return;
    final codigos = captura.barcodes;
    if (codigos.isEmpty) return;

    final valor = codigos.first.rawValue;
    if (valor == null || valor.trim().isEmpty) return;

    _yaNavego = true;
    _irAlFormulario(valor);
  }

  Future<void> _alternarLinterna() async {
    await _controller.toggleTorch();
    setState(() => _linternaEncendida = !_linternaEncendida);
  }

  Future<void> _elegirDeGaleria() async {
    final picker = ImagePicker();
    final XFile? archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo == null) return;

    // mobile_scanner puede analizar una imagen ya tomada/elegida
    final BarcodeCapture? resultado = await _controller.analyzeImage(archivo.path);
    final codigos = resultado?.barcodes ?? [];

    if (codigos.isEmpty || codigos.first.rawValue == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un código QR en esa imagen')),
      );
      return;
    }

    if (_yaNavego) return;
    _yaNavego = true;
    _irAlFormulario(codigos.first.rawValue!);
  }

  void _irAlFormulario(String textoQr) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AgregarIngresoScreen(textoDetectadoQr: textoQr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(child: _buildMarcoEscaneo()),
            const SizedBox(height: 20),
            _buildTextoInstructivo(),
            const SizedBox(height: 24),
            _buildBotonesInferiores(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _IconCircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESCANEAR QR',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Escanear QR',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextoInstructivo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Apunta la cámara al código QR del '),
            TextSpan(
              text: 'recibo o comprobante',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' para registrar el ingreso automáticamente.'),
          ],
        ),
      ),
    );
  }

  Widget _buildMarcoEscaneo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vista de la cámara en vivo
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
              // Oscurecemos un poco para que resalten las esquinas verdes
              Container(color: Colors.black.withOpacity(0.05)),
              // Esquinas tipo "corner brackets"
              CustomPaint(
                painter: _CornerBracketsPainter(color: AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonesInferiores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AccionRedonda(
          icono: Icons.photo_library_outlined,
          etiqueta: 'Galería',
          onTap: _elegirDeGaleria,
        ),
        const SizedBox(width: 28),
        _AccionRedonda(
          icono: _linternaEncendida ? Icons.flash_on : Icons.flash_off,
          etiqueta: 'Linterna',
          activo: _linternaEncendida,
          onTap: _alternarLinterna,
        ),
      ],
    );
  }
}

/// Botón circular pequeño para el header (flecha atrás).
class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: clayRaised(radius: AppRadius.pill),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

/// Botón circular grande para Galería/Linterna.

class _AccionRedonda extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  const _AccionRedonda({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: activo
                ? clayGlow(color: AppColors.accent)
                : clayRaised(radius: AppRadius.pill, color: AppColors.surfaceAlt),
            child: Icon(
              icono,
              color: activo ? Colors.black87 : AppColors.textPrimary,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          etiqueta,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Dibuja las 4 esquinas verdes tipo "marco de escaneo" sobre el preview
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  const _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double margen = 24;
    const double largo = 32;

    // Esquina superior-izquierda
    canvas.drawLine(const Offset(margen, margen + largo), const Offset(margen, margen), paint);
    canvas.drawLine(const Offset(margen, margen), const Offset(margen + largo, margen), paint);

    // Esquina superior-derecha
    canvas.drawLine(Offset(size.width - margen - largo, margen), Offset(size.width - margen, margen), paint);
    canvas.drawLine(Offset(size.width - margen, margen), Offset(size.width - margen, margen + largo), paint);

    // Esquina inferior-izquierda
    canvas.drawLine(Offset(margen, size.height - margen - largo), Offset(margen, size.height - margen), paint);
    canvas.drawLine(Offset(margen, size.height - margen), Offset(margen + largo, size.height - margen), paint);

    // Esquina inferior-derecha
    canvas.drawLine(
      Offset(size.width - margen - largo, size.height - margen),
      Offset(size.width - margen, size.height - margen),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margen, size.height - margen - largo),
      Offset(size.width - margen, size.height - margen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => false;
}