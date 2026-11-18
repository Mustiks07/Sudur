import 'dart:math';

import 'package:eval/src/acceptance.dart';
import 'package:eval/src/annotation.dart';
import 'package:eval/src/bootstrap.dart';
import 'package:eval/src/counts.dart';
import 'package:eval/src/metrics.dart';
import 'package:meta/meta.dart';

/// Version of the report JSON.
const int reportFormat = 1;

/// Changes are rounded to this many decimals, so that floating-point noise
/// (1.0 − 0.99 = 0.0100…09) does not turn an allowed drop into a failure.
const int changeDecimals = 6;

double _round(double value) {
  final factor = pow(10, changeDecimals);
  return (value * factor).round() / factor;
}

/// One metric in the report.
@immutable
final class MetricResult {
  /// Creates a result.
  const MetricResult({required this.value, required this.status});

  /// Value with interval.
  final MetricValue value;

  /// Against the threshold.
  final Status status;
}

/// Evaluation report (docs/tz 12.6 «Отчёт»).
@immutable
final class Report {
  /// Creates a report.
  const Report({
    required this.model,
    required this.recordings,
    required this.people,
    required this.metrics,
    required this.groups,
    required this.groupStatuses,
    required this.groupRecordings,
    required this.mode,
    required this.thresholds,
    this.baseline,
  });

  /// Thresholds the metrics were compared with.
  final Map<Metric, Threshold> thresholds;

  /// Model id the recognition results came from.
  final String model;

  /// Number of recordings.
  final int recordings;

  /// Number of different people.
  final int people;

  /// Overall metrics.
  final Map<Metric, MetricResult> metrics;

  /// Metrics per group key and group value (docs/tz КЧ-08).
  final Map<String, Map<String, Map<Metric, MetricValue>>> groups;

  /// Recordings per group key and value; 0 for a required value the corpus
  /// lacks.
  final Map<String, Map<String, int>> groupRecordings;

  /// Required group values without any recording, as `key=value`.
  List<String> get missingGroups => [
        for (final MapEntry(:key, :value) in groupRecordings.entries)
          for (final MapEntry(key: v, value: n) in value.entries)
            if (n == 0) '$key=$v',
      ];

  /// Precision status per group key and value.
  final Map<String, Map<String, Status>> groupStatuses;

  /// Release mode (docs/tz 5.3).
  final ReleaseMode mode;

  /// Metric values of the previous report, if compared.
  final Map<Metric, double?>? baseline;

  /// Whether every threshold passed.
  bool get passed => mode == ReleaseMode.a;

  /// Difference to [baseline] in percentage points for shares, in units for
  /// "per 1000"; `null` where either side has no data.
  Map<Metric, double?> get changes => {
        for (final m in Metric.values)
          m: switch ((metrics[m]?.value.value, baseline?[m])) {
            (final now?, final before?) =>
              _round((now - before) * (m.isShare ? 100 : 1)),
            _ => null,
          },
      };

  /// Regression check against [baseline] (docs/tz 5.5): returns a message
  /// for every metric that dropped more than allowed by [config].
  List<String> regressions(AcceptanceConfig config) {
    final c = changes;
    return [
      for (final MapEntry(key: m, value: limit) in config.maxDropPp.entries)
        if (c[m] case final change? when -change > limit)
          _dropMessage(m, -change, limit),
    ];
  }

  static String _dropMessage(Metric m, double drop, double limit) =>
      '${m.code} ${m.title}: упало на ${drop.toStringAsFixed(2)} п. п. '
      '(допустимо $limit)';

