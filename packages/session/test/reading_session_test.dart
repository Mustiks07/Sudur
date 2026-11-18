import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';
import 'package:session/session.dart';
import 'package:test/test.dart';
import 'package:testing/testing.dart';

const fixturePath = '../testing/fixtures/content_p582_583.json';
const Normalizer normalizer = Normalizer.builtIn;
const versions = ReadingVersions(
  modelId: 'fake/scripted',
  modelVersion: '0',
  rulesVersion: 'test-rules',
  textVersion: 'test-text',
);

late InMemoryQuranText quran;

List<Word> ayah(int surah, int number) => quran.words
    .where((word) => word.key.surah == surah && word.key.ayah == number)
    .toList();

List<Word> ayahs(int surah, int first, int last) => [
      for (var number = first; number <= last; number++) ...ayah(surah, number),
    ];

List<String> heard(Iterable<Word> words) => [
      for (final word in words) quran.searchKey(word.key, normalizer.id).value,
    ];

final class _Harness {
  _Harness({
    required this.session,
    required this.audio,
    required this.recognizer,
    required this.events,
    required this.states,
    required this.strictSignals,
  });

  final ReadingSession session;
  final FakeSessionAudioSource audio;
  final FakeSpeechRecognizer recognizer;
  final List<SessionEvent> events;
  final List<ReadingSessionState> states;
  final List<StrictSignal> strictSignals;
}

_Harness _harness({
  Result<void> loadResult = const Result<void>.ok(null),
  SessionCheckpointStore? checkpointStore,
  void Function(int segmentId)? onCloseSegment,
  CheckParams checkParams = CheckParams.defaults,
  Duration strictTickInterval = const Duration(milliseconds: 250),
  void Function(FakeSessionAudioSource source)? onAudioStop,
}) {
  final audio = FakeSessionAudioSource(onStop: onAudioStop);
  final recognizer = FakeSpeechRecognizer(
    const [],
    info: scriptedRecognizerInfo,
    loadResult: loadResult,
    onCloseSegment: onCloseSegment,
  );
  final events = <SessionEvent>[];
  final states = <ReadingSessionState>[];
  final strictSignals = <StrictSignal>[];
  final session = ReadingSession(
    recognizer: recognizer,
    audioSource: audio,
    text: quran,
    normalizer: normalizer,
    versions: versions,
    modelDirectory: '/in-memory-model',
    createSessionId: () => 'test-session',
    checkpointStore: checkpointStore,
    checkParams: checkParams,
    finishingTimeout: const Duration(milliseconds: 50),
    strictTickInterval: strictTickInterval,
  );
  session.events.listen(events.add);
  session.states.listen(states.add);
  session.strictSignals.listen(strictSignals.add);
  return _Harness(
    session: session,
    audio: audio,
    recognizer: recognizer,
    events: events,
    states: states,
    strictSignals: strictSignals,
  );
}

StartSession startFor(List<Word> words) => StartSession(
      fromWordKey: words.first.key,
      toWordKey: words.last.key,
      mode: SessionMode.recall,
      behavior: SessionBehavior.gentle,
    );

StartSession strictFor(List<Word> words) => StartSession(
      fromWordKey: words.first.key,
      toWordKey: words.last.key,
      mode: SessionMode.recall,
      behavior: SessionBehavior.strict,
    );

void _emitScript(_Harness h, RecognitionScript script) =>
    script.results.forEach(h.recognizer.emit);

SessionFinished _finished(_Harness h) =>
    h.events.whereType<SessionFinished>().single;

