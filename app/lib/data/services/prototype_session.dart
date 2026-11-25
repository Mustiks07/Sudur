import 'dart:async';
import 'dart:typed_data';

import 'package:contracts/contracts.dart';

/// Audio input selected for a prototype reading session.
sealed class PrototypeSessionInput {
  const new();
}

/// Text-free diagnostic signal used only by the prototype measurement log.
enum PrototypeDiagnosticKind {
  /// Voice activity opened a speech segment.
  segmentOpened,

  /// Voice activity closed a speech segment.
  segmentClosed,

  /// ASR emitted a growing partial hypothesis.
  recognitionPartial,

  /// ASR emitted a final hypothesis for one segment.
  recognitionFinal,
}

/// Safe diagnostic metadata; recognized text and audio are never included.
final class PrototypeSessionDiagnostic {
  /// Creates one diagnostic counter input.
  const new(this.kind, {this.decodeMs});

  /// Pipeline stage that advanced.
  final PrototypeDiagnosticKind kind;

  /// ASR decode duration, only for recognition results.
  final int? decodeMs;
}

/// Uses the microphone once the real S05 session is connected.
final class PrototypeMicrophoneInput extends PrototypeSessionInput {
  /// Creates microphone input.
  const new();
}

/// Replays a WAV selected by the owner in measurement mode.
final class PrototypeWavInput extends PrototypeSessionInput {
  /// Creates file input for [path].
  const new(this.path);

  /// Local path returned by the platform file picker.
  final String path;
}

/// App-side session boundary matching the ADR 0005 command contract.
///
/// Input selection remains prototype-specific until S05 provides the real
/// microphone and WAV adapters through [SessionAudioSource].
abstract interface class PrototypeReadingSession {
  /// Events consumed by `ReadingViewModel`.
  Stream<SessionEvent> get events;

  /// Terminal worker failures that are not tied to one command.
  Stream<Exception> get failures;

  /// Text-free pipeline diagnostics consumed by the measurement log.
  Stream<PrototypeSessionDiagnostic> get diagnostics;

  /// Selects the source used by the next [StartSession] command.
  Future<void> configureInput(PrototypeSessionInput input);

  /// Executes one type-safe session command from `contracts`.
  Future<Result<void>> execute(SessionCommand command);

  /// The reader's own audio around check event [eventId], kept in memory
  /// for «Разбор» (ЗВ-02); `null` when there is none.
  ReviewAudio? reviewSnippet(String eventId);

  /// Drops every kept snippet when «Разбор» closes (ЗВ-07).
  void closeReview();

  /// Releases streams and timers.
  Future<void> dispose();
}

/// Audio of the reader in memory, mono float samples (never on disk).
final class ReviewAudio {
  /// Creates the audio.
  const new({required this.samples, required this.sampleRate});

  /// Samples in −1…1.
  final Float32List samples;

  /// Samples per second.
  final int sampleRate;
}

/// Creates sessions for canonical reading-order word lists.
abstract interface class PrototypeReadingSessionFactory {
  /// Creates one session instance.
  PrototypeReadingSession create(PrototypeSessionConfiguration configuration);
}

/// Isolate-sendable inputs required to build the real reading session.
final class PrototypeSessionConfiguration {
  /// Creates verified session inputs installed by the prototype repository.
  const new({
    required this.words,
    required this.contentJson,
    required this.normalizerJson,
    required this.modelDirectory,
    required this.vadModelPath,
    required this.textVersion,
    required this.rulesVersion,
    this.wholeQuranText = false,
  });

  /// Canonical reading range shown by the prototype.
  final List<WordKey> words;

  /// Canonical content JSON; parsed inside the session worker.
  final String contentJson;

  /// Whether [contentJson] is the whole-Quran text (format 2, ADR 0004)
  /// rather than the prototype pages.
  final bool wholeQuranText;

  /// Normalizer supplied with the selected ASR package.
  final String normalizerJson;

  /// Verified ASR package directory.
  final String modelDirectory;

  /// Verified Silero VAD model path.
  final String vadModelPath;

  /// Canonical content revision used by events.
  final String textVersion;

  /// Follow/check parameter revision used by events.
  final String rulesVersion;
}

/// Scripted session used until S05 is merged and retained for UI tests.
final class ScriptedPrototypeReadingSession implements PrototypeReadingSession {
  /// Creates a session that reveals [words] in order.
  new(
    List<WordKey> words, {
    this.eventInterval = const Duration(milliseconds: 240),
  }) : _words = List.unmodifiable(words);

  /// Delay between scripted word events.
  final Duration eventInterval;

  final List<WordKey> _words;
  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast(sync: true);
  Timer? _timer;
  var _index = 0;
  var _elapsedMs = 0;
  var _paused = false;
  var _disposed = false;
  var _finished = false;
  PrototypeSessionInput _input = const PrototypeMicrophoneInput();
  final Set<WordKey> _hintedWords = <WordKey>{};

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Stream<Exception> get failures => const Stream<Exception>.empty();

