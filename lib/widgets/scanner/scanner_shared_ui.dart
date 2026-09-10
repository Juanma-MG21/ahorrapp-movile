// UI compartida entre QrScannerScreen y OcrScannerScreen. Ambas pantallas
// muestran: un header con back + título, un marco con esquinas verdes
// (con cámara en vivo o una foto capturada adentro), texto instructivo,
// y botones circulares de acción abajo. Vivía duplicado en cada archivo;
// se extrae acá para que quede en un solo lugar y las dos pantallas
// queden compactas.

import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Colores y sombras propias del módulo de escaneo (no genéricos de
/// AppColors, porque el verde de las esquinas y la sombra del marco son
/// específicos de esta UI).
class ScannerColors {
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color frameShadow = Color(0xFF05060D);
  static const Color iconShadowDark = Color(0xFF05060D);
  static const Color iconShadowLight = Color(0xFF1A1D3A);
}

/// Header con botón de volver + label superior (ej. "ESCANEAR QR") +
/// título (ej. "Escanear QR").
class ScannerHeader extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback onBack;

  const ScannerHeader({
    super.key,
    required this.label,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ScannerNeumorphicIcon(icon: Icons.arrow_back, size: 20, onTap: onBack),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
}

/// Texto instructivo centrado con una frase destacada en negrita en
/// medio (ej. "... del **recibo o comprobante** para registrar ...").
class ScannerInstructionText extends StatelessWidget {
  final String antes;
  final String resaltado;
  final String despues;

  const ScannerInstructionText({
    super.key,
    required this.antes,
    required this.resaltado,
    required this.despues,
  });

  @override
  Widget build(BuildContext context) {
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
            TextSpan(text: antes),
            TextSpan(
              text: resaltado,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: despues),
          ],
        ),
      ),
    );
  }
}

/// Marco cuadrado con esquinas verdes tipo "encuadre de escaneo",
/// envolviendo lo que se le pase como [child] (la cámara en vivo del
/// QR, o la miniatura de una foto capturada + overlay de carga en OCR).
class ScannerCornerFrame extends StatelessWidget {
  final Widget child;
  final Color cornerColor;

  const ScannerCornerFrame({
    super.key,
    required this.child,
    this.cornerColor = ScannerColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: ScannerColors.frameShadow, blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Container(color: Colors.black.withValues(alpha: 0.05)),
              CustomPaint(painter: _CornerBracketsPainter(color: cornerColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón circular grande con etiqueta debajo (ej. "Galería", "Tomar foto",
/// "Linterna"). Al estar [activo] se pinta con el acento dorado.
class ScannerRoundAction extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback? onTap;

  const ScannerRoundAction({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    final deshabilitado = onTap == null;
    return Opacity(
      opacity: deshabilitado ? 0.4 : 1.0,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: activo ? AppColors.accent : AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: activo
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [
                        BoxShadow(color: ScannerColors.iconShadowDark, offset: Offset(3, 3), blurRadius: 8),
                        BoxShadow(color: ScannerColors.iconShadowLight, offset: Offset(-3, -3), blurRadius: 8),
                      ],
              ),
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Botón circular pequeño neumórfico, usado en el header para "volver".
class ScannerNeumorphicIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const ScannerNeumorphicIcon({super.key, required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: ScannerColors.iconShadowDark, offset: Offset(3, 3), blurRadius: 8),
            BoxShadow(color: ScannerColors.iconShadowLight, offset: Offset(-3, -3), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: size),
      ),
    );
  }
}

/// Esquinas verdes tipo "marco de escaneo" pintadas sobre el contenido
/// de un ScannerCornerFrame.
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
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) => oldDelegate.color != color;
}