  /// JSON form; [baselineValuesFromJson] reads it back for comparisons.
  Map<String, Object?> toJson() => {
        'format': reportFormat,
        'model': model,
        'recordings': recordings,
        'people': people,
        'releaseMode': mode.letter,
        'thresholds': {
          for (final MapEntry(key: m, value: t) in thresholds.entries)
            m.name: t.toJson(),
        },
        'passed': passed,
        'metrics': {
          for (final MapEntry(key: m, value: r) in metrics.entries)
            m.name: {
              'code': m.code,
              ..._valueJson(r.value),
              'status': r.status.name,
              if (changes[m] case final c?) 'change': c,
            },
        },
        'missingGroups': missingGroups,
        'groups': {
          for (final MapEntry(:key, value: byValue) in groups.entries)
            key: {
              for (final MapEntry(key: value, value: values) in byValue.entries)
                value: {
                  'recordings': groupRecordings[key]?[value] ?? 0,
                  'precisionStatus': groupStatuses[key]?[value]?.name,
                  for (final MapEntry(key: m, value: v) in values.entries)
                    m.name: _valueJson(v),
                },
            },
        },
      };

  /// Markdown report in Russian.
  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('# Отчёт оценки: $model')
      ..writeln()
      ..writeln('Записей: $recordings, людей: $people.')
      ..writeln()
      ..writeln(
        missingGroups.isEmpty
            ? 'Все обязательные группы КЧ-08 представлены.'
            : '**Нет записей в обязательных группах КЧ-08:** '
                '${missingGroups.join(', ')} — режим «А» невозможен.',
      )
      ..writeln()
      ..writeln(
        '**Итог: ${passed ? 'прошло' : 'не прошло'}.** '
        'Режим выпуска: **${mode.letter}** — ${mode.meaning}.',
      )
      ..writeln()
      ..writeln('| ID | Показатель | Значение | Интервал | Порог | Итог |'
          '${baseline == null ? '' : ' Изменение |'}')
      ..writeln('|---|---|---|---|---|---|${baseline == null ? '' : '---|'}');
    for (final MapEntry(key: m, value: r) in metrics.entries) {
      final change = changes[m];
      b.writeln(
        '| ${m.code} | ${m.title} | ${_format(m, r.value.value)} '
        '(${r.value.numerator}/${r.value.denominator}) | '
        '${_interval(m, r.value)} | ${_thresholdText(m)} | '
        '${r.status.label} |'
        '${baseline == null ? '' : ' ${_change(m, change)} |'}',
      );
    }
    for (final MapEntry(:key, value: byValue) in groups.entries) {
      b
        ..writeln()
        ..writeln('## Группа: $key')
        ..writeln()
        ..writeln('| Значение | Записей | ${[
          for (final m in Metric.values) m.column,
        ].join(' | ')} | Точность ≥ порога |')
        ..writeln('|---|---|${[for (final _ in Metric.values) '---'].join('|')}'
            '|---|');
      for (final MapEntry(key: value, value: values) in byValue.entries) {
        b.writeln(
          '| $value | ${groupRecordings[key]?[value] ?? 0} | ${[
            for (final m in Metric.values) _format(m, values[m]?.value),
          ].join(' | ')} | ${groupStatuses[key]?[value]?.label ?? '—'} |',
        );
      }
    }
    b
      ..writeln()
      ..writeln(
        'Интервалы — бутстреп по людям (КЧ-09). Значения проверки ошибок '
        '«нет данных», пока `check` не участвует в прогоне.',
      );
    return b.toString();
  }

  String _thresholdText(Metric m) {
    final t = thresholds[m];
    if (t == null) return '—';
    return [
      if (t.min case final v?) '≥ ${_format(m, v)}',
      if (t.max case final v?) '≤ ${_format(m, v)}',
    ].join(', ');
  }

  static String _change(Metric m, double? change) {
    if (change == null) return '—';
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}${m.isShare ? ' п. п.' : ''}';
  }

  static String _interval(Metric m, MetricValue v) {
    if (v.ciLow == null || v.ciHigh == null) return '—';
    return '${_format(m, v.ciLow)}…${_format(m, v.ciHigh)}';
  }

  static String _format(Metric m, double? v) {
    if (v == null) return 'нет данных';
    return m.isShare
        ? '${(v * 100).toStringAsFixed(1)}%'
        : v.toStringAsFixed(2);
  }

  static Map<String, Object?> _valueJson(MetricValue v) => {
        'value': v.value,
        'numerator': v.numerator,
        'denominator': v.denominator,
        'ciLow': v.ciLow,
        'ciHigh': v.ciHigh,
      };
}

