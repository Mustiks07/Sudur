import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_capture/src/audio_capture_config.dart';
import 'package:audio_capture/src/audio_capture_event.dart';
import 'package:audio_capture/src/audio_capture_exception.dart';
import 'package:audio_capture/src/audio_pipeline.dart';
import 'package:audio_capture/src/frame_accumulator.dart';
import 'package:audio_capture/src/pcm16_converter.dart';
import 'package:audio_capture/src/vad_queue.dart';
import 'package:contracts/contracts.dart';
import 'package:crypto/crypto.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

const _sileroVadSha256 =
    '9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6';

/// Entry point for the long-lived audio processing isolate.
void runAudioWorker(SendPort ownerPort) {
  final requests = ReceivePort();
  final worker = _AudioWorker(ownerPort, requests);
  ownerPort.send(requests.sendPort);
  requests.listen(worker.handle);
}

final class _AudioWorker {
  _AudioWorker(this._ownerPort, this._requests);

  final SendPort _ownerPort;
  final ReceivePort _requests;
  AudioCaptureConfig? _config;
  AudioPipeline? _pipeline;
  FrameAccumulator? _frames;
  sherpa.VoiceActivityDetector? _vad;
  SignalQualityLevel? _lastQuality;
  var _nextSegmentId = 1;
  int? _openSegmentId;
  var _fileCancelled = false;
  var _playbackActive = false;

  void handle(Object? rawMessage) {
    if (rawMessage is! Map<String, Object?>) {
      return;
    }
    final requestId = rawMessage['requestId'];
    final operation = rawMessage['operation'];
    if (requestId is! int || operation is! String) {
      return;
    }
    switch (operation) {
      case 'load':
        unawaited(_load(requestId, rawMessage));
        return;
      case 'audio':
        _acceptAudio(requestId, rawMessage);
        return;
      case 'startFile':
        _startFile(requestId, rawMessage);
        return;
      case 'snippet':
        _snippet(requestId, rawMessage);
        return;
      case 'pause':
        _pause(requestId, rawMessage);
        return;
      case 'playback':
        _playback(requestId, rawMessage);
        return;
      case 'stop':
        _stop(requestId);
        return;
      case 'dispose':
        _dispose(requestId);
        return;
      default:
        _error(
          requestId,
          'unsupportedOperation',
          'Unsupported audio operation.',
        );
    }
  }

