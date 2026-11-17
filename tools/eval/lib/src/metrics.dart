import 'package:eval/src/counts.dart';
import 'package:meta/meta.dart';

/// Metrics of docs/tz 5.3.
enum Metric {
  /// КЧ-01: words read correctly that were revealed.
  followRevealedInPlace('КЧ-01', 'Следование: открыто на своём месте'),

  /// КЧ-02: revealed words that were not read, among revealed words.
  followRevealedNotRead('КЧ-02', 'Следование: открыто непрочитанное'),

  /// КЧ-03: precision of confirmed mistakes.
  precision('КЧ-03', 'Точность подтверждённых ошибок', needsCheck: true),

  /// КЧ-04: recall of omissions.
  omissionRecall('КЧ-04', 'Полнота пропусков', needsCheck: true),

  /// КЧ-04: recall of substitutions.
  substitutionRecall('КЧ-04', 'Полнота замен', needsCheck: true),

  /// КЧ-05: false alarms per 1000 correctly read words.
  falseAlarmsPer1000(
    'КЧ-05',
    'Ложные тревоги на 1000 правильных слов',
    needsCheck: true,
    scale: 1000,
  ),

  /// КЧ-06: words not verified, on recordings of normal quality.
  refusalRate('КЧ-06', 'Отказы («не удалось проверить»)', needsCheck: true),

  /// КЧ-07: self-corrections recognized as corrections.
  selfCorrectionRecall('КЧ-07', 'Самоисправления распознаны', needsCheck: true);

  const Metric(
    this.code,
    this.title, {
    this.needsCheck = false,
    this.scale = 1,
  });

  /// Requirement id.
  final String code;

  /// Russian title for reports.
  final String title;

  /// Whether the metric needs check events.
  final bool needsCheck;

  /// 1 for shares, 1000 for "per 1000 words".
  final int scale;

  /// Column header for tables: the code, plus the kind for КЧ-04.
  String get column => switch (this) {
        omissionRecall => '$code (пропуски)',
        substitutionRecall => '$code (замены)',
        _ => code,
      };

  /// Whether the value is a share shown in percent.
  bool get isShare => scale == 1;

  /// Numerator and denominator in [c].
  (int, int) ratioIn(Counts c) => switch (this) {
        followRevealedInPlace => (c.revealedReadCleanly, c.readCleanly),
        followRevealedNotRead => (c.revealedNotRead, c.revealed),
        precision => (c.confirmedTrue, c.confirmed),
        omissionRecall => (c.omittedFound, c.omitted),
        substitutionRecall => (c.substitutedFound, c.substituted),
        falseAlarmsPer1000 => (c.falseAlarms, c.readCleanly),
        refusalRate => (c.normalUnverified, c.normalWords),
        selfCorrectionRecall => (c.selfCorrectedFound, c.selfCorrected),
      };

  /// Value in [c], or `null` when there is no data: checking did not run,
  /// or the denominator is zero (for example, no mistakes at all).
  double? valueIn(Counts c) {
    if (needsCheck && !c.hasCheck) return null;
    final (n, d) = ratioIn(c);
    if (d == 0) return null;
    return n / d * scale;
  }
}

/// A metric value with its bootstrap confidence interval.
@immutable
final class MetricValue {
  /// Creates a value.
  const MetricValue({
    required this.value,
    required this.numerator,
    required this.denominator,
    this.ciLow,
    this.ciHigh,
  });

  /// The value, or `null` for "no data".
  final double? value;

  /// Numerator of the pooled ratio.
  final int numerator;

  /// Denominator of the pooled ratio.
  final int denominator;

  /// Lower end of the interval, if computed.
  final double? ciLow;

  /// Upper end of the interval, if computed.
  final double? ciHigh;
}
