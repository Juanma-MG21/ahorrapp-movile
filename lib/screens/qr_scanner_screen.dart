// lib/screens/qr_scanner_screen.dart
//
// Pantalla de escaneo de QR. A propósito NO sabe nada de "Gasto" ni de
// Supabase: su única responsabilidad es mostrar la cámara y, al
// detectar un código, devolver el texto crudo con Navigator.pop().
// Quien la llama (ModuloGastos) decide qué hacer con ese texto — hoy
// lo manda a QrParserService, pero mañana podría usarse para Ingresos
// u otro módulo sin tocar esta pantalla.
//
// Dependencias nuevas en pubspec.yaml:
//   mobile_scanner: ^5.2.3
//   image_picker: ^1.1.2

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../core/design_tokens.dart';

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
    final codigos = resultado?.barcodes ?? [];

    if (codigos.isEmpty || codigos.first.rawValue == null) {
      if (!mounted) return;
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
      backgroundColor: kBgColor,
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
          _NeumorphicIcon(
            icon: Icons.arrow_back,
            size: 20,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESCANEAR QR',
                style: TextStyle(
                  color: kAccentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Escanear QR',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
            color: kTextSecondary,
            fontSize: 13,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Apunta la cámara al código QR del '),
            TextSpan(
              text: 'recibo o comprobante',
              style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' para registrar el gasto automáticamente.'),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0xFF05060D), blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              Container(color: Colors.black.withValues(alpha: 0.05)),
              CustomPaint(painter: _CornerBracketsPainter(color: const Color(0xFF4ADE80))),
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

/// Botón circular grande con etiqueta debajo (Galería / Linterna).
/// Al estar "activo" (linterna encendida) se pinta con el acento
/// dorado, igual al resto de estados activos en la app.
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: activo ? kAccentColor : kSecondaryBgColor,
              shape: BoxShape.circle,
              boxShadow: activo
                  ? [
                BoxShadow(
                  color: kAccentColor.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
                  : const [
                BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8),
                BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8),
              ],
            ),
            child: Icon(
              icono,
              color: activo ? Colors.black87 : kTextPrimary,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          etiqueta,
          style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Copia local del mismo botón circular con sombra neumórfica que ya
/// existe (duplicado) en modulo_gastos.dart y agregar_gasto_screen.dart.
/// Se repite aquí siguiendo la misma convención del proyecto (cada
/// pantalla trae su propia copia privada en vez de importar una
/// compartida). Si más adelante quieres, se puede extraer a un solo
/// widget reutilizable en lib/widgets/.
class _NeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _NeumorphicIcon({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: kBgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0xFF05060D), offset: Offset(3, 3), blurRadius: 8),
            BoxShadow(color: Color(0xFF1A1D3A), offset: Offset(-3, -3), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: kTextSecondary, size: size),
      ),
    );
  }
}

/// Esquinas verdes tipo "marco de escaneo" sobre el preview de cámara.
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

    canvas.drawLine(const Offset(margen, margen + largo), const Offset(margen, margen), paint);
    canvas.drawLine(const Offset(margen, margen), const Offset(margen + largo, margen), paint);

    canvas.drawLine(Offset(size.width - margen - largo, margen), Offset(size.width - margen, margen), paint);
    canvas.drawLine(Offset(size.width - margen, margen), Offset(size.width - margen, margen + largo), paint);

    canvas.drawLine(Offset(margen, size.height - margen - largo), Offset(margen, size.height - margen), paint);
    canvas.drawLine(Offset(margen, size.height - margen), Offset(margen + largo, size.height - margen), paint);

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