  Future<void> _load(int requestId, Map<String, Object?> message) async {
    if (_vad != null) {
      _error(requestId, 'alreadyLoaded', 'The audio worker is already loaded.');
      return;
    }
    final modelPath = message['vadModelPath'];
    final configValue = message['config'];
    if (modelPath is! String || configValue is! Map<String, Object?>) {
      _error(
        requestId,
        'invalidRequest',
        'The worker load request is invalid.',
      );
      return;
    }
    try {
      final model = File(modelPath);
      if (!model.existsSync()) {
        _error(
          requestId,
          'vadModelMissing',
          'The Silero VAD model is missing.',
        );
        return;
      }
      final digest = (await sha256.bind(model.openRead()).first).toString();
      if (digest != _sileroVadSha256) {
        _error(
          requestId,
          'vadModelCorrupt',
          'The Silero VAD checksum does not match.',
        );
        return;
      }
      final config = AudioCaptureConfig.fromMessage(configValue);
      sherpa.initBindings();
      final vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: modelPath,
            threshold: config.vadThreshold,
            minSilenceDuration: config.vadMinSilenceMs / 1000,
            minSpeechDuration: config.vadMinSpeechMs / 1000,
            windowSize: config.vadWindowSize,
            maxSpeechDuration: config.maxSegmentMs / 1000,
          ),
          sampleRate: config.sampleRate,
          debug: false,
        ),
        bufferSizeInSeconds: config.ringBufferSec.toDouble(),
      );
      _config = config;
      _pipeline = AudioPipeline(config);
      _frames = FrameAccumulator(
        config.sampleRate * config.captureFrameMs ~/ 1000,
      );
      _vad = vad;
      _success(requestId, null);
    } on Object {
      _error(requestId, 'vadLoadFailed', 'Silero VAD could not be loaded.');
    }
  }

  void _acceptAudio(int requestId, Map<String, Object?> message) {
    if (_playbackActive) {
      _success(requestId, null);
      return;
    }
    final transfer = message['pcm16'];
    if (transfer is! TransferableTypedData) {
      _error(requestId, 'invalidRequest', 'The PCM request is invalid.');
      return;
    }
    try {
      _processPcm(transfer.materialize().asUint8List());
      _success(requestId, null);
    } on AudioCaptureException catch (error) {
      _error(requestId, error.code, error.message);
    } on Object {
      _error(
        requestId,
        'audioProcessingFailed',
        'The audio frame could not be processed.',
      );
    }
  }

  void _processPcm(Uint8List pcm16) {
    final frames = _frames;
    if (frames == null) {
      throw const AudioCaptureException(
        'notLoaded',
        'The audio worker is not loaded.',
      );
    }
    final samples = pcm16ToFloat32(pcm16);
    frames.add(samples).forEach(_processFrame);
  }

  void _processFrame(Float32List frame) {
    final vad = _vad;
    final pipeline = _pipeline;
    final config = _config;
    if (vad == null || pipeline == null || config == null) {
      throw const AudioCaptureException(
        'notLoaded',
        'The audio worker is not loaded.',
      );
    }
    vad.acceptWaveform(frame);
    final output = pipeline.processFrame(frame, isSpeech: vad.isDetected());
    _emitSegmentStream(output, frame, config);
    discardCompletedVadSegments(vad);
    for (final reading in output.qualityReadings) {
      if (reading.level != _lastQuality) {
        _lastQuality = reading.level;
        final sinceSample = reading.sinceSample;
        _event(<String, Object?>{
          'kind': 'quality',
          'atMs': _samplesToMs(reading.endSample, config.sampleRate),
          'level': reading.level.name,
          'sinceMs': sinceSample == null
              ? null
              : _samplesToMs(sinceSample, config.sampleRate),
          'dbfs': reading.dbfs,
          'clippedRatio': reading.clippedRatio,
        });
      }
    }
  }

  void _startFile(int requestId, Map<String, Object?> message) {
    final path = message['path'];
    final config = _config;
    if (path is! String || config == null || _vad == null) {
      _error(requestId, 'invalidRequest', 'The file input request is invalid.');
      return;
    }
    try {
      final pcm = _readWavPcm16(path, config.sampleRate);
      _fileCancelled = false;
      _success(requestId, null);
      unawaited(_feedFileInRealTime(pcm, config));
    } on AudioCaptureException catch (error) {
      _error(requestId, error.code, error.message);
    } on FileSystemException {
      _error(requestId, 'fileReadFailed', 'The WAV file could not be read.');
    }
  }

  Future<void> _feedFileInRealTime(
    Uint8List pcm,
    AudioCaptureConfig config,
  ) async {
    final bytesPerFrame = config.streamBufferBytes;
    for (var offset = 0; offset < pcm.length && !_fileCancelled;) {
      final end = (offset + bytesPerFrame).clamp(0, pcm.length);
      _processPcm(Uint8List.sublistView(pcm, offset, end));
      offset = end;
      await Future<void>.delayed(Duration(milliseconds: config.captureFrameMs));
    }
    if (_fileCancelled) {
      return;
    }
    _flushPendingFrame();
    _flushOpenSegment();
    final pipeline = _pipeline;
    _event(<String, Object?>{
      'kind': 'fileFinished',
      'atMs': pipeline == null
          ? 0
          : _samplesToMs(pipeline.currentSample, config.sampleRate),
    });
  }

  void _snippet(int requestId, Map<String, Object?> message) {
    final pipeline = _pipeline;
    final config = _config;
    final startMs = message['startMs'];
    final endMs = message['endMs'];
    if (pipeline == null ||
        config == null ||
        startMs is! int ||
        endMs is! int) {
      _error(requestId, 'invalidRequest', 'The snippet request is invalid.');
      return;
    }
    try {
      final samples = pipeline.snippet(startMs, endMs);
      final actualStart = startMs > config.reviewSnippetPadMs
          ? startMs - config.reviewSnippetPadMs
          : 0;
      final actualEnd = endMs + config.reviewSnippetPadMs;
      _success(requestId, <String, Object?>{
        'samples': TransferableTypedData.fromList(<TypedData>[
          samples.buffer.asUint8List(
            samples.offsetInBytes,
            samples.lengthInBytes,
          ),
        ]),
        'sampleRate': config.sampleRate,
        'startMs': actualStart,
        'endMs': actualEnd,
      });
    } on AudioCaptureException catch (error) {
      _error(requestId, error.code, error.message);
    }
  }

  void _pause(int requestId, Map<String, Object?> message) {
    final reasonName = message['reason'];
    final bluetooth = message['bluetoothInput'];
    if (reasonName is! String || bluetooth is! bool) {
      _error(requestId, 'invalidRequest', 'The pause request is invalid.');
      return;
    }
    final reason = CapturePauseReason.values.asNameMap()[reasonName];
    if (reason == null) {
      _error(requestId, 'invalidPauseReason', 'The pause reason is invalid.');
      return;
    }
    _fileCancelled = true;
    _flushPendingFrame();
    _flushOpenSegment();
    final pipeline = _pipeline;
    final config = _config;
    _event(<String, Object?>{
      'kind': 'paused',
      'atMs': pipeline == null || config == null
          ? 0
          : _samplesToMs(pipeline.currentSample, config.sampleRate),
      'reason': reason.name,
      'bluetoothInput': bluetooth,
    });
    _clearAudioMemory(preserveTimeline: true);
    _success(requestId, null);
  }

  void _playback(int requestId, Map<String, Object?> message) {
    final active = message['active'];
    if (active is! bool) {
      _error(requestId, 'invalidRequest', 'The playback request is invalid.');
      return;
    }
    _playbackActive = active;
    if (active) {
      _pause(requestId, <String, Object?>{
        'reason': CapturePauseReason.playback.name,
        'bluetoothInput': false,
      });
    } else {
      _success(requestId, null);
    }
  }

  void _stop(int requestId) {
    _fileCancelled = true;
    _flushPendingFrame();
    _flushOpenSegment();
    _clearAudioMemory();
    _success(requestId, null);
  }

  void _flushPendingFrame() {
    final frame = _frames?.flush();
    if (frame != null) {
      _processFrame(frame);
    }
  }

  void _flushOpenSegment() {
    final pipeline = _pipeline;
    final config = _config;
    if (pipeline == null || config == null) {
      return;
    }
    final segment = pipeline.flush();
    if (segment != null) {
      final segmentId = _openSegmentId ?? _nextSegmentId++;
      _emitSegment(segment, config, segmentId);
      _emitSegmentClosed(
        segmentId,
        pipeline.currentSample,
        config.sampleRate,
      );
      _openSegmentId = null;
    }
  }

  void _emitSegmentStream(
    AudioPipelineOutput output,
    Float32List frame,
    AudioCaptureConfig config,
  ) {
    final openedAt = output.openedAtSample;
    if (!output.wasSegmentOpen && openedAt != null) {
      _openStreamSegment(openedAt, config.sampleRate);
    }
    final activeSegmentId = _openSegmentId;
    if (activeSegmentId != null && output.wasSegmentOpen) {
      _emitSegmentAudio(
        activeSegmentId,
        frame,
        output.frameStart,
        output.frameEnd,
        config.sampleRate,
      );
    }
    for (final segment in output.segments) {
      final segmentId = _openSegmentId ?? _nextSegmentId++;
      _emitSegment(segment, config, segmentId);
      _emitSegmentClosed(segmentId, output.frameEnd, config.sampleRate);
      _openSegmentId = null;
    }
    final openedSamples = output.openedSamples;
    final openedAudioStart = output.openedAudioStartSample;
    if (output.isSegmentOpen &&
        openedAt != null &&
        openedSamples != null &&
        openedAudioStart != null) {
      final segmentId =
          _openSegmentId ?? _openStreamSegment(openedAt, config.sampleRate);
      _emitSegmentAudio(
        segmentId,
        openedSamples,
        openedAudioStart,
        output.frameEnd,
        config.sampleRate,
      );
    }
  }

  int _openStreamSegment(int openedAt, int sampleRate) {
    final segmentId = _nextSegmentId++;
    _openSegmentId = segmentId;
    _event(<String, Object?>{
      'kind': 'segmentOpened',
      'atMs': _samplesToMs(openedAt, sampleRate),
      'segmentId': segmentId,
    });
    return segmentId;
  }

  void _emitSegmentAudio(
    int segmentId,
    Float32List samples,
    int startSample,
    int endSample,
    int sampleRate,
  ) {
    _event(<String, Object?>{
      'kind': 'segmentAudio',
      'atMs': _samplesToMs(endSample, sampleRate),
      'segmentId': segmentId,
      'samples': TransferableTypedData.fromList(<TypedData>[
        samples.buffer.asUint8List(
          samples.offsetInBytes,
          samples.lengthInBytes,
        ),
      ]),
      'sampleRate': sampleRate,
      'startMs': _samplesToMs(startSample, sampleRate),
      'endMs': _samplesToMs(endSample, sampleRate),
    });
  }

  void _emitSegmentClosed(int segmentId, int atSample, int sampleRate) {
    _event(<String, Object?>{
      'kind': 'segmentClosed',
      'atMs': _samplesToMs(atSample, sampleRate),
      'segmentId': segmentId,
    });
  }

  void _emitSegment(
    ProcessedSegment segment,
    AudioCaptureConfig config,
    int segmentId,
  ) {
    final boundary = segment.boundary;
    final samples = segment.samples;
    _event(<String, Object?>{
      'kind': 'segment',
      'atMs': _samplesToMs(boundary.audioEnd, config.sampleRate),
      'segmentId': segmentId,
      'samples': TransferableTypedData.fromList(<TypedData>[
        samples.buffer.asUint8List(
          samples.offsetInBytes,
          samples.lengthInBytes,
        ),
      ]),
      'sampleRate': config.sampleRate,
      'audioStartMs': _samplesToMs(boundary.audioStart, config.sampleRate),
      'audioEndMs': _samplesToMs(boundary.audioEnd, config.sampleRate),
      'speechStartMs': _samplesToMs(boundary.speechStart, config.sampleRate),
      'speechEndMs': _samplesToMs(boundary.speechEnd, config.sampleRate),
      'pauseBeforeMs': _samplesToMs(boundary.pauseBefore, config.sampleRate),
    });
  }

  void _clearAudioMemory({bool preserveTimeline = false}) {
    _pipeline?.clear(preserveTimeline: preserveTimeline);
    _frames?.clear();
    _vad?.clear();
    _lastQuality = null;
    _openSegmentId = null;
  }

  void _dispose(int requestId) {
    _fileCancelled = true;
    _clearAudioMemory();
    _vad?.free();
    _vad = null;
    _pipeline = null;
    _frames = null;
    _success(requestId, null);
    _requests.close();
  }

  void _event(Map<String, Object?> value) {
    _ownerPort.send(<String, Object?>{'type': 'event', ...value});
  }

  void _success(int requestId, Object? value) {
    _ownerPort.send(<String, Object?>{
      'type': 'response',
      'requestId': requestId,
      'ok': true,
      'value': value,
    });
  }

  void _error(int requestId, String code, String message) {
    _ownerPort.send(<String, Object?>{
      'type': 'response',
      'requestId': requestId,
      'ok': false,
      'errorCode': code,
      'errorMessage': message,
    });
  }
}

