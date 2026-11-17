import 'dart:async';

import 'package:contracts/contracts.dart';

/// In-memory [SessionAudioSource] controlled directly by a test.
final class FakeSessionAudioSource implements SessionAudioSource {
  /// Creates an idle fake source.
  FakeSessionAudioSource({
    this.startResult = const Result<void>.ok(null),
    this.pauseResult = const Result<void>.ok(null),
    this.resumeResult = const Result<void>.ok(null),
    this.stopResult = const Result<void>.ok(null),
  });

  final StreamController<Result<SessionAudioEvent>> _events =
      StreamController<Result<SessionAudioEvent>>.broadcast(sync: true);

  /// Result returned by [start].
  final Result<void> startResult;

  /// Result returned by [pause].
  final Result<void> pauseResult;

  /// Result returned by [resume].
  final Result<void> resumeResult;

  /// Result returned by [stop].
  final Result<void> stopResult;

  /// Session id most recently passed to [start].
  String? sessionId;

  /// Number of pause calls.
  int pauseCalls = 0;

  /// Number of resume calls.
  int resumeCalls = 0;

  /// Number of stop calls.
  int stopCalls = 0;

  /// Whether [dispose] was called.
  bool disposed = false;

  @override
  Stream<Result<SessionAudioEvent>> get events => _events.stream;

  @override
  Future<Result<void>> start(String sessionId) async {
    this.sessionId = sessionId;
    return startResult;
  }

  @override
  Future<Result<void>> pause() async {
    pauseCalls++;
    return pauseResult;
  }

  @override
  Future<Result<void>> resume() async {
    resumeCalls++;
    return resumeResult;
  }

  @override
  Future<Result<void>> stop() async {
    stopCalls++;
    return stopResult;
  }

  /// Emits one source event synchronously.
  void emit(SessionAudioEvent event) => _events.add(Result.ok(event));

  /// Emits an operation error through the source stream.
  void emitError(Exception error) => _events.add(Result.error(error));

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
  }
}
