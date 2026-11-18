import 'dart:async';

import 'package:contracts/contracts.dart';

/// Audio input selected for a prototype reading session.
sealed class PrototypeSessionInput {
  const new();
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

/// Temporary app-side session contract until ADR 0005 lands in `contracts`.
abstract interface class PrototypeReadingSession {
  /// Events consumed by `ReadingViewModel`.
  Stream<SessionEvent> get events;

  /// Starts the session with microphone or WAV input.
  Future<void> start(PrototypeSessionInput input);

  /// Pauses event delivery without losing position.
  Future<void> pause();

  /// Continues from the preserved position.
  Future<void> resume();

  /// Finishes the current run.
  Future<void> stop();

  /// Reveals the next word as a hint.
  Future<void> requestHint();

  /// Releases streams and timers.
  Future<void> dispose();
}

/// Creates sessions for canonical reading-order word lists.
abstract interface class PrototypeReadingSessionFactory {
  /// Creates one session instance.
  PrototypeReadingSession create(List<WordKey> words);
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

  @override
  Stream<SessionEvent> get events => _events.stream;

  @override
  Future<void> start(PrototypeSessionInput input) async {
    if (_disposed || _timer != null || _index >= _words.length) return;
    _paused = false;
    _timer = Timer.periodic(eventInterval, (_) => _tick());
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
  }

  @override
  Future<void> pause() async {
    _paused = true;
  }

  @override
  Future<void> resume() async {
    _paused = false;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> requestHint() async {
    if (_disposed || _index >= _words.length) return;
    final word = _words[_index];
    _events.add(
      WordRevealed(
        sessionId: 'prototype-scripted',
        atMs: _elapsedMs,
        word: word,
        reason: RevealReason.hint,
      ),
    );
    _index += 1;
  }

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
  PrototypeReadingSession create(List<WordKey> words) =>
      ScriptedPrototypeReadingSession(words);
}