Uint8List _readWavPcm16(String path, int expectedSampleRate) {
  final bytes = File(path).readAsBytesSync();
  if (bytes.length < 44 ||
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
    throw const AudioCaptureException(
      'invalidWav',
      'Input is not a RIFF/WAVE file.',
    );
  }
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  int? format;
  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  Uint8List? pcm;
  while (offset + 8 <= bytes.length) {
    final id = ascii.decode(
      bytes.sublist(offset, offset + 4),
      allowInvalid: true,
    );
    final length = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    final end = start + length;
    if (end > bytes.length) {
      throw const AudioCaptureException(
        'invalidWav',
        'A WAV chunk is truncated.',
      );
    }
    if (id == 'fmt ' && length >= 16) {
      format = data.getUint16(start, Endian.little);
      channels = data.getUint16(start + 2, Endian.little);
      sampleRate = data.getUint32(start + 4, Endian.little);
      bitsPerSample = data.getUint16(start + 14, Endian.little);
    } else if (id == 'data') {
      pcm = Uint8List.sublistView(bytes, start, end);
    }
    offset = end + length.remainder(2);
  }
  if (format != 1 ||
      channels != 1 ||
      sampleRate != expectedSampleRate ||
      bitsPerSample != 16 ||
      pcm == null ||
      pcm.lengthInBytes.isOdd) {
    throw AudioCaptureException(
      'unsupportedWav',
      'WAV must be mono PCM16 at $expectedSampleRate Hz.',
    );
  }
  return pcm;
}

int _samplesToMs(int samples, int sampleRate) => samples * 1000 ~/ sampleRate;
