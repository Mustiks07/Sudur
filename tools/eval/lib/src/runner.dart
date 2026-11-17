import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:eval/src/annotation.dart';
import 'package:eval/src/asr_jsonl.dart';
import 'package:eval/src/counts.dart';
import 'package:follow/follow.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:quran_text/quran_text.dart';

/// Turns follow output into check events; plugged in once `check` exists
/// (task S04). `null` means checking does not run and its metrics have no
/// data.
typedef CheckStage = List<CheckEvent> Function(
  Annotation annotation,
  List<RecognitionResult> results,
  List<FollowUpdate> updates,
);

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

/// Runs following (and checking, if [check] is given) over one recording
/// the way the phone does: results in their order, the same parameters,
/// `finish` at the end. Deterministic.
RecordingOutcome runRecording(
  CorpusRecording recording, {
  required QuranText text,
  required Normalizer normalizer,
  required FollowParams params,
  CheckStage? check,
}) {
  final follower = Follower(
    text: text,
    normalizer: normalizer,
    from: recording.annotation.from,
    to: recording.annotation.to,
    params: params,
  );
  final updates = [for (final r in recording.results) follower.accept(r)];
  final last = recording.results.isEmpty ? null : recording.results.last;
  updates.add(
    follower.finish(
      sessionId: last?.sessionId ?? recording.annotation.recordingId,
      atMs: last?.audioEndMs ?? 0,
    ),
  );
  return RecordingOutcome(
    revealed: {
      for (final u in updates)
        for (final e in u.events)
          if (e is WordRevealed && e.reason == RevealReason.heard) e.word,
    },
    checkEvents: check?.call(recording.annotation, recording.results, updates),
  );
}
