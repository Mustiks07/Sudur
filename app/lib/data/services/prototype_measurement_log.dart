import 'dart:convert';

import 'package:contracts/contracts.dart';

/// JSONL-compatible timing log that deliberately excludes recognized text.
final class PrototypeMeasurementLog {
  /// Creates an empty log for [modelId].
  new({required this.modelId});

  /// Selected ASR model identifier.
  final String modelId;

  final Stopwatch _clock = Stopwatch();
  final List<Map<String, Object?>> _entries = <Map<String, Object?>>[];
  String _input = 'microphone';
  int? _sessionClockOffsetMs;

  /// Starts a fresh measurement run.
  void start({required bool usesWav}) {
    _entries.removeWhere((entry) => entry['type'] != 'MushafPageRendered');
    _input = usesWav ? 'wav' : 'microphone';
    _sessionClockOffsetMs = null;
    _clock
      ..reset()
      ..start();
  }

  /// Adds one session event without expected or recognized text.
  void addSessionEvent(SessionEvent event) {
    final receivedAtMs = _clock.elapsedMilliseconds;
    if (event is SessionStarted) {
      _sessionClockOffsetMs = receivedAtMs - event.atMs;
    }
    final sessionClockOffsetMs = _sessionClockOffsetMs;
    _entries.add(<String, Object?>{
      'type': event.runtimeType.toString(),
      'sessionAtMs': event.atMs,
      'receivedAtMs': receivedAtMs,
      if (sessionClockOffsetMs != null)
        'uiAtSessionMs': receivedAtMs - sessionClockOffsetMs,
      ..._safeEventFields(event),
    });
  }

  /// Records first-frame timing for a Mushaf page.
  void addPageRendered(int pageNumber, int elapsedMs) {
    _entries.add(<String, Object?>{
      'type': 'MushafPageRendered',
      'page': pageNumber,
      'firstFrameMs': elapsedMs,
    });
  }

  /// Serializes a readable JSON document for sharing.
  String toJson() => const JsonEncoder.withIndent('  ')
      .convert(<String, Object?>{
        'format': 1,
        'modelId': modelId,
        'input': _input,
        'events': _entries,
      });
}

Map<String, Object?> _safeEventFields(SessionEvent event) => switch (event) {
  PositionUpdate() => <String, Object?>{
    'wordKey': event.word.toString(),
    'confidence': event.confidence.name,
  },
  WordRevealed() => <String, Object?>{
    'wordKey': event.word.toString(),
    'reason': event.reason.name,
  },
  PositionLost() => <String, Object?>{
    'lastConfidentWord': event.lastConfidentWord?.toString(),
  },
  CheckEvent() => <String, Object?>{
    'eventId': event.eventId,
    'kind': event.kind.name,
    'state': event.state.name,
    'wordKeys': event.words.map((word) => word.toString()).toList(),
    'audioStartMs': event.audioStartMs,
    'audioEndMs': event.audioEndMs,
  },
  SignalQuality() => <String, Object?>{
    'level': event.level.name,
    'sinceMs': event.sinceMs,
  },
  SessionStarted() => <String, Object?>{
    'fromWordKey': event.fromWordKey.toString(),
    'toWordKey': event.toWordKey.toString(),
    'mode': event.mode.name,
    'modelId': event.versions.modelId,
    'modelVersion': event.versions.modelVersion,
    'rulesVersion': event.versions.rulesVersion,
    'textVersion': event.versions.textVersion,
  },
  HintGiven() => <String, Object?>{
    'kind': event.kind.name,
    'wordKey': event.wordKey.toString(),
  },
  CheckStateChanged() => <String, Object?>{
    'eventId': event.eventId,
    'from': event.from.name,
    'to': event.to.name,
    'reason': event.reason,
  },
  SessionFinished() => <String, Object?>{
    'words': event.words
        .map(
          (word) => <String, Object?>{
            'wordKey': word.wordKey.toString(),
            'outcome': word.outcome.name,
          },
        )
        .toList(),
    'eventIds': event.eventIds,
    'durationMs': event.durationMs,
    'audioWasSuitable': event.audioWasSuitable,
  },
};
