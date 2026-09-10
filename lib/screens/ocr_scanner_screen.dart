// lib/screens/ocr_scanner_screen.dart
//
// Pantalla de escaneo de recibos por OCR (RF-23). A diferencia de
// QrScannerScreen, no hay una cámara en vivo dentro de la app: se usa
// image_picker para lanzar la cámara nativa, y una vez capturada la
// foto se corre reconocimiento de texto (google_mlkit_text_recognition)
// sobre ella. Igual que QrScannerScreen, esta pantalla NO sabe nada de
// "Gasto": solo devuelve el texto crudo reconocido con Navigator.pop().
// Quien la llama decide qué hacer con ese texto (hoy: OcrParserService).
//
// Dependencias nuevas en pubspec.yaml:
//   google_mlkit_text_recognition: ^0.13.0  (o la última estable)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/theme/design_tokens.dart';
import '../widgets/scanner/scanner_shared_ui.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  String? _fotoPath;
  bool _procesando = false;
  bool _yaDevolvioResultado = false; // evita hacer pop() dos veces

  @override
  void initState() {
    super.initState();
    // Al entrar a la pantalla, se lanza la cámara de una vez — el
    // usuario vino desde el menú explícitamente a "Escanear Recibo",
    // así que no tiene sentido hacerlo tocar un botón extra primero.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tomarFoto());
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    if (_procesando) return;
    final XFile? archivo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (archivo == null) return; // el usuario canceló la cámara
    await _procesarImagen(archivo.path);
  }

  Future<void> _elegirDeGaleria() async {
    if (_procesando) return;
    final XFile? archivo = await _picker.pickImage(source: ImageSource.gallery);
    if (archivo == null) return;
    await _procesarImagen(archivo.path);
  }

  Future<void> _procesarImagen(String path) async {
    setState(() {
      _fotoPath = path;
      _procesando = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText resultado = await _recognizer.processImage(inputImage);
      final texto = resultado.text.trim();

      if (!mounted) return;

      if (texto.isEmpty) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se detectó texto en la foto. Intenta de nuevo con mejor luz.')),
        );
        return;
      }

      if (_yaDevolvioResultado) return;
      _yaDevolvioResultado = true;
      Navigator.of(context).pop(texto);
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo procesar la imagen. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScannerHeader(
              label: 'ESCANEAR RECIBO',
              title: 'Escanear Recibo',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScannerCornerFrame(child: _buildPreview()),
            ),
            const SizedBox(height: 20),
            const ScannerInstructionText(
              antes: 'Toma una foto clara del ',
              resaltado: 'recibo o factura',
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

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_fotoPath != null)
          Image.file(File(_fotoPath!), fit: BoxFit.cover)
        else
          Container(
            color: AppColors.surface,
            child: const Center(
              child: Icon(Icons.receipt_long, color: AppColors.textSecondary, size: 64),
            ),
          ),
        if (_procesando)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
      ],
    );
  }

  Widget _buildBotonesInferiores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScannerRoundAction(
          icono: Icons.photo_library_outlined,
          etiqueta: 'Galería',
          onTap: _procesando ? null : _elegirDeGaleria,
        ),
        const SizedBox(width: 28),
        ScannerRoundAction(
          icono: Icons.photo_camera,
          etiqueta: 'Tomar foto',
          onTap: _procesando ? null : _tomarFoto,
        ),
      ],
    );
  }
}