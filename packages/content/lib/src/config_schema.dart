// Generated from the parameter tables of docs/tz 12.4 (see README);
// test/config_defaults_test.dart checks every value against the spec.
// `fromValues` only runs on values checked by `parseConfigValues`: the
// `!` and casts there cannot fail.

import 'package:meta/meta.dart';

/// Kind of a config value.
enum ParamKind {
  /// A whole number.
  integer,

  /// A number.
  number,

  /// true or false.
  boolean,

  /// A non-empty ascending list of whole numbers.
  integerList,

  /// Three ascending numbers.
  numberTriple,

  /// `{"min": a, "max": b}` with a ≤ b.
  range,
}

/// One parameter: kind, allowed range and built-in value.
@immutable
final class ParamSpec {
  /// Creates a spec.
  const ParamSpec(
    this.name,
    this.kind,
    this.defaultValue, {
    this.min,
    this.max,
  });

  /// Name in the config file.
  final String name;

  /// Kind of value.
  final ParamKind kind;

  /// Built-in value (docs/tz 12.4), as in JSON.
  final Object defaultValue;

  /// Smallest allowed value (each element for lists and ranges).
  final double? min;

  /// Largest allowed value.
  final double? max;
}

/// Sections of the config file and their parameters (docs/tz 12.4 without
/// the model thresholds, which ship with the model, РС-02). The limits are
/// sanity bounds: a value outside is a broken file, not a tuning.
const Map<String, List<ParamSpec>> configSchema = {
  'audio': [
    ParamSpec('ringBufferSec', ParamKind.integer, 30, min: 1, max: 300),
    ParamSpec('preRollMs', ParamKind.integer, 300, min: 0, max: 5000),
    ParamSpec('postRollMs', ParamKind.integer, 300, min: 0, max: 5000),
    ParamSpec(
      'segmentEndPauseMs',
      ParamKind.integer,
      700,
      min: 100,
      max: 10000,
    ),
    ParamSpec(
      'maxSegmentMs',
      ParamKind.integer,
      15000,
      min: 1000,
      max: 120000,
    ),
    ParamSpec(
      'reviewSnippetPadMs',
      ParamKind.integer,
      3000,
      min: 0,
      max: 30000,
    ),
    ParamSpec('quietDbfs', ParamKind.number, -42.0, min: -120, max: 0),
    ParamSpec('noisyDbfs', ParamKind.number, -35.0, min: -120, max: 0),
    ParamSpec('clippingRatio', ParamKind.number, 0.01, min: 0, max: 1),
    ParamSpec('signalHoldMs', ParamKind.integer, 3000, min: 0, max: 60000),
  ],
  'recognition': [
    ParamSpec('asrThreads', ParamKind.integer, 2, min: 1, max: 16),
    ParamSpec(
      'partialIntervalMs',
      ParamKind.integer,
      500,
      min: 100,
      max: 5000,
    ),
    ParamSpec(
      'maxPartialWindowMs',
      ParamKind.integer,
      8000,
      min: 1000,
      max: 60000,
    ),
    ParamSpec('deviceTestSmallMax', ParamKind.number, 0.3, min: 0, max: 10),
    ParamSpec('deviceTestTinyMax', ParamKind.number, 0.6, min: 0, max: 10),
  ],
  'plan': [
    ParamSpec('newShare', ParamKind.number, 0.2, min: 0, max: 1),
    ParamSpec('recentShare', ParamKind.number, 0.3, min: 0, max: 1),
    ParamSpec('oldShare', ParamKind.number, 0.5, min: 0, max: 1),
    ParamSpec('hardSpotMaxShare', ParamKind.number, 0.25, min: 0, max: 1),
    ParamSpec('recentDays', ParamKind.integer, 30, min: 1, max: 365),
    ParamSpec(
      'recentLadderDays',
      ParamKind.integerList,
      [1, 2, 4, 7],
      min: 1,
      max: 365,
    ),
    ParamSpec('desiredRetention', ParamKind.number, 0.9, min: 0.5, max: 0.999),
    ParamSpec('breakDays', ParamKind.integer, 7, min: 1, max: 365),
    ParamSpec(
      'diagnosticSize',
      ParamKind.range,
      {'min': 3, 'max': 5},
      min: 1,
      max: 50,
    ),
    ParamSpec('afterBreakNewFactor', ParamKind.number, 0.5, min: 0, max: 1),
    ParamSpec('afterBreakDays', ParamKind.integer, 7, min: 0, max: 365),
    ParamSpec(
      'defaultSecondsPerWord',
      ParamKind.number,
      1.0,
      min: 0.1,
      max: 10,
    ),
    ParamSpec('speedWindow', ParamKind.integer, 10, min: 1, max: 100),
    ParamSpec('debtLimitFactor', ParamKind.number, 1.0, min: 0, max: 10),
    ParamSpec('passageMaxAyahs', ParamKind.integer, 5, min: 1, max: 50),
    ParamSpec(
      'stepMultipliers',
      ParamKind.numberTriple,
      [1.3, 3.0, 8.0],
      min: 1,
      max: 100,
    ),
    ParamSpec('learnListenRepeats', ParamKind.integer, 3, min: 0, max: 20),
    ParamSpec(
      'learnSupportedRepeats',
      ParamKind.integer,
      2,
      min: 0,
      max: 20,
    ),
  ],
  'other': [
    ParamSpec('quizPassPercent', ParamKind.number, 80.0, min: 0, max: 100),
    ParamSpec(
      'skillReviewQuestions',
      ParamKind.integer,
      3,
      min: 1,
      max: 20,
    ),
    ParamSpec(
      'listenRepeatPauseFactor',
      ParamKind.number,
      1.2,
      min: 0,
      max: 10,
    ),
    ParamSpec(
      'freeVoiceMinutesPerDay',
      ParamKind.integer,
      10,
      min: 0,
      max: 1440,
    ),
    ParamSpec('trialDays', ParamKind.integer, 7, min: 0, max: 365),
    ParamSpec('offlineGraceDays', ParamKind.integer, 14, min: 0, max: 365),
    ParamSpec(
      'uploadQueueMaxMb',
      ParamKind.integer,
      200,
      min: 0,
      max: 10000,
    ),
    ParamSpec('uploadWifiOnly', ParamKind.boolean, true),
    ParamSpec('opusBitrateKbps', ParamKind.integer, 16, min: 6, max: 510),
    ParamSpec('maxRemindersPerDay', ParamKind.integer, 2, min: 0, max: 24),
    ParamSpec('pageFontWindow', ParamKind.integer, 3, min: 0, max: 604),
    ParamSpec(
      'manifestCheckHours',
      ParamKind.integer,
      24,
      min: 1,
      max: 720,
    ),
  ],
};

