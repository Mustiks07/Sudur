import 'dart:math';

import 'package:eval/src/counts.dart';
import 'package:eval/src/metrics.dart';

/// Confidence intervals by resampling **people**, not words
/// (docs/tz КЧ-09): each sample draws as many people as there are, with
/// replacement, sums their counts and computes every metric.
///
/// Returns `(low, high)` per metric; a metric that has no value in any
/// sample is left out. [random] is injected so a seed gives the same report
/// every run.
Map<Metric, (double, double)> bootstrapByPeople(
  List<Counts> perPerson, {
  required int samples,
  required double confidence,
  required Random random,
}) {
  if (perPerson.isEmpty || samples <= 0) return const {};
  final values = {for (final m in Metric.values) m: <double>[]};
  for (var s = 0; s < samples; s++) {
    var sum = const Counts(hasCheck: true);
    for (var i = 0; i < perPerson.length; i++) {
      sum += perPerson[random.nextInt(perPerson.length)];
    }
    for (final m in Metric.values) {
      if (m.valueIn(sum) case final v?) values[m]!.add(v);
    } // Every metric has a list.
  }
  final tail = (1 - confidence) / 2;
  return {
    for (final MapEntry(key: m, value: v) in values.entries)
      if (v.isNotEmpty) m: _interval(v..sort(), tail),
  };
}

(double, double) _interval(List<double> sorted, double tail) {
  final last = sorted.length - 1;
  return (
    sorted[(tail * last).floor()],
    sorted[((1 - tail) * last).ceil()],
  );
}
