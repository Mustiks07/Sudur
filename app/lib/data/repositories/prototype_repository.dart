import 'dart:async';

import 'package:asr_sherpa/asr_sherpa.dart';
import 'package:audio_capture/audio_capture.dart' as audio;
import 'package:contracts/contracts.dart';
import 'package:sudur/config/prototype_config.dart';
import 'package:sudur/data/services/prototype_follow.dart';
import 'package:sudur/data/services/prototype_platform.dart';
import 'package:sudur/data/services/prototype_trace.dart';

/// Prototype operations exposed to the view model, replaceable in tests.
abstract interface class PrototypeRepository {
  /// Following events, never raw recognition text.
  Stream<SessionEvent> get events;

  /// Lifecycle and error codes for localized UI presentation.
  Stream<String> get status;

  /// Metadata-only measurement log.
  PrototypeTrace get trace;

  /// Location of installed content, models and fonts.
  Future<String> root();

  /// Starts one fresh session after the UI permission explanation.
  Future<Result<void>> start(String model, {required bool fromFile});

  /// Flushes and releases the active session.
  Future<Result<void>> stop();

  /// Measures both installed models sequentially, releasing each afterwards.
  Future<Result<AsrDeviceDecision>> benchmark();

  /// Explicitly exports timing metadata.
  Future<void> share(String model);

  /// Frees all owned streams and workers.
  Future<void> dispose();
}

/// Wires P05 → P04 → P06; P08 deliberately does not claim mistake checking.
final class LocalPrototypeRepository implements PrototypeRepository {
  /// Creates a repository for a dev-only prototype.
  new({required this._platform, this.config = const PrototypeConfig()});

  /// Limits for worker transport and device fallback.
  final PrototypeConfig config;
  AsrDeviceDecision? _decision;
  final PrototypePlatform _platform;
  final _events = StreamController<SessionEvent>.broadcast();
  final _status = StreamController<String>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  audio.AudioCaptureService? _capture;
  SherpaCtcRecognizer? _recognizer;
  PrototypeFollow? _follow;
  Future<void> _following = Future<void>.value();
  Future<Result<void>>? _stopping;
  int _pending = 0;
  Completer<void>? _drained;
  int _endMs = 0;
  String _session = '';
  String _traceModel = 'none';
  bool _failed = false;
  bool _disposed = false;

  @override
  final PrototypeTrace trace = PrototypeTrace();
  @override
  Stream<SessionEvent> get events => _events.stream;
  @override
  Stream<String> get status => _status.stream;
  @override
  Future<String> root() => _platform.root();

