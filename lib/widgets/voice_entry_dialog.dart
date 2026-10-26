import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/theme/design_tokens.dart';

/// Solo recoge texto. Ningún resultado de voz crea movimientos automáticamente.
class VoiceEntryDialog extends StatefulWidget {
  const VoiceEntryDialog(
      {super.key,
      required this.speech,
      required this.income,
      this.requestPermission});
  final stt.SpeechToText speech;
  final bool income;
  final Future<PermissionStatus> Function()? requestPermission;
  @override
  State<VoiceEntryDialog> createState() => _VoiceEntryDialogState();
}

class _VoiceEntryDialogState extends State<VoiceEntryDialog>
    with WidgetsBindingObserver {
  bool _starting = true;
  bool _listening = false;
  bool _processing = false;
  bool _closed = false;
  bool _foreground = true;
  String _words = '';
  String? _error;
  final _finalResult = Completer<void>();
  bool get _current => mounted && !_closed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    try {
      final permission = await (widget.requestPermission?.call() ??
          Permission.microphone.request());
      if (!_current) return;
      if (!permission.isGranted) {
        setState(() {
          _starting = false;
          _error = permission.isPermanentlyDenied
              ? 'Activa el permiso del micrófono en los ajustes del teléfono.'
              : 'Necesitamos el permiso del micrófono para dictar.';
        });
        return;
      }
      final available = await widget.speech.initialize(onStatus: (status) {
        if (_current &&
            !_processing &&
            (status == 'done' || status == 'notListening')) {
          setState(() => _listening = false);
        }
      }, onError: (_) {
        if (!_finalResult.isCompleted) _finalResult.complete();
        if (_current) {
          setState(() {
            _starting = false;
            _listening = false;
            _error =
                'No se pudo reconocer la voz. Revisa el texto o registra manualmente.';
          });
        }
      });
      if (!_current) return;
      if (!available) {
        setState(() {
          _starting = false;
          _error =
              'El reconocimiento de voz no está disponible en este teléfono.';
        });
        return;
      }
      final locales = await widget.speech.locales();
      if (!_current) return;
      final spanish = locales.where((l) =>
          l.localeId.toLowerCase().replaceAll('-', '_').startsWith('es'));
      if (spanish.isEmpty) {
        setState(() {
          _starting = false;
          _error =
              'Instala un idioma de reconocimiento en español o registra manualmente.';
        });
        return;
      }
      final locale = spanish.firstWhere(
          (l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'es_co',
          orElse: () => spanish.first);
      if (!_foreground) {
        _cancel();
        return;
      }
      setState(() {
        _starting = false;
        _listening = true;
      });
      // Se inicia una sola vez, fuera de build. No se reinicia al terminar.
      await widget.speech.listen(
          onResult: (result) {
            if (_current) setState(() => _words = result.recognizedWords);
            if (result.finalResult && !_finalResult.isCompleted) {
              _finalResult.complete();
            }
          },
          listenOptions: stt.SpeechListenOptions(
              localeId: locale.localeId,
              cancelOnError: true,
              listenMode: stt.ListenMode.dictation,
              listenFor: const Duration(seconds: 60),
              pauseFor: const Duration(seconds: 5)));
      if (!_current) await widget.speech.cancel();
    } catch (_) {
      if (_current) {
        setState(() {
          _starting = false;
          _listening = false;
          _error =
              'No se pudo iniciar el dictado. Puedes registrar manualmente.';
        });
      }
    }
  }

  Future<void> _review() async {
    if (_processing || _closed) return;
    setState(() {
      _processing = true;
      _listening = false;
    });
    try {
      await widget.speech.stop();
      // stop puede responder antes de entregar la transcripción final.
      await _finalResult.future
          .timeout(const Duration(seconds: 2), onTimeout: () {});
      if (!mounted || _closed) return;
      if (_words.trim().isEmpty) {
        setState(() {
          _processing = false;
          _error = 'No se reconoció texto. Cancela y vuelve a intentarlo.';
        });
        return;
      }
      _closed = true;
      Navigator.of(context).pop(_words.trim());
    } catch (_) {
      if (_current) {
        setState(() {
          _processing = false;
          _error = 'No se pudo detener el dictado. Intenta de nuevo o cancela.';
        });
      }
    }
  }

  void _cancel() {
    if (_closed) return;
    _closed = true;
    if (!_finalResult.isCompleted) _finalResult.complete();
    unawaited(_cancelSpeech());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _cancelSpeech() async {
    try {
      await widget.speech.cancel();
    } catch (_) {/* La ruta ya no acepta resultados. */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if ((_listening || _processing) && !_foreground) _cancel();
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (!_finalResult.isCompleted) _finalResult.complete();
    unawaited(_cancelSpeech());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _closed = true;
            if (!_finalResult.isCompleted) _finalResult.complete();
            unawaited(_cancelSpeech());
          }
        },
        child: Dialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_listening ? Icons.mic : Icons.mic_none,
                      size: 48, color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                      _starting
                          ? 'Preparando micrófono…'
                          : _listening
                              ? 'Escuchando…'
                              : 'Revisa el dictado',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                      _words.isNotEmpty
                          ? _words
                          : widget.income
                              ? 'Di algo como: «Recibí un millón de pesos de salario»'
                              : 'Di algo como: «Gasté diez mil pesos en taxi»',
                      textAlign: TextAlign.center),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error))),
                  const SizedBox(height: 20),
                  FilledButton(
                      onPressed: _starting || _processing ? null : _review,
                      child: Text(_processing
                          ? 'Preparando formulario…'
                          : 'Revisar formulario')),
                  TextButton(onPressed: _cancel, child: const Text('Cancelar')),
                ]))),
      );
}