  @override
  Stream<PrototypeSessionDiagnostic> get diagnostics =>
      const Stream<PrototypeSessionDiagnostic>.empty();

  @override
  Future<void> configureInput(PrototypeSessionInput input) async {
    _input = input;
  }

  @override
  Future<Result<void>> execute(SessionCommand command) async {
    if (_disposed) {
      return const Result<void>.error(
        _PrototypeSessionException('The scripted session is disposed.'),
      );
    }
    return switch (command) {
      StartSession() => _start(command),
      Pause() => _pause(),
      Resume() => _resume(),
      Stop() => _stop(),
      RequestHint() => _requestHint(command.kind),
      DisputeEvent() => const Result<void>.ok(null),
    };
  }

  Result<void> _start(StartSession command) {
    if (_timer != null || _index >= _words.length) {
      return const Result<void>.error(
        _PrototypeSessionException('The scripted session cannot start.'),
      );
    }
    if (command.fromWordKey != _words.first ||
        command.toWordKey != _words.last) {
      return const Result<void>.error(
        _PrototypeSessionException('The scripted range does not match.'),
      );
    }
    if (_input case PrototypeWavInput(:final path) when path.isEmpty) {
      return const Result<void>.error(
        _PrototypeSessionException('The WAV path is empty.'),
      );
    }
    _paused = false;
    _finished = false;
    _events.add(
      SessionStarted(
        sessionId: 'prototype-scripted',
        atMs: _elapsedMs,
        fromWordKey: command.fromWordKey,
        toWordKey: command.toWordKey,
        mode: command.mode,
        versions: const ReadingVersions(
          modelId: 'prototype-scripted',
          modelVersion: '1',
          rulesVersion: '1',
          textVersion: 'fixture',
        ),
      ),
    );
    _timer = Timer.periodic(eventInterval, (_) => _tick());
    return const Result<void>.ok(null);
  }

  void _tick() {
    if (_paused || _index >= _words.length) {
      if (_index >= _words.length) _timer?.cancel();
      return;
    }
    final word = _words[_index];
    _elapsedMs += eventInterval.inMilliseconds;
    _events
      ..add(
        PositionUpdate(
          sessionId: 'prototype-scripted',
          atMs: _elapsedMs,
          word: word,
          confidence: PositionConfidence.high,
        ),
      )
      ..add(
        WordRevealed(
          sessionId: 'prototype-scripted',
          atMs: _elapsedMs,
          word: word,
          reason: RevealReason.heard,
        ),
      );
    _index += 1;
    if (_index >= _words.length) {
      _timer?.cancel();
      _timer = null;
      _emitFinished();
    }
  }

  Result<void> _pause() {
    _paused = true;
    return const Result<void>.ok(null);
  }

  Result<void> _resume() {
    _paused = false;
    return const Result<void>.ok(null);
  }

  Result<void> _stop() {
    _timer?.cancel();
    _timer = null;
    _emitFinished();
    return const Result<void>.ok(null);
  }

  Result<void> _requestHint(HintKind kind) {
    if (_index >= _words.length) return const Result<void>.ok(null);
    final word = _words[_index];
    _hintedWords.add(word);
    _events
      ..add(
        HintGiven(
          sessionId: 'prototype-scripted',
          atMs: _elapsedMs,
          kind: kind,
          wordKey: word,
        ),
      )
      ..add(
        WordRevealed(
          sessionId: 'prototype-scripted',
          atMs: _elapsedMs,
          word: word,
          reason: RevealReason.hint,
        ),
      );
    _index += 1;
    if (_index >= _words.length) _emitFinished();
    return const Result<void>.ok(null);
  }

  void _emitFinished() {
    if (_finished || _events.isClosed) return;
    _finished = true;
    _events.add(
      SessionFinished(
        sessionId: 'prototype-scripted',
        atMs: _elapsedMs,
        words: <SessionWordResult>[
          for (var index = 0; index < _words.length; index += 1)
            SessionWordResult(
              wordKey: _words[index],
              outcome: index >= _index
                  ? SessionWordOutcome.notRead
                  : _hintedWords.contains(_words[index])
                  ? SessionWordOutcome.readWithHint
                  : SessionWordOutcome.read,
            ),
        ],
        eventIds: const <String>[],
        durationMs: _elapsedMs,
        audioWasSuitable: true,
      ),
    );
  }

  @override
  ReviewAudio? reviewSnippet(String eventId) => null;

  @override
  void closeReview() {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    await _events.close();
  }
}

/// Factory for the production-development scripted session.
final class ScriptedPrototypeReadingSessionFactory
    implements PrototypeReadingSessionFactory {
  /// Creates a factory.
  const new();

  @override
  PrototypeReadingSession create(PrototypeSessionConfiguration configuration) =>
      ScriptedPrototypeReadingSession(configuration.words);
}

final class _PrototypeSessionException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}
