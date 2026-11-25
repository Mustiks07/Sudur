import 'package:contracts/contracts.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/repositories/reading_repository.dart';
import 'package:sudur/data/services/device_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';
import 'package:sudur/data/services/prototype_session.dart';

/// Three test words of one ayah; their text is a test value, not Quran.
const w1 = WordKey(2, 255, 1);
const w2 = WordKey(2, 255, 2);
const w3 = WordKey(2, 255, 3);

ReadingPassage testPassage({bool voice = true}) => ReadingPassage(
  from: w1,
  to: w3,
  ayahs: [
    ReadingAyah(
      surah: 2,
      ayah: 255,
      words: const [
        ReadingWord(key: w1, text: 'test-1'),
        ReadingWord(key: w2, text: 'test-2'),
        ReadingWord(key: w3, text: 'test-3'),
      ],
    ),
  ],
  session: voice
      ? const PrototypeSessionConfiguration(
          words: [w1, w2, w3],
          contentJson: '{}',
          normalizerJson: '{}',
          modelDirectory: '/model',
          vadModelPath: '/vad',
          textVersion: 't',
          rulesVersion: 'r',
          wholeQuranText: true,
        )
      : null,
  limits: voice
      ? const ReadingLimits(
          stuckWordTries: 3,
          strictMaxFails: 2,
          strictMaxWaitMs: 15000,
        )
      : null,
);

/// Reading repository returning [testPassage]; the model downloads on call.
final class FakeReadingRepository implements ReadingRepository {
  // The class name keeps the fake easy to scan.
  // ignore: unnecessary_type_name_in_constructor
  FakeReadingRepository({this.voice = true});

  bool voice;
  int downloads = 0;

  @override
  Future<Result<ReadingPassage>> prepare({
    required WordKey from,
    required WordKey to,
  }) async => Result.ok(testPassage(voice: voice));

  @override
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) async {
    downloads++;
    voice = true;
    return const Result.ok(null);
  }
}

const versions = ReadingVersions(
  modelId: 'm',
  modelVersion: '1',
  rulesVersion: 'r',
  textVersion: 't',
);

CheckEvent check(
  String id,
  WordKey word, {
  CheckKind kind = CheckKind.substitution,
  CheckState state = CheckState.preliminary,
}) => CheckEvent(
  sessionId: 's',
  atMs: 10,
  eventId: id,
  kind: kind,
  state: state,
  words: [word],
  expectedText: 'expected-test',
  heardText: 'heard-test',
  audioStartMs: 0,
  audioEndMs: 10,
  versions: versions,
);

PositionUpdate at(WordKey word) => PositionUpdate(
  sessionId: 's',
  atMs: 10,
  word: word,
  confidence: PositionConfidence.high,
);

WordRevealed revealed(WordKey word) => WordRevealed(
  sessionId: 's',
  atMs: 10,
  word: word,
  reason: RevealReason.heard,
);

const ok = SignalQuality(sessionId: 's', atMs: 1, level: SignalQualityLevel.ok);

SessionFinished finishedEvent() => const SessionFinished(
  sessionId: 's',
  atMs: 100,
  words: [
    SessionWordResult(wordKey: w1, outcome: SessionWordOutcome.read),
    SessionWordResult(wordKey: w2, outcome: SessionWordOutcome.read),
    SessionWordResult(wordKey: w3, outcome: SessionWordOutcome.read),
  ],
  eventIds: [],
  durationMs: 100,
  audioWasSuitable: true,
);

/// Device without a screen or settings: remembers what was asked.
final class FakeDevice implements DeviceService {
  /// Whether the screen is kept on now.
  bool screenOn = false;

  /// Times the settings were opened.
  int settingsOpened = 0;

  @override
  Future<void> keepScreenOn({required bool on}) async => screenOn = on;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  /// Audio played, in order.
  final List<ReviewAudio> played = [];

  /// Texts shared, in order.
  final List<String> shared = [];

  @override
  Future<void> play(ReviewAudio audio) async => played.add(audio);

  @override
  Future<void> stopPlaying() async {}

  @override
  Future<void> shareText(String text) async => shared.add(text);
}
