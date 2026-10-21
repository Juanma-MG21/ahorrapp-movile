import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:ahorrapp_movil/services/local_parser_service.dart';
import 'package:ahorrapp_movil/widgets/voice_entry_dialog.dart';

class _Speech extends Mock implements stt.SpeechToText {}

void main() {
  final examples = <String, double>{
    'Gasté diez mil pesos en taxi': 10000,
    'Recibí un millón quinientos mil pesos de salario': 1500000,
    'Gasté 45.000,50 pesos en comida': 45000.5,
    'Gasté 45,000.50 pesos en comida': 45000.5,
    'Gasté 500,50 pesos': 500.5,
    'Gasté 500.50 pesos': 500.5,
    'Compré dos cafés por diez mil pesos': 10000,
    'Gasté diez mil en un taxi': 10000,
    'Recibí 2,5 millones de salario': 2500000,
    'Gasté veintiún mil pesos': 21000,
    'Gasté 500 pesos el 05/10/2026': 500,
    'Compré una pizza': 0,
    'Gasté -500 pesos': 0,
    'Gasté 500 pesos y 800 pesos': 0,
  };
  for (final entry in examples.entries) {
    test('monto: ${entry.key}', () {
      expect(LocalParserService.parseGasto(entry.key).monto, entry.value);
      expect(LocalParserService.parseIngreso(entry.key).monto, entry.value);
    });
  }
  test('categorías por palabras completas, sin inventar categoría o ID', () {
    final expense = LocalParserService.parseGasto('Gasté 1000 en taxi');
    expect(expense.categoriaNombre, 'Transporte');
    expect(expense.id, isNull);
    expect(expense.idCategoria, isNull);
    expect(
        LocalParserService.parseGasto('Gasté 1000 en un regalo')
            .categoriaNombre,
        isNull);
    expect(
        LocalParserService.parseGasto('Gasté 1000 en un surtidor')
            .categoriaNombre,
        isNull);
    final income = LocalParserService.parseIngreso('Recibí 1000 de nómina');
    expect(income.categoriaNombre, 'Salario');
    expect(income.fuente, 'Nómina');
    expect(income.descripcion, 'Recibí 1000 de nómina');
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(stt.SpeechListenOptions());
  late _Speech speech;
  late void Function(SpeechRecognitionResult) result;
  late void Function(String) status;
  late void Function(SpeechRecognitionError) error;
  late List<String?> returned;
  setUp(() {
    speech = _Speech();
    returned = [];
    when(() => speech.initialize(
        onStatus: any(named: 'onStatus'),
        onError: any(named: 'onError'))).thenAnswer((call) async {
      status = call.namedArguments[#onStatus] as void Function(String);
      error = call.namedArguments[#onError] as void Function(
          SpeechRecognitionError);
      return true;
    });
    when(() => speech.locales()).thenAnswer((_) async => [
          stt.LocaleName('en_US', 'English'),
          stt.LocaleName('es_ES', 'Español')
        ]);
    when(() => speech.listen(
        onResult: any(named: 'onResult'),
        listenOptions: any(named: 'listenOptions'))).thenAnswer((call) async {
      result = call.namedArguments[#onResult] as void Function(
          SpeechRecognitionResult);
    });
    when(() => speech.stop()).thenAnswer((_) async {});
    when(() => speech.cancel()).thenAnswer((_) async {});
  });
  Future<void> open(WidgetTester tester,
      {PermissionStatus permission = PermissionStatus.granted}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      returned.add(await showDialog<String>(
                          context: context,
                          builder: (_) => VoiceEntryDialog(
                              speech: speech,
                              income: false,
                              requestPermission: () async => permission)));
                    },
                    child: const Text('Voz'))))));
    await tester.tap(find.text('Voz'));
    await tester.pumpAndSettle();
  }

  void say(String words, {bool finalResult = true}) =>
      result(SpeechRecognitionResult.fromJson({
        'alternates': [
          {'recognizedWords': words, 'confidence': 1.0}
        ],
        'resultType': finalResult ? 2 : 0,
      }));

  testWidgets('dictado devuelve texto solo al revisar y usa español disponible',
      (tester) async {
    await open(tester);
    say('Gasté diez mil pesos en taxi');
    await tester.pump();
    expect(returned, isEmpty);
    await tester.tap(find.text('Revisar formulario'));
    await tester.pumpAndSettle();
    expect(returned, ['Gasté diez mil pesos en taxi']);
    final options = verify(() => speech.listen(
            onResult: any(named: 'onResult'),
            listenOptions: captureAny(named: 'listenOptions'))).captured.single
        as stt.SpeechListenOptions;
    expect(options.localeId, 'es_ES');
  });
  testWidgets('cancelar ignora resultados tardíos y cancela el motor',
      (tester) async {
    await open(tester);
    say('Gasté 1000');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    say('Gasté 9999');
    await tester.pump();
    expect(returned, [null]);
    expect(tester.takeException(), isNull);
    verify(() => speech.cancel()).called(greaterThanOrEqualTo(1));
  });
  testWidgets('fin natural no reinicia la escucha al reconstruir',
      (tester) async {
    await open(tester);
    say('Gasté 1000');
    status('done');
    await tester.pumpAndSettle();
    expect(find.text('Revisa el dictado'), findsOneWidget);
    verify(() => speech.listen(
        onResult: any(named: 'onResult'),
        listenOptions: any(named: 'listenOptions'))).called(1);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
  testWidgets('permiso denegado explica el problema y no inicia el motor',
      (tester) async {
    await open(tester, permission: PermissionStatus.permanentlyDenied);
    expect(find.textContaining('ajustes'), findsOneWidget);
    verifyNever(() => speech.initialize(
        onStatus: any(named: 'onStatus'), onError: any(named: 'onError')));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
  testWidgets('motor no disponible se informa', (tester) async {
    when(() => speech.initialize(
        onStatus: any(named: 'onStatus'),
        onError: any(named: 'onError'))).thenAnswer((_) async => false);
    await open(tester);
    expect(find.textContaining('no está disponible'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
  testWidgets('error tardío permite cancelar sin enviar datos', (tester) async {
    await open(tester);
    error(SpeechRecognitionError('error_network', true));
    await tester.pump();
    expect(find.textContaining('No se pudo reconocer'), findsOneWidget);
    expect(returned, isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
  testWidgets('sin idioma español informa y no inicia escucha', (tester) async {
    when(() => speech.locales())
        .thenAnswer((_) async => [stt.LocaleName('en_US', 'English')]);
    await open(tester);
    expect(find.textContaining('en español'), findsOneWidget);
    verifyNever(() => speech.listen(
        onResult: any(named: 'onResult'),
        listenOptions: any(named: 'listenOptions')));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });
  testWidgets('pasar a segundo plano cancela y descarta texto tardío',
      (tester) async {
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    say('Gasté 9000');
    await tester.pump();
    expect(returned, [null]);
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  testWidgets('stop espera al resultado final y bloquea doble confirmación',
      (tester) async {
    await open(tester);
    say('Gasté diez', finalResult: false);
    final stopped = Completer<void>();
    when(() => speech.stop()).thenAnswer((_) => stopped.future);
    await tester.tap(find.text('Revisar formulario'));
    await tester.pump();
    expect(find.text('Preparando formulario…'), findsOneWidget);
    stopped.complete();
    await tester.pump();
    say('Gasté diez mil pesos');
    await tester.pumpAndSettle();
    expect(returned, ['Gasté diez mil pesos']);
    verify(() => speech.stop()).called(1);
  });
  testWidgets('volver atrás cierra y cancela, incluso antes del permiso',
      (tester) async {
    final permission = Completer<PermissionStatus>();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<String>(
                        context: context,
                        builder: (_) => VoiceEntryDialog(
                            speech: speech,
                            income: true,
                            requestPermission: () => permission.future)),
                    child: const Text('Voz'))))));
    await tester.tap(find.text('Voz'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    permission.complete(PermissionStatus.granted);
    await tester.pumpAndSettle();
    verifyNever(() => speech.initialize(
        onStatus: any(named: 'onStatus'), onError: any(named: 'onError')));
    expect(tester.takeException(), isNull);
  });
}