void main() {
  setUpAll(() {
    final words = switch (
        ContentJsonSource(File(fixturePath).readAsStringSync()).loadWords()) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
    quran = InMemoryQuranText(
      words: words,
      normalizers: [normalizer],
      params: SearchParams.defaults,
    );
  });

  test('clean reading of surah 78 reveals every word in order', () async {
    final words = ayahs(78, 1, 40);
    final h = _harness();
    addTearDown(h.session.dispose);
    expect(await h.session.execute(startFor(words)), isA<Ok<void>>());

    final script = RecognitionScript();
    for (var number = 1; number <= 40; number++) {
      script.segment(heard(ayah(78, number)));
    }
    _emitScript(h, script);
    await h.session.execute(const Stop());

    expect(
      h.events.whereType<WordRevealed>().map((event) => event.word),
      words.map((word) => word.key),
    );
    expect(
      _finished(h).words.map((result) => result.outcome).toSet(),
      {SessionWordOutcome.read},
    );
    expect(h.session.state.phase, ReadingSessionPhase.finished);
  });

  test('a skipped word becomes a confirmed error', () async {
    final words = ayahs(78, 12, 14);
    final skipped = words[4];
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    _emitScript(
      h,
      RecognitionScript()..segment(heard([...words.take(4), ...words.skip(5)])),
    );
    await h.session.execute(const Stop());

    final result = _finished(h).words.singleWhere(
          (word) => word.wordKey == skipped.key,
        );
    expect(result.outcome, SessionWordOutcome.error);
    expect(
      h.events.whereType<CheckEvent>().where(
            (event) =>
                event.kind == CheckKind.omission &&
                event.state == CheckState.confirmed,
          ),
      isNotEmpty,
    );
    expect(
      h.events.whereType<CheckStateChanged>().where(
            (event) =>
                event.from == CheckState.preliminary &&
                event.to == CheckState.confirmed,
          ),
      isNotEmpty,
    );
  });

  test('DisputeEvent moves a confirmed check to disputed', () async {
    final words = ayahs(78, 12, 14);
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    _emitScript(
      h,
      RecognitionScript()..segment(heard([...words.take(4), ...words.skip(5)])),
    );
    final confirmed = h.events.whereType<CheckEvent>().lastWhere(
          (event) => event.state == CheckState.confirmed,
        );

    expect(
      await h.session.execute(DisputeEvent(eventId: confirmed.eventId)),
      isA<Ok<void>>(),
    );
    expect(
      h.events.whereType<CheckStateChanged>().last.to,
      CheckState.disputed,
    );
  });

  test('pause and resume retain following position and checkpoint', () async {
    final words = ayahs(78, 1, 4);
    final store = _FakeCheckpointStore();
    final h = _harness(checkpointStore: store);
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    final script = RecognitionScript()..segment(heard(ayahs(78, 1, 2)));
    final beforePause = script.results.length;
    script.segment(heard(ayahs(78, 3, 4)));
    script.results.take(beforePause).forEach(h.recognizer.emit);

    expect(await h.session.execute(const Pause()), isA<Ok<void>>());
    expect(h.session.state.phase, ReadingSessionPhase.paused);
    expect(store.saved, hasLength(1));
    expect(await h.session.execute(const Resume()), isA<Ok<void>>());
    script.results.skip(beforePause).forEach(h.recognizer.emit);
    await h.session.execute(const Stop());

    expect(h.audio.pauseCalls, 1);
    expect(h.audio.resumeCalls, 1);
    expect(
      h.events.whereType<WordRevealed>().map((event) => event.word).toSet(),
      words.map((word) => word.key).toSet(),
    );
  });

  test('all four hint kinds use words from the requested canon range',
      () async {
    final words = ayahs(78, 1, 4);
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));

    for (final kind in HintKind.values) {
      expect(
        await h.session.execute(RequestHint(kind: kind)),
        isA<Ok<void>>(),
      );
    }

    final hints = h.events.whereType<HintGiven>().toList();
    expect(hints.map((hint) => hint.kind), HintKind.values);
    expect(
      hints.every((hint) => words.any((word) => word.key == hint.wordKey)),
      isTrue,
    );
  });

  test('stop in the middle marks remaining words notRead, not error', () async {
    final words = ayahs(78, 1, 3);
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    _emitScript(h, RecognitionScript()..segment(heard(ayah(78, 1))));
    await h.session.execute(const Stop());

    final summary = _finished(h).words;
    expect(
      summary
          .where((result) => result.outcome == SessionWordOutcome.notRead)
          .map((result) => result.wordKey),
      words.skip(ayah(78, 1).length).map((word) => word.key),
    );
    expect(
      summary.where((result) => result.outcome == SessionWordOutcome.error),
      isEmpty,
    );
  });

  test('missing model enters error(modelMissing)', () async {
    final h = _harness(
      loadResult: const Result<void>.error(FormatException('missing')),
    );
    addTearDown(h.session.dispose);

    expect(
      await h.session.execute(startFor(ayah(78, 1))),
      isA<Error<void>>(),
    );
    expect(h.session.state.phase, ReadingSessionPhase.error);
    expect(h.session.state.error, ReadingSessionError.modelMissing);
    expect(h.audio.sessionId, isNull);
  });

  test('audio frames and closures are forwarded without writing audio',
      () async {
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(ayah(78, 1)));
    h.audio
      ..emit(
        const SessionAudioSegmentOpened(
          atMs: 100,
          segmentId: 7,
          pauseBeforeMs: 100,
        ),
      )
      ..emit(
        SessionAudioFrame(
          atMs: 120,
          segmentId: 7,
          samples: Float32List(320),
          sampleRateHz: 16000,
          startMs: 100,
          endMs: 120,
        ),
      )
      ..emit(
        const SignalQuality(
          sessionId: 'test-session',
          atMs: 120,
          level: SignalQualityLevel.noisy,
          sinceMs: 100,
        ),
      )
      ..emit(
        const SessionAudioSegmentClosed(atMs: 140, segmentId: 7),
      );

    expect(h.recognizer.acceptedAudio, hasLength(1));
    expect(h.recognizer.acceptedAudio.single.startMs, 100);
    expect(h.recognizer.closedSegments, [7]);
    expect(h.events.whereType<SignalQuality>(), hasLength(1));
  });

  test('slow recognition makes the affected word unverified', () async {
    final words = ayah(78, 1);
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    final scripted = RecognitionScript()..segment(heard(words));
    final source = scripted.results.last;
    h.recognizer.emit(
      RecognitionResult(
        sessionId: source.sessionId,
        segmentId: source.segmentId,
        isFinal: source.isFinal,
        text: source.text,
        tokens: source.tokens,
        audioStartMs: source.audioStartMs,
        audioEndMs: source.audioEndMs,
        decodeMs: (source.audioEndMs - source.audioStartMs) * 4,
        info: source.info,
      ),
    );

    expect(h.session.state.error, ReadingSessionError.deviceTooSlow);
    await h.session.execute(const Stop());
    expect(_finished(h).audioWasSuitable, isFalse);
  });

  test('finishing waits for the final result of an open segment', () async {
    final words = ayah(78, 1);
    late FakeSpeechRecognizer recognizer;
    final audio = FakeSessionAudioSource();
    final script = RecognitionScript()..segment(heard(words));
    final finalResult = script.results.last;
    recognizer = FakeSpeechRecognizer(
      const [],
      info: scriptedRecognizerInfo,
      onCloseSegment: (_) => recognizer.emit(finalResult),
    );
    final events = <SessionEvent>[];
    final session = ReadingSession(
      recognizer: recognizer,
      audioSource: audio,
      text: quran,
      normalizer: normalizer,
      versions: versions,
      modelDirectory: '/in-memory-model',
      createSessionId: () => 'test-session',
      finishingTimeout: const Duration(milliseconds: 50),
    );
    session.events.listen(events.add);
    addTearDown(session.dispose);
    await session.execute(startFor(words));
    audio.emit(
      const SessionAudioSegmentOpened(atMs: 0, segmentId: 1),
    );

    expect(await session.execute(const Stop()), isA<Ok<void>>());
    expect(
      events.whereType<SessionFinished>().single.words.first.outcome,
      SessionWordOutcome.read,
    );
  });

  test('finishing waits for a final result from an already closed segment',
      () async {
    final words = ayah(78, 1);
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(startFor(words));
    h.audio
      ..emit(const SessionAudioSegmentOpened(atMs: 0, segmentId: 1))
      ..emit(const SessionAudioSegmentClosed(atMs: 1000, segmentId: 1));
    final finalResult =
        (RecognitionScript()..segment(heard(words))).results.last;
    Timer(
      const Duration(milliseconds: 10),
      () => h.recognizer.emit(finalResult),
    );

    expect(await h.session.execute(const Stop()), isA<Ok<void>>());
    expect(_finished(h).words.first.outcome, SessionWordOutcome.read);
  });

  test('stop drains source tail frames and closure before finishing', () async {
    final words = ayah(78, 1);
    late FakeSpeechRecognizer recognizer;
    final finalResult =
        (RecognitionScript()..segment(heard(words))).results.last;
    final audio = FakeSessionAudioSource(
      onStop: (source) {
        source
          ..emit(
            SessionAudioFrame(
              atMs: 1000,
              segmentId: 1,
              samples: Float32List(320),
              sampleRateHz: 16000,
              startMs: 980,
              endMs: 1000,
            ),
          )
          ..emit(
            const SessionAudioSegmentClosed(atMs: 1000, segmentId: 1),
          );
      },
    );
    recognizer = FakeSpeechRecognizer(
      const [],
      info: scriptedRecognizerInfo,
      onCloseSegment: (_) => recognizer.emit(finalResult),
    );
    final events = <SessionEvent>[];
    final session = ReadingSession(
      recognizer: recognizer,
      audioSource: audio,
      text: quran,
      normalizer: normalizer,
      versions: versions,
      modelDirectory: '/in-memory-model',
      createSessionId: () => 'test-session',
      finishingTimeout: const Duration(milliseconds: 50),
    );
    session.events.listen(events.add);
    addTearDown(session.dispose);
    await session.execute(startFor(words));
    audio.emit(const SessionAudioSegmentOpened(atMs: 0, segmentId: 1));

    expect(await session.execute(const Stop()), isA<Ok<void>>());
    expect(recognizer.acceptedAudio, hasLength(1));
    expect(
      events.whereType<SessionFinished>().single.words.first.outcome,
      SessionWordOutcome.read,
    );
  });

  test('strict mode forwards wait, offer and stop signals', () async {
    final words = ayahs(78, 12, 16);
    final skipped = words[4];
    final h = _harness();
    addTearDown(h.session.dispose);
    await h.session.execute(strictFor(words));
    _emitScript(
      h,
      RecognitionScript()
        ..segment([
          ...heard(words.take(4)),
          ...heard(words.skip(5).take(7)),
          quran.searchKey(skipped.key, normalizer.id).value,
        ]),
    );
    expect(h.strictSignals.whereType<OfferHint>(), hasLength(1));
    final revealsBeforeHint = h.events.whereType<WordRevealed>().length;
    expect(
      await h.session.execute(const RequestHint(kind: HintKind.word)),
      isA<Ok<void>>(),
    );

    expect(
      h.strictSignals.map((signal) => signal.runtimeType),
      containsAllInOrder([WaitForWord, OfferHint, StopWaiting]),
    );
    expect(
      h.strictSignals.every((signal) => signal.word == skipped.key),
      isTrue,
    );
    expect((h.strictSignals.last as StopWaiting).how, WaitEnd.hint);
    expect(
      h.events.whereType<WordRevealed>().length,
      greaterThan(revealsBeforeHint),
    );
  });

  test('strict tick offers a hint after the configured wait', () async {
    final words = ayahs(78, 12, 16);
    final h = _harness(
      checkParams: const CheckParams(
        strongMatch: 0.85,
        substitutionMax: 0.6,
        confirmContextWords: 2,
        jumpMinWords: 3,
        selfCorrectionMs: 1,
        selfCorrectionWords: 0,
        hesitationPauseMs: 2500,
        hesitationTempoFactor: 3,
        strictMaxFails: 100,
        strictMaxWaitMs: 4,
      ),
      strictTickInterval: const Duration(milliseconds: 1),
    );
    addTearDown(h.session.dispose);
    await h.session.execute(strictFor(words));
    _emitScript(
      h,
      RecognitionScript()
        ..segment(heard([...words.take(4), ...words.skip(5).take(4)])),
    );
    expect(h.strictSignals.whereType<WaitForWord>(), isNotEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(h.strictSignals.whereType<OfferHint>(), hasLength(1));
  });
}

final class _FakeCheckpointStore implements SessionCheckpointStore {
  final List<SessionCheckpoint> saved = [];

  @override
  Future<Result<void>> save(SessionCheckpoint checkpoint) async {
    saved.add(checkpoint);
    return const Result<void>.ok(null);
  }
}
