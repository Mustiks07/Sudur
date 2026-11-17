// Measures building search keys and indexes for the whole Quran, and the
// cost of searches, on this machine. Run from the repository root:
//
//   dart compile exe packages/quran_text/tool/benchmark.dart -o /tmp/qt
//   /tmp/qt packages/testing/fixtures/quran_text.json
//
// Results go to the package README.
import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:quran_text/quran_text.dart';

void main(List<String> args) {
  final path =
      args.isEmpty ? 'packages/testing/fixtures/quran_text.json' : args.first;
  int mb() => ProcessInfo.currentRss >> 20;
  final out = StringBuffer();
  final rss0 = mb();
  final sw = Stopwatch()..start();
  final words = switch (QuranTextJsonSource(
    File(path).readAsStringSync(),
  ).loadWords()) {
    Ok(:final value) => value,
    Error(:final error) => throw error,
  };
  out.writeln('load ${words.length} words: ${sw.elapsedMilliseconds} ms');

  sw.reset();
  const normalizer = Normalizer.builtIn;
  final keys = [for (final w in words) normalizer.keyOf(w.text)];
  out.writeln('keys: ${sw.elapsedMilliseconds} ms');

  sw.reset();
  final text = InMemoryQuranText(
    words: words,
    normalizers: [normalizer],
    params: SearchParams.defaults,
    cachedKeys: {normalizer.id: keys},
  );
  out
    ..writeln('index from cached keys: ${sw.elapsedMilliseconds} ms')
    ..writeln('memory: $rss0 MB at start, ${mb()} MB with text and index');

  final all = text.keysFor(normalizer.id);
  const lookups = 200;
  sw.reset();
  for (var i = 0; i < lookups; i++) {
    final j = (i * 389) % (all.length - 3);
    text.findSequence(all.sublist(j, j + 3), normalizer: normalizer.id);
  }
  out.writeln(
    'findSequence (3 words): '
    '${(sw.elapsedMicroseconds / lookups / 1000).toStringAsFixed(2)} ms',
  );
  sw.reset();
  for (var i = 0; i < lookups; i++) {
    final j = (i * 389) % (all.length - 3);
    text.findSimilar(
      all.sublist(j, j + 3),
      normalizer: normalizer.id,
      minSimilarity: 0.4,
      maxMeanCost: 0.6,
    );
  }
  out.writeln(
    'findSimilar (3 words): '
    '${(sw.elapsedMicroseconds / lookups / 1000).toStringAsFixed(2)} ms',
  );
  stdout.write(out);
}