/// Звук: `audio_capture` (docs/tz 10.2).
@immutable
final class AudioConfig {
  /// Creates the section.
  const AudioConfig({
    required this.ringBufferSec,
    required this.preRollMs,
    required this.postRollMs,
    required this.segmentEndPauseMs,
    required this.maxSegmentMs,
    required this.reviewSnippetPadMs,
    required this.quietDbfs,
    required this.noisyDbfs,
    required this.clippingRatio,
    required this.signalHoldMs,
  });

  /// Reads checked values of section `audio`.
  factory AudioConfig.fromValues(Map<String, Object> v) => AudioConfig(
        ringBufferSec: v['ringBufferSec']! as int,
        preRollMs: v['preRollMs']! as int,
        postRollMs: v['postRollMs']! as int,
        segmentEndPauseMs: v['segmentEndPauseMs']! as int,
        maxSegmentMs: v['maxSegmentMs']! as int,
        reviewSnippetPadMs: v['reviewSnippetPadMs']! as int,
        quietDbfs: (v['quietDbfs']! as num).toDouble(),
        noisyDbfs: (v['noisyDbfs']! as num).toDouble(),
        clippingRatio: (v['clippingRatio']! as num).toDouble(),
        signalHoldMs: v['signalHoldMs']! as int,
      );