  @override
  Future<Result<void>> start(String model, {required bool fromFile}) async {
    if (_disposed) return Result.error(Exception('disposed'));
    if (_capture != null) return Result.error(Exception('alreadyRunning'));
    if (_decision == AsrDeviceDecision.selfCheck) {
      return Result.error(Exception('deviceTooSlow'));
    }
    trace.start();
    _traceModel = model;
    trace.add(fromFile ? 'fileInput' : 'microphoneInput');
    _failed = false;
    _pending = 0;
    _endMs = 0;
    _session = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final directory = await root();
      _follow = await PrototypeFollow.start(directory, model);
      final recognizer = SherpaCtcRecognizer(
        sessionId: _session,
        config:
            _decision == AsrDeviceDecision.smallWithSlowPartials &&
                model == 'quran-asr-small'
            ? SherpaRecognizerConfig(
                partialIntervalMs: config.slowPartialIntervalMs,
              )
            : const SherpaRecognizerConfig(),
      );
      _recognizer = recognizer;
      _require(await recognizer.load('$directory/$model'));
      trace.add('modelLoaded');
      final capture = audio.AudioCaptureService();
      _capture = capture;
      _subscriptions.add(
        recognizer.outcomes.listen((outcome) {
          _pending--;
          trace.add('asrRequestCompleted', requestId: outcome.requestId);
          if (outcome.result case Error<RecognitionResult?>()) _fail();
          if (_pending == 0) {
            final drained = _drained;
            if (drained != null && !drained.isCompleted) drained.complete();
          }
        }),
      );
      _subscriptions.add(
        recognizer.results.listen((result) {
          trace.add(
            result.isFinal ? 'asrFinal' : 'asrPartial',
            audioMs: result.audioEndMs,
            startMs: result.audioStartMs,
            durationUs: result.decodeMs * 1000,
            segment: result.segmentId,
          );
          _following = _following
              .then((_) async {
                final follow = _follow;
                if (follow == null || _failed) return;
                _emit(await follow.accept(result));
              })
              .catchError((Object error) {
                _fail();
              });
        }),
      );
      _subscriptions.add(
        capture.events.listen((result) {
          if (result case Error<audio.AudioCaptureEvent>()) {
            _fail();
            return;
          }
          if (result case Ok<audio.AudioCaptureEvent>(:final value)) {
            _endMs = value.atMs;
            trace.add(value.runtimeType.toString(), audioMs: value.atMs);
            switch (value) {
              case audio.SpeechSegmentAudioFrame():
                if (_failed) return;
                if (_pending >= config.maxPendingAudioRequests) {
                  trace.add('audioBacklogExceeded');
                  _fail();
                  return;
                }
                _pending++;
                trace.add(
                  'asrRequest',
                  audioMs: value.startMs,
                  segment: value.segmentId,
                  samples: value.samples.length,
                );
                recognizer.acceptAudio(
                  value.samples,
                  value.sampleRate,
                  value.startMs,
                );
              case audio.SpeechSegmentClosed():
                if (_failed) return;
                _pending++;
                recognizer.closeSegment(value.segmentId);
              case audio.FileInputFinished():
                unawaited(stop());
              case audio.CapturePaused():
                _status.add('interrupted');
                unawaited(stop());
              default:
                break;
            }
          }
        }),
      );
      trace.add('captureStart');
      final result = fromFile
          ? await capture.startFile(
              vadModelPath: '$directory/silero_vad.onnx',
              wavPath: '$directory/input.wav',
            )
          : await capture.startMicrophone(
              vadModelPath: '$directory/silero_vad.onnx',
              permissionExplanationShown: true,
            );
      _require(result);
      trace.add('captureStarted');
      _status.add('running');
      return const Result.ok(null);
    } on Object {
      await _release();
      _status.add('failed');
      return Result.error(Exception('prototypeStartFailed'));
    }
  }

  void _emit(List<SessionEvent> events) {
    for (final event in events) {
      final word = switch (event) {
        WordRevealed(:final word) => word,
        _ => null,
      };
      trace.add(
        event.runtimeType.toString(),
        audioMs: event.atMs,
        wordIndex: word == null
            ? null
            : word.surah * 1000000 + word.ayah * 1000 + word.word,
      );
      _events.add(event);
    }
  }

  void _fail() {
    if (_failed || _disposed) return;
    _failed = true;
    trace.add('pipelineFailed');
    _status.add('failed');
    // Schedule outside the event callback so cancellation cannot deadlock it.
    unawaited(
      Future<void>(() async {
        if (!_disposed) await stop();
      }),
    );
  }

  @override
  Future<Result<void>> stop() => _stopping ??= _stop().whenComplete(() {
    _stopping = null;
  });

  Future<Result<void>> _stop() async {
    if (_capture != null) _status.add('stopping');
    try {
      final capture = _capture;
      if (capture != null) _require(await capture.stop());
      // Drain stream callbacks preceding the stop acknowledgement.
      await Future<void>.delayed(Duration.zero);
      if (_pending > 0) {
        _drained = Completer<void>();
        await _drained!.future.timeout(
          config.drainTimeout,
        ); // Assigned immediately above.
      }
      await _following;
      final follow = _follow;
      if (follow != null && !_failed) {
        _emit(await follow.finish(_session, _endMs));
      }
      trace.add('finished', audioMs: _endMs);
      return _failed
          ? Result.error(Exception('prototypeFailed'))
          : const Result.ok(null);
    } on Object {
      _failed = true;
      return Result.error(Exception('prototypeStopFailed'));
    } finally {
      await _release();
      _status.add(_failed ? 'failed' : 'stopped');
    }
  }

  Future<void> _release() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _capture?.dispose();
    _capture = null;
    await _recognizer?.dispose();
    _recognizer = null;
    _follow?.dispose();
    _follow = null;
    _drained = null;
    _pending = 0;
  }

  @override
  Future<Result<AsrDeviceDecision>> benchmark() async {
    try {
      final directory = await root();
      final ratios = <double>[];
      for (final model in ['quran-asr-small', 'quran-asr-tiny']) {
        final recognizer = SherpaCtcRecognizer(sessionId: 'device-test');
        try {
          _require(await recognizer.load('$directory/$model'));
          final result = _require(await recognizer.benchmarkDevice());
          ratios.add(result.speedRatio);
          trace.add(
            'benchmark',
            audioMs: result.audioDurationMs,
            durationUs: result.decodeMs * 1000,
          );
        } finally {
          await recognizer.dispose();
        }
      }
      final decision = selectAsrDeviceDecision(
        smallSpeedRatio: ratios[0],
        tinySpeedRatio: ratios[1],
      );
      _decision = decision;
      return Result.ok(decision);
    } on Object {
      return Result.error(Exception('benchmarkFailed'));
    }
  }

  @override
  Future<void> share(String model) =>
      _platform.share(trace.encode(_traceModel));

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _events.close();
    await _status.close();
  }
}

T _require<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Error(:final error) => throw error,
};
