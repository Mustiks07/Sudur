import 'package:contracts/contracts.dart';
import 'package:planner/planner.dart';

final DateTime epoch = DateTime.utc(2026);

PlanUnit passage({
  required String id,
  int surah = 78,
  int ayah = 1,
  int fromWord = 1,
  int toWord = 10,
  int wordCount = 10,
  PlanQueue queue = PlanQueue.notStarted,
  DateTime? due,
  DateTime? recentStartedAt,
  DateTime? learningStartedAt,
  List<AttemptRecord> history = const [],
  Set<String> goalIds = const {},
  bool knownBefore = false,
  bool acceleratedLearning = false,
  String? previousUnitId,
  int priorErrorCount = 0,
  FsrsCardSnapshot? card,
}) =>
    PlanUnit(
      id: id,
      kind: PlanUnitKind.passage,
      range: PassageRange(
        from: WordKey(surah, ayah, fromWord),
        to: WordKey(surah, ayah, toWord),
        wordCount: wordCount,
      ),
      goalIds: goalIds,
      queue: queue,
      card: card ?? FsrsCardSnapshot.initial(cardId: id.hashCode, now: epoch),
      due: due ?? epoch,
      recentStartedAt: recentStartedAt,
      learningStartedAt: learningStartedAt,
      history: history,
      knownBefore: knownBefore,
      acceleratedLearning: acceleratedLearning,
      previousUnitId: previousUnitId,
      priorErrorCount: priorErrorCount,
    );

PlanUnit hardSpot({
  required String id,
  HardSpotStage stage = HardSpotStage.open,
  DateTime? due,
  DateTime? cleanAt,
  List<AttemptRecord> history = const [],
}) =>
    PlanUnit(
      id: id,
      kind: PlanUnitKind.hardSpot,
      range: const PassageRange(
        from: WordKey(78, 1, 1),
        to: WordKey(78, 1, 3),
        wordCount: 3,
      ),
      hardSpotStage: stage,
      card: FsrsCardSnapshot.initial(cardId: id.hashCode, now: epoch),
      due: due ?? epoch,
      hardSpotCleanAt: cleanAt,
      history: history,
    );

PlanUnit skill({required String id, DateTime? due}) => PlanUnit(
      id: id,
      kind: PlanUnitKind.skill,
      range: const PassageRange(
        from: WordKey(1, 1, 1),
        to: WordKey(1, 1, 1),
        wordCount: 1,
      ),
      skillStage: SkillStage.learning,
      card: FsrsCardSnapshot.initial(cardId: id.hashCode, now: epoch),
      due: due ?? epoch,
    );

Attempt attempt({
  required String unitId,
  DateTime? at,
  AttemptMode mode = AttemptMode.recall,
  AttemptResult result = AttemptResult.clean,
  int hints = 0,
  VerificationMethod verification = VerificationMethod.voice,
  Duration duration = const Duration(seconds: 10),
  int wordCount = 10,
}) =>
    Attempt(
      unitId: unitId,
      at: at ?? epoch,
      mode: mode,
      result: result,
      hints: hints,
      verification: verification,
      duration: duration,
      wordCount: wordCount,
    );

AttemptRecord record({
  required Attempt attempt,
  PlannerRating? rating,
}) =>
    AttemptRecord(
      attempt: attempt,
      assessment: rating == null
          ? const AttemptAssessment(
              noRatingReason: NoRatingReason.notAssessable,
            )
          : AttemptAssessment(rating: rating),
    );
