import 'dart:io';

import 'package:check/check.dart';
import 'package:contracts/contracts.dart';
import 'package:eval/src/annotation.dart';
import 'package:eval/src/asr_jsonl.dart';
import 'package:eval/src/counts.dart';
import 'package:follow/follow.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';

/// How checking runs over the corpus (task M01 + S04): the same
/// parameters as on the phone, and the versions written into every event.
@immutable
final class CheckSetup {
  /// Creates a setup.
  const CheckSetup({
    required this.params,
    required this.rulesVersion,
    required this.textVersion,
  });

  /// Check thresholds from the model's `thresholds.json` (docs/tz 12.4).
  final CheckParams params;

  /// Version of the rules and thresholds, for `CheckEvent.versions`.
  final String rulesVersion;

  /// Version of the content text, for `CheckEvent.versions`.
  final String textVersion;
}

/// One recording of the corpus: its annotation and recognition results.
@immutable
final class CorpusRecording {
  /// Creates a recording.
  const CorpusRecording({required this.annotation, required this.results});

  /// Human annotation.
  final Annotation annotation;

  /// Recognition results in the order the model produced them.
  final List<RecognitionResult> results;
}

/// Loads every `<id>.ann.json` in [directory] with its
/// `<id>.<model>.asr.jsonl`, sorted by id so runs are repeatable.
Result<List<CorpusRecording>> loadCorpus(String directory, String model) {
  final dir = Directory(directory);
  if (!dir.existsSync()) {
    return Result.error(FileSystemException('No such folder', directory));
  }
  const annSuffix = '.ann.json';
  final annFiles = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith(annSuffix))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final recordings = <CorpusRecording>[];
  for (final file in annFiles) {
    final name = p.basename(file.path);
    final id = name.substring(0, name.length - annSuffix.length);
    final asr = File(p.join(directory, '$id.$model.asr.jsonl'));
    if (!asr.existsSync()) {
      return Result.error(
        FileSystemException('No recognition results for $id', asr.path),
      );
    }
    final annotation = Annotation.parse(file.readAsStringSync());
    final results = parseAsrJsonl(asr.readAsStringSync());
    switch ((annotation, results)) {
      case (Ok(value: final a), Ok(value: final r)):
        recordings.add(CorpusRecording(annotation: a, results: r));
      case (Error(:final error), _) || (_, Error(:final error)):
        return Result.error(FormatException('$id: $error'));
    }
  }
  return Result.ok(recordings);
}

/// Runs following and, with [check], checking over one recording the way
/// the reading session does: results in their order, `check` fed with
/// each final part of the path right after `follow`, the pause between
/// speech segments given as a VAD pause, both finished at the end.
/// Deterministic. Without [check] its metrics have no data.
RecordingOutcome runRecording(
  CorpusRecording recording, {
  required QuranText text,
  required Normalizer normalizer,
  required FollowParams params,
  CheckSetup? check,
}) {
  final annotation = recording.annotation;
  final results = recording.results;
  final sessionId =
      results.isEmpty ? annotation.recordingId : results.first.sessionId;
  final follower = Follower(
    text: text,
    normalizer: normalizer,
    from: annotation.from,
    to: annotation.to,
    params: params,
  );
  final checker = check == null || results.isEmpty
      ? null
      : Checker(
          text: text,
          normalizer: normalizer.id,
          from: annotation.from,
          to: annotation.to,
          params: check.params,
          sessionId: sessionId,
          versions: ReadingVersions(
            modelId: results.first.info.modelId,
            modelVersion: results.first.info.modelVersion,
            rulesVersion: check.rulesVersion,
            textVersion: check.textVersion,
          ),
        );

  final revealed = <WordKey>{};
  final events = <CheckEvent>[];
  void take(FollowUpdate u) {
    for (final e in u.events) {
      if (e is WordRevealed && e.reason == RevealReason.heard) {
        revealed.add(e.word);
      }
    }
    if (checker != null) {
      events.addAll(checker.accept(path: u.path, jumps: u.jumps).events);
    }
  }

  RecognitionResult? lastFinal;
  for (final r in results) {
    final previous = lastFinal;
    if (checker != null &&
        previous != null &&
        r.segmentId != previous.segmentId &&
        r.audioStartMs > previous.audioEndMs) {
      events.addAll(
        checker
            .onPause(
              SpeechPause(startMs: previous.audioEndMs, endMs: r.audioStartMs),
            )
            .events,
      );
      lastFinal = null;
    }
    take(follower.accept(r));
    if (r.isFinal) lastFinal = r;
  }
  final endMs = results.isEmpty ? 0 : results.last.audioEndMs;
  take(follower.finish(sessionId: sessionId, atMs: endMs));
  if (checker != null) events.addAll(checker.finish(endMs).events);

  return RecordingOutcome(
    revealed: revealed,
    checkEvents: checker == null ? null : events,
  );
}
