import 'dart:convert';

import 'package:contracts/contracts.dart';
import 'package:eval/src/metrics.dart';
import 'package:meta/meta.dart';

/// A bound on a metric value.
@immutable
final class Threshold {
  /// Creates a threshold; at least one bound must be set.
  const Threshold({this.min, this.max});

  /// Lowest passing value.
  final double? min;

  /// Highest passing value.
  final double? max;

  /// Whether [value] passes.
  bool passes(double value) =>
      (min == null || value >= min!) && // Checked for null first.
      (max == null || value <= max!); // Checked for null first.

  /// JSON form.
  Map<String, double> toJson() => {
        if (min case final m?) 'min': m,
        if (max case final m?) 'max': m,
      };
}

/// Outcome of comparing a metric with its threshold.
enum Status {
  /// The value passes.
  pass,

  /// The value fails.
  fail,

  /// No value: checking did not run or nothing to measure.
  noData;

  /// Russian label.
  String get label => switch (this) {
        pass => 'прошло',
        fail => 'не прошло',
        noData => 'нет данных',
      };
}

/// Release mode by result (docs/tz 5.3).
enum ReleaseMode {
  /// All thresholds pass.
  a('А', 'Проверка на ходу, мягкое и строгое поведение'),

  /// Precision and false alarms pass, something else does not.
  b('Б', 'Проверка после фразы, «бета», без строгого поведения'),

  /// Following passes, precision or false alarms do not (or no data).
  v('В', 'Только следование и самопроверка'),

  /// Following does not pass.
  g('Г', 'Чтение с поддержкой по видимому тексту и самопроверка');

  const ReleaseMode(this.letter, this.meaning);

  /// Cyrillic letter used in the spec.
  final String letter;

  /// What is released in this mode.
  final String meaning;
}

/// Acceptance parameters (`tools/eval/config/acceptance.json`): thresholds
/// of docs/tz 5.3, regression tolerances of 5.5, bootstrap settings. No
/// threshold lives in code.
@immutable
final class AcceptanceConfig {
  /// Creates a config.
  const AcceptanceConfig({
    required this.thresholds,
    required this.groupPrecision,
    required this.groupKeys,
    required this.normalNoise,
    required this.timeToleranceMs,
    required this.bootstrapSamples,
    required this.confidence,
    required this.seed,
    required this.maxDropPp,
  });

  /// Parses the config file.
  static Result<AcceptanceConfig> parse(String source) {
    try {
      final root = _object(jsonDecode(source), 'config');
      final thresholds = _object(root['thresholds'], 'thresholds');
      final bootstrap = _object(root['bootstrap'], 'bootstrap');
      final drops = _object(root['ciMaxDropPp'], 'ciMaxDropPp');
      return Result.ok(
        AcceptanceConfig(
          thresholds: {
            for (final m in Metric.values)
              m: _threshold(thresholds[m.name], 'thresholds.${m.name}'),
          },
          groupPrecision: _threshold(
            thresholds['groupPrecision'],
            'thresholds.groupPrecision',
          ),
          groupKeys: [
            for (final k in _list(root['groups'], 'groups'))
              _string(k, 'groups'),
          ],
          normalNoise: {
            for (final n in _list(root['normalNoise'], 'normalNoise'))
              _string(n, 'normalNoise'),
          },
          timeToleranceMs: _int(root['timeToleranceMs'], 'timeToleranceMs'),
          bootstrapSamples: _int(bootstrap['samples'], 'bootstrap.samples'),
          confidence: _double(bootstrap['confidence'], 'bootstrap.confidence'),
          seed: _int(bootstrap['seed'], 'bootstrap.seed'),
          maxDropPp: {
            for (final e in drops.entries)
              Metric.values.firstWhere(
                (m) => m.name == e.key,
                orElse: () => throw FormatException('Unknown metric', e.key),
              ): _double(e.value, 'ciMaxDropPp.${e.key}'),
          },
        ),
      );
    } on FormatException catch (e) {
      return Result.error(e);
    }
  }

  /// Threshold of every metric.
  final Map<Metric, Threshold> thresholds;

  /// Threshold of precision in each group (docs/tz КЧ-08).
  final Threshold groupPrecision;

  /// Annotation group keys reported separately (docs/tz КЧ-08).
  final List<String> groupKeys;

  /// Noise conditions of recordings of normal quality (docs/tz КЧ-06).
  final Set<String> normalNoise;

  /// Slack when matching insertions and jumps by time.
  final int timeToleranceMs;

  /// Bootstrap resamples (docs/tz КЧ-09).
  final int bootstrapSamples;

  /// Confidence level of intervals, for example 0.95.
  final double confidence;

  /// Seed of the bootstrap, so every run gives the same report.
  final int seed;

  /// Largest allowed drop against the baseline, in percentage points
  /// (docs/tz 5.5).
  final Map<Metric, double> maxDropPp;

  /// Status of [value] for [metric].
  Status statusOf(Metric metric, double? value) =>
      _status(thresholds[metric]!, value); // Every metric is parsed.

  /// Status of a group precision [value].
  Status groupStatusOf(double? value) => _status(groupPrecision, value);

  static Status _status(Threshold t, double? value) {
    if (value == null) return Status.noData;
    return t.passes(value) ? Status.pass : Status.fail;
  }
}

/// Release mode from metric statuses (docs/tz 5.3): Г if following fails;
/// В if precision or false alarms fail or have no data; А if everything
/// passes, including every group; otherwise Б.
ReleaseMode releaseMode(
  Map<Metric, Status> statuses,
  Iterable<Status> groupStatuses,
) {
  bool passes(Metric m) => statuses[m] == Status.pass;
  if (!passes(Metric.followRevealedInPlace) ||
      !passes(Metric.followRevealedNotRead)) {
    return ReleaseMode.g;
  }
  if (!passes(Metric.precision) || !passes(Metric.falseAlarmsPer1000)) {
    return ReleaseMode.v;
  }
  final all = Metric.values.every(passes) &&
      groupStatuses.every((s) => s == Status.pass);
  return all ? ReleaseMode.a : ReleaseMode.b;
}

Threshold _threshold(Object? value, String what) {
  final map = _object(value, what);
  final min = map['min'];
  final max = map['max'];
  if (min == null && max == null) {
    throw FormatException('$what needs "min" or "max"');
  }
  return Threshold(
    min: min == null ? null : _double(min, '$what.min'),
    max: max == null ? null : _double(max, '$what.max'),
  );
}

Map<String, Object?> _object(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected an object for $what', value);
}

List<Object?> _list(Object? value, String what) {
  if (value is List<Object?>) return value;
  throw FormatException('Expected a list for $what', value);
}

String _string(Object? value, String what) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected a string for $what', value);
}

int _int(Object? value, String what) {
  if (value is int) return value;
  throw FormatException('Expected an integer for $what', value);
}

double _double(Object? value, String what) {
  if (value is num) return value.toDouble();
  throw FormatException('Expected a number for $what', value);
}
