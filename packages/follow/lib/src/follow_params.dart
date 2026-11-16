import 'package:meta/meta.dart';

/// Parameters of following (docs/tz section 12.4, group «Следование»;
/// shipped with the model in `thresholds.json`).
@immutable
final class FollowParams {
  /// Creates parameters.
  const FollowParams({
    required this.beamSize,
    required this.maxSkip,
    required this.maxBack,
    required this.costSkip,
    required this.costBack,
    required this.costInsert,
    required this.simFloor,
    required this.openThreshold,
    required this.lostCostThreshold,
    required this.ambiguityMargin,
    required this.ngramSize,
    required this.stableConfirmations,
    required this.openDelayWords,
    required this.lostWindowWords,
  });

  /// Reads `thresholds.json` values; missing keys keep [defaults].
  ///
  /// Throws [FormatException] if a value has the wrong type.
  factory FollowParams.fromJson(Map<String, Object?> json) {
    const d = defaults;
    int i(String k, int fallback) => switch (json[k]) {
          null => fallback,
          final int v => v,
          final v => throw FormatException('"$k" must be an integer', v),
        };
    double n(String k, double fallback) => switch (json[k]) {
          null => fallback,
          final num v => v.toDouble(),
          final v => throw FormatException('"$k" must be a number', v),
        };
    return FollowParams(
      beamSize: i('beamSize', d.beamSize),
      maxSkip: i('maxSkip', d.maxSkip),
      maxBack: i('maxBack', d.maxBack),
      costSkip: n('costSkip', d.costSkip),
      costBack: n('costBack', d.costBack),
      costInsert: n('costInsert', d.costInsert),
      simFloor: n('simFloor', d.simFloor),
      openThreshold: n('openThreshold', d.openThreshold),
      lostCostThreshold: n('lostCostThreshold', d.lostCostThreshold),
      ambiguityMargin: n('ambiguityMargin', d.ambiguityMargin),
      ngramSize: i('ngramSize', d.ngramSize),
      stableConfirmations: i('stableConfirmations', d.stableConfirmations),
      openDelayWords: i('openDelayWords', d.openDelayWords),
      lostWindowWords: i('lostWindowWords', d.lostWindowWords),
    );
  }

  /// Built-in values from docs/tz 12.4 and 10.4, used until the model
  /// package provides calibrated ones.
  static const FollowParams defaults = FollowParams(
    beamSize: 5,
    maxSkip: 4,
    maxBack: 8,
    costSkip: 1,
    costBack: 0.3,
    costInsert: 1,
    simFloor: 0.4,
    openThreshold: 0.7,
    lostCostThreshold: 0.6,
    ambiguityMargin: 0.15,
    ngramSize: 3,
    stableConfirmations: 2,
    openDelayWords: 2,
    lostWindowWords: 4,
  );

  /// Hypotheses kept in the beam.
  final int beamSize;

  /// Most expected words one transition may skip.
  final int maxSkip;

  /// Farthest a transition may go back.
  final int maxBack;

  /// Cost of each skipped word.
  final double costSkip;

  /// Cost of going back.
  final double costBack;

  /// Cost of an extra heard word.
  final double costInsert;

  /// Transitions with a lower similarity are not built.
  final double simFloor;

  /// Similarity needed to reveal a word.
  final double openThreshold;

  /// Mean cost of the last [lostWindowWords] steps above which the
  /// position is lost.
  final double lostCostThreshold;

  /// Places closer in cost than this are ambiguous.
  final double ambiguityMargin;

  /// Words per n-gram in searches.
  final int ngramSize;

  /// Consecutive partial results that must agree for a word to be stable.
  final int stableConfirmations;

  /// Stable words after which a step is final even if the beam disagrees
  /// (docs/tz 10.4, «прошло ещё 2 устойчивых слова»; not yet in 12.4).
  final int openDelayWords;

  /// Steps averaged for the lost-position check (docs/tz 10.4, «последних 4
  /// слов»; not yet in 12.4).
  final int lostWindowWords;
}