  /// Built-in values (docs/tz 12.4).
  static const AudioConfig defaults = AudioConfig(
    ringBufferSec: 30,
    preRollMs: 300,
    postRollMs: 300,
    segmentEndPauseMs: 700,
    maxSegmentMs: 15000,
    reviewSnippetPadMs: 3000,
    quietDbfs: -42,
    noisyDbfs: -35,
    clippingRatio: 0.01,
    signalHoldMs: 3000,
  );

  /// Ring buffer length, s. `ringBufferSec`, 10.2.
  final int ringBufferSec;

  /// Audio kept before speech starts, ms. `preRollMs`, 10.2.
  final int preRollMs;

  /// Audio kept after speech ends, ms. `postRollMs`, 10.2.
  final int postRollMs;

  /// Pause that closes a segment, ms. `segmentEndPauseMs`, 10.2.
  final int segmentEndPauseMs;

  /// Longest segment, ms. `maxSegmentMs`, 10.2.
  final int maxSegmentMs;

  /// Audio around a mistake kept for review, ms. `reviewSnippetPadMs`, ЗВ-02.
  final int reviewSnippetPadMs;

  /// Below this level the signal is too quiet, dBFS. `quietDbfs`, 10.2.
  final double quietDbfs;

  /// Noise floor above this is too noisy, dBFS. `noisyDbfs`, 10.2.
  final double noisyDbfs;

  /// Share of clipped samples that marks clipping. `clippingRatio`, 10.2.
  final double clippingRatio;

  /// How long a signal state holds before it changes, ms. `signalHoldMs`, 10.2.
  final int signalHoldMs;
}

/// Распознавание, не привязанное к модели: `asr_sherpa` (10.3).
@immutable
final class RecognitionConfig {
  /// Creates the section.
  const RecognitionConfig({
    required this.asrThreads,
    required this.partialIntervalMs,
    required this.maxPartialWindowMs,
    required this.deviceTestSmallMax,
    required this.deviceTestTinyMax,
  });

  /// Reads checked values of section `recognition`.
  factory RecognitionConfig.fromValues(Map<String, Object> v) =>
      RecognitionConfig(
        asrThreads: v['asrThreads']! as int,
        partialIntervalMs: v['partialIntervalMs']! as int,
        maxPartialWindowMs: v['maxPartialWindowMs']! as int,
        deviceTestSmallMax: (v['deviceTestSmallMax']! as num).toDouble(),
        deviceTestTinyMax: (v['deviceTestTinyMax']! as num).toDouble(),
      );

  /// Built-in values (docs/tz 12.4).
  static const RecognitionConfig defaults = RecognitionConfig(
    asrThreads: 2,
    partialIntervalMs: 500,
    maxPartialWindowMs: 8000,
    deviceTestSmallMax: 0.3,
    deviceTestTinyMax: 0.6,
  );

  /// Recognizer threads. `asrThreads`, 10.3.
  final int asrThreads;

  /// Interval of partial results, ms. `partialIntervalMs`, 10.3.
  final int partialIntervalMs;

  /// Longest audio window of a partial result, ms. `maxPartialWindowMs`, 10.3.
  final int maxPartialWindowMs;

  /// Device test: real-time factor up to which the small model runs.
  /// `deviceTestSmallMax`, 10.3.
  final double deviceTestSmallMax;

  /// Device test: real-time factor up to which the tiny model runs.
  /// `deviceTestTinyMax`, 10.3.
  final double deviceTestTinyMax;
}

/// План: `planner` (11.1).
@immutable
final class PlanConfig {
  /// Creates the section.
  const PlanConfig({
    required this.newShare,
    required this.recentShare,
    required this.oldShare,
    required this.hardSpotMaxShare,
    required this.recentDays,
    required this.recentLadderDays,
    required this.desiredRetention,
    required this.breakDays,
    required this.diagnosticSize,
    required this.afterBreakNewFactor,
    required this.afterBreakDays,
    required this.defaultSecondsPerWord,
    required this.speedWindow,
    required this.debtLimitFactor,
    required this.passageMaxAyahs,
    required this.stepMultipliers,
    required this.learnListenRepeats,
    required this.learnSupportedRepeats,
  });

