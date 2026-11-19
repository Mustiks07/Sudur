import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:contracts/contracts.dart';
import 'package:mushaf_view/mushaf_view.dart';
import 'package:sudur/data/repositories/prototype_repository.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_session.dart';

const firstWord = WordKey(78, 1, 1);
const secondWord = WordKey(78, 1, 2);

PrototypeBundle fakePrototypeBundle() => PrototypeBundle(
  pages: <MushafPageData>[
    _page(582, <MushafFragment>[
      const MushafFragment(
        glyph: 'ONE',
        kind: MushafFragmentKind.word,
        wordKey: firstWord,
      ),
      const MushafFragment(
        glyph: 'TWO',
        kind: MushafFragmentKind.word,
        wordKey: secondWord,
      ),
    ]),
    _page(583, const <MushafFragment>[]),
  ],
  fontFamilies: const <int, String>{582: 'sans-serif', 583: 'sans-serif'},
  sessionWords: const <WordKey>[firstWord, secondWord],
  modelDirectory: '/fake/model',
  sessionConfiguration: const PrototypeSessionConfiguration(
    words: <WordKey>[firstWord, secondWord],
    contentJson: '{}',
    normalizerJson: '{}',
    modelDirectory: '/fake/model',
    vadModelPath: '/fake/vad.onnx',
    textVersion: 'fake-text',
    rulesVersion: 'fake-rules',
  ),
);

MushafPageData _page(int number, List<MushafFragment> firstLine) =>
    MushafPageData(
      pageNumber: number,
      lines: <MushafLineData>[
        MushafLineData(firstLine),
        for (var line = 1; line < 15; line += 1)
          const MushafLineData(<MushafFragment>[]),
      ],
      ayahSemantics: const <MushafAyahSemantics>[],
    );

final class FakePrototypeRepository implements PrototypeRepository {
  new({PrototypeBundle? bundle}) : bundle = bundle ?? fakePrototypeBundle();

  final PrototypeBundle bundle;
  final List<PrototypeModelChoice> preparedModels = <PrototypeModelChoice>[];
  String? pickedWav;
  String? sharedLog;

  @override
  Future<PrototypeBundle> prepare(
    PrototypeModelChoice model, {
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) async {
    preparedModels.add(model);
    onProgress(
      const PrototypeDownloadProgress(
        completedBytes: 10,
        totalBytes: 10,
        resourceName: 'fake',
      ),
    );
    return bundle;
  }

  @override
  Future<AsrDeviceBenchmark> benchmark(PrototypeBundle bundle) async =>
      const AsrDeviceBenchmark(
        modelId: 'fake',
        audioDurationMs: 10000,
        decodeMs: 2500,
      );

  @override
  Future<String?> pickWavFile() async => pickedWav;

  @override
  Future<void> shareLog(String json) async {
    sharedLog = json;
  }
}

final class ManualPrototypeSession implements PrototypeReadingSession {
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  final StreamController<PrototypeSessionDiagnostic> _diagnostics =
      StreamController<PrototypeSessionDiagnostic>.broadcast(sync: true);
  final StreamController<Exception> _failures =
      StreamController<Exception>.broadcast(sync: true);

  PrototypeSessionInput? input;
  int pauses = 0;
  int resumes = 0;
  int stops = 0;
  int hints = 0;
  final List<SessionCommand> commands = <SessionCommand>[];
  Completer<Result<void>>? startResult;

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<Exception> get failures => _failures.stream;

  @override
  Stream<PrototypeSessionDiagnostic> get diagnostics => _diagnostics.stream;

  void emit(SessionEvent event) => _events.add(event);

  void emitDiagnostic(PrototypeSessionDiagnostic event) =>
      _diagnostics.add(event);

  void emitFailure(Exception error) => _failures.add(error);

  @override
  Future<void> configureInput(PrototypeSessionInput input) async {
    this.input = input;
  }

  @override
  Future<Result<void>> execute(SessionCommand command) async {
    commands.add(command);
    switch (command) {
      case StartSession():
        final pending = startResult;
        if (pending != null) return await pending.future;
      case Pause():
        pauses += 1;
      case Resume():
        resumes += 1;
      case Stop():
        stops += 1;
      case RequestHint():
        hints += 1;
      case DisputeEvent():
        break;
    }
    return const Result<void>.ok(null);
  }

  @override
  Future<void> dispose() async {
    await _diagnostics.close();
    await _failures.close();
  }
}

final class ManualPrototypeSessionFactory
    implements PrototypeReadingSessionFactory {
  final List<ManualPrototypeSession> sessions = <ManualPrototypeSession>[];

  ManualPrototypeSession get session => sessions.last;

  @override
  PrototypeReadingSession create(PrototypeSessionConfiguration configuration) {
    final session = ManualPrototypeSession();
    sessions.add(session);
    return session;
  }
}