/// Metric values of a report written by [Report.toJson].
Map<Metric, double?> baselineValuesFromJson(Map<String, Object?> json) {
  final metrics = json['metrics'];
  if (metrics is! Map<String, Object?>) {
    throw const FormatException('Report has no "metrics"');
  }
  return {
    for (final m in Metric.values)
      m: switch (metrics[m.name]) {
        {'value': final num v} => v.toDouble(),
        _ => null,
      },
  };
}

/// One evaluated recording.
typedef EvaluatedRecording = ({
  Annotation annotation,
  RecordingOutcome outcome,
});

/// Builds the report from evaluated recordings (docs/tz 5.3, 12.6).
Report buildReport({
  required String model,
  required List<EvaluatedRecording> recordings,
  required AcceptanceConfig config,
  Map<Metric, double?>? baseline,
  CorrectionWindow? window,
}) {
  Counts countsOf(EvaluatedRecording r) => Counts.of(
        r.annotation,
        r.outcome,
        normalNoise: config.normalNoise,
        timeToleranceMs: config.timeToleranceMs,
        window: window,
      );

  final byPerson = <String, Counts>{};
  for (final r in recordings) {
    final id = r.annotation.speaker.id;
    byPerson[id] = (byPerson[id] ?? const Counts(hasCheck: true)) + countsOf(r);
  }
  final people = byPerson.keys.toList()..sort();
  final perPerson = [for (final p in people) byPerson[p]!]; // Keys above.

  final total = Counts.sum(perPerson);
  final intervals = bootstrapByPeople(
    perPerson,
    samples: config.bootstrapSamples,
    confidence: config.confidence,
    random: Random(config.seed),
  );
  MetricValue valueOf(Metric m, Counts c, {(double, double)? ci}) {
    final (n, d) = m.ratioIn(c);
    return MetricValue(
      value: m.valueIn(c),
      numerator: n,
      denominator: d,
      ciLow: ci?.$1,
      ciHigh: ci?.$2,
    );
  }

  final metrics = {
    for (final m in Metric.values)
      m: MetricResult(
        value: valueOf(m, total, ci: intervals[m]),
        status: config.statusOf(m, m.valueIn(total)),
      ),
  };

  final groups = <String, Map<String, Map<Metric, MetricValue>>>{};
  final groupStatuses = <String, Map<String, Status>>{};
  final groupRecordings = <String, Map<String, int>>{};
  for (final MapEntry(:key, value: required) in config.requiredGroups.entries) {
    // Required values start empty: without recordings they have no data,
    // and a group without data keeps the release mode below А (КЧ-08).
    final byValue = <String, Counts>{
      for (final v in required) v: const Counts(hasCheck: true),
    };
    final counted = <String, int>{for (final v in required) v: 0};
    for (final r in recordings) {
      final value = r.annotation.groups[key];
      if (value == null) continue;
      byValue[value] =
          (byValue[value] ?? const Counts(hasCheck: true)) + countsOf(r);
      counted[value] = (counted[value] ?? 0) + 1;
    }
    groupRecordings[key] = counted;
    final values = byValue.keys.toList()..sort();
    groups[key] = {
      for (final v in values)
        v: {for (final m in Metric.values) m: valueOf(m, byValue[v]!)},
    }; // Keys above.
    groupStatuses[key] = {
      for (final v in values)
        v: config.groupStatusOf(Metric.precision.valueIn(byValue[v]!)),
    }; // Keys above.
  }

  return Report(
    model: model,
    recordings: recordings.length,
    people: people.length,
    metrics: metrics,
    groups: groups,
    groupStatuses: groupStatuses,
    groupRecordings: groupRecordings,
    thresholds: config.thresholds,
    mode: releaseMode(
      {for (final e in metrics.entries) e.key: e.value.status},
      groupStatuses.values.expand((s) => s.values),
    ),
    baseline: baseline,
  );
}