  /// Reads checked values of section `plan`.
  factory PlanConfig.fromValues(Map<String, Object> v) => PlanConfig(
        newShare: (v['newShare']! as num).toDouble(),
        recentShare: (v['recentShare']! as num).toDouble(),
        oldShare: (v['oldShare']! as num).toDouble(),
        hardSpotMaxShare: (v['hardSpotMaxShare']! as num).toDouble(),
        recentDays: v['recentDays']! as int,
        recentLadderDays:
            List<int>.unmodifiable(v['recentLadderDays']! as List<Object?>),
        desiredRetention: (v['desiredRetention']! as num).toDouble(),
        breakDays: v['breakDays']! as int,
        diagnosticSize: _range(v['diagnosticSize']!),
        afterBreakNewFactor: (v['afterBreakNewFactor']! as num).toDouble(),
        afterBreakDays: v['afterBreakDays']! as int,
        defaultSecondsPerWord: (v['defaultSecondsPerWord']! as num).toDouble(),
        speedWindow: v['speedWindow']! as int,
        debtLimitFactor: (v['debtLimitFactor']! as num).toDouble(),
        passageMaxAyahs: v['passageMaxAyahs']! as int,
        stepMultipliers: List<double>.unmodifiable([
          for (final x in v['stepMultipliers']! as List<Object?>)
            (x! as num).toDouble(),
        ]),
        learnListenRepeats: v['learnListenRepeats']! as int,
        learnSupportedRepeats: v['learnSupportedRepeats']! as int,
      );

  /// Built-in values (docs/tz 12.4).
  static const PlanConfig defaults = PlanConfig(
    newShare: 0.2,
    recentShare: 0.3,
    oldShare: 0.5,
    hardSpotMaxShare: 0.25,
    recentDays: 30,
    recentLadderDays: [1, 2, 4, 7],
    desiredRetention: 0.9,
    breakDays: 7,
    diagnosticSize: (min: 3, max: 5),
    afterBreakNewFactor: 0.5,
    afterBreakDays: 7,
    defaultSecondsPerWord: 1,
    speedWindow: 10,
    debtLimitFactor: 1,
    passageMaxAyahs: 5,
    stepMultipliers: [1.3, 3.0, 8.0],
    learnListenRepeats: 3,
    learnSupportedRepeats: 2,
  );

  /// Share of the budget for new material. `newShare`, 11.1.
  final double newShare;

  /// Share for recent material. `recentShare`, 11.1.
  final double recentShare;

  /// Share for old material. `oldShare`, 11.1.
  final double oldShare;

  /// Most of the budget hard spots may take. `hardSpotMaxShare`, 11.1.
  final double hardSpotMaxShare;

  /// Days a passage stays recent. `recentDays`, 11.1.
  final int recentDays;

  /// Review days of recent material, ascending. `recentLadderDays`, 11.1.
  final List<int> recentLadderDays;

  /// FSRS desired retention. `desiredRetention`, 11.1.
  final double desiredRetention;

  /// Days without practice that count as a break. `breakDays`, 3.5.
  final int breakDays;

  /// Passages in the diagnostic after a break: min and max.
  /// `diagnosticSize`, ВЗ-02.
  final ({int min, int max}) diagnosticSize;

  /// Factor of new material after a break. `afterBreakNewFactor`, 3.5.
  final double afterBreakNewFactor;

  /// Days the factor holds after a break. `afterBreakDays`, 3.5.
  final int afterBreakDays;

  /// Reading time per word before the own speed is known, s.
  /// `defaultSecondsPerWord`, 11.1.
  final double defaultSecondsPerWord;

  /// Attempts the own speed is averaged over. `speedWindow`, 11.1.
  final int speedWindow;

  /// Review debt limit as a factor of the daily budget.
  /// `debtLimitFactor`, 11.1.
  final double debtLimitFactor;

  /// Most ayahs in a default passage. `passageMaxAyahs`, 4.8.
  final int passageMaxAyahs;

  /// Interval multipliers of the steps, ascending. `stepMultipliers`, 11.1.
  final List<double> stepMultipliers;

