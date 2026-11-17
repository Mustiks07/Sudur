import 'dart:async';
import 'dart:io';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/prototype_content.dart';
import 'package:sudur/data/services/prototype_trace.dart';
import 'package:sudur/ui/prototype/view_models/prototype_view_model.dart';

final class FakePrototypeRepository implements PrototypeRepository {
  final eventController = StreamController<SessionEvent>.broadcast();
  final statusController = StreamController<String>.broadcast();
  final startGate = Completer<Result<void>>();
  int stops = 0;
  bool? fileRequested;
  @override
  final trace = PrototypeTrace();
  @override
  Stream<SessionEvent> get events => eventController.stream;
  @override
  Stream<String> get status => statusController.stream;
  @override
  Future<String> root() async => '/unused';
  @override
  Future<Result<void>> start(String model, {required bool fromFile}) {
    fileRequested = fromFile;
    return startGate.future;
  }

  @override
  Future<Result<void>> stop() async {
    stops++;
    return const Result.ok(null);
  }

  @override
  Future<Result<AsrDeviceDecision>> benchmark() async =>
      const Result.ok(AsrDeviceDecision.tiny);
  @override
  Future<void> share(String model) async {}
  @override
  Future<void> dispose() async {
    await eventController.close();
    await statusController.close();
  }
}

void main() {
  late FakePrototypeRepository repository;
  late PrototypeViewModel model;
  setUp(() {
    repository = FakePrototypeRepository();
    model = PrototypeViewModel(repository)
      ..content = PrototypeContent(
        File('../packages/testing/fixtures/content_p582_583.json')
            .readAsStringSync(),
      )
      ..fonts = PageFontLoader(fontDirectoryPath: '/unused');
  });
  tearDown(() => model.dispose());

  test('background stop waits for model load and then ends capture', () async {
    final started = model.start();
    await Future<void>.delayed(Duration.zero);
    final stopped = model.stop();
    expect(repository.stops, 0);
    repository.startGate.complete(const Result.ok(null));
    await started;
    await stopped;
    expect(repository.stops, 1);
    expect(model.running, isFalse);
    expect(model.state, 'stopped');
  });

  test(
    'reveals only an explicit heard word, without claiming correctness',
    () async {
      repository.startGate.complete(const Result.ok(null));
      await model.start();
      const word = WordKey(78, 1, 1);
      expect(model.words[word], MushafWordState.hidden);
      repository.eventController.add(
        const WordRevealed(
          sessionId: 'test',
          atMs: 100,
          word: word,
          reason: RevealReason.heard,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(model.words[word], MushafWordState.normal);
      expect(model.words[const WordKey(78, 1, 2)], MushafWordState.hidden);
    },
  );

  test('denied microphone leaves a usable stopped screen', () async {
    repository.startGate.complete(Result.error(Exception('micDenied')));
    await model.start();
    expect(model.running, isFalse);
    expect(model.busy, isFalse);
    expect(model.state, 'failed');
  });

  test(
    'file selection reaches the session and benchmark selects tiny',
    () async {
      await model.benchmark();
      expect(model.model, 'quran-asr-tiny');
      model.selectFile(true);
      repository.startGate.complete(const Result.ok(null));
      await model.start();
      expect(repository.fileRequested, isTrue);
      model.selectModel('quran-asr-small');
      expect(model.model, 'quran-asr-tiny');
    },
  );
}