  /// Listen repeats when a passage is learned. `learnListenRepeats`, ЗН.
  final int learnListenRepeats;

  /// Supported readings when a passage is learned. `learnSupportedRepeats`, ЗН.
  final int learnSupportedRepeats;
}

/// Прочее.
@immutable
final class OtherConfig {
  /// Creates the section.
  const OtherConfig({
    required this.quizPassPercent,
    required this.skillReviewQuestions,
    required this.listenRepeatPauseFactor,
    required this.freeVoiceMinutesPerDay,
    required this.trialDays,
    required this.offlineGraceDays,
    required this.uploadQueueMaxMb,
    required this.uploadWifiOnly,
    required this.opusBitrateKbps,
    required this.maxRemindersPerDay,
    required this.pageFontWindow,
    required this.manifestCheckHours,
  });

  /// Reads checked values of section `other`.
  factory OtherConfig.fromValues(Map<String, Object> v) => OtherConfig(
        quizPassPercent: (v['quizPassPercent']! as num).toDouble(),
        skillReviewQuestions: v['skillReviewQuestions']! as int,
        listenRepeatPauseFactor:
            (v['listenRepeatPauseFactor']! as num).toDouble(),
        freeVoiceMinutesPerDay: v['freeVoiceMinutesPerDay']! as int,
        trialDays: v['trialDays']! as int,
        offlineGraceDays: v['offlineGraceDays']! as int,
        uploadQueueMaxMb: v['uploadQueueMaxMb']! as int,
        uploadWifiOnly: v['uploadWifiOnly']! as bool,
        opusBitrateKbps: v['opusBitrateKbps']! as int,
        maxRemindersPerDay: v['maxRemindersPerDay']! as int,
        pageFontWindow: v['pageFontWindow']! as int,
        manifestCheckHours: v['manifestCheckHours']! as int,
      );

  /// Built-in values (docs/tz 12.4).
  static const OtherConfig defaults = OtherConfig(
    quizPassPercent: 80,
    skillReviewQuestions: 3,
    listenRepeatPauseFactor: 1.2,
    freeVoiceMinutesPerDay: 10,
    trialDays: 7,
    offlineGraceDays: 14,
    uploadQueueMaxMb: 200,
    uploadWifiOnly: true,
    opusBitrateKbps: 16,
    maxRemindersPerDay: 2,
    pageFontWindow: 3,
    manifestCheckHours: 24,
  );

  /// Mini-quiz pass mark, % (`lessons`). `quizPassPercent`, УЧ-04.
  final double quizPassPercent;

  /// Questions in a skill review (`lessons`). `skillReviewQuestions`, 11.2.
  final int skillReviewQuestions;

  /// Pause after a repeated ayah as a factor of its length.
  /// `listenRepeatPauseFactor`, АУ-06.
  final double listenRepeatPauseFactor;

  /// Free voice checking per day, min (`entitlements`).
  /// `freeVoiceMinutesPerDay`, 11.6.
  final int freeVoiceMinutesPerDay;

  /// Trial days. `trialDays`, 11.6.
  final int trialDays;

  /// Days a subscription is trusted offline. `offlineGraceDays`, 11.6.
  final int offlineGraceDays;

  /// Largest upload queue of recordings, MB. `uploadQueueMaxMb`, 11.7.
  final int uploadQueueMaxMb;

  /// Upload recordings over Wi-Fi only. `uploadWifiOnly`, 11.7.
  final bool uploadWifiOnly;

  /// Opus bitrate of uploaded recordings, kbit/s. `opusBitrateKbps`, 11.7.
  final int opusBitrateKbps;

  /// Most reminders a day. `maxRemindersPerDay`, 11.8.
  final int maxRemindersPerDay;

  /// Page fonts kept loaded around the open page. `pageFontWindow`, 11.3.
  final int pageFontWindow;

  /// Hours between manifest checks. `manifestCheckHours`, 11.4.
  final int manifestCheckHours;
}

({int min, int max}) _range(Object v) {
  final m = v as Map<String, Object?>;
  return (min: m['min']! as int, max: m['max']! as int);
}
