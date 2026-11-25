import 'package:contracts/contracts.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/data/repositories/app_user_repository.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';

final class FakeAppUserRepository implements AppUserRepository {
  AppUserProfile? profile;
  OnboardingDraft draft = OnboardingDraft();
  TodayDashboardData today = TodayDashboardData(
    date: '2026-11-19',
    approximateMinutes: 10,
    steps: const [
      TodayStepData(
        id: 'step-1',
        kind: TodayStepKind.passage,
        reason: TodayStepReason.newMaterial,
        estimatedSeconds: 600,
      ),
    ],
    extraReview: const [],
    condition: TodayCondition.firstDay,
  );
  MoreSettingsData more = MoreSettingsData(
    profile: _profile,
    listenRepeats: 3,
    supportedRepeats: 2,
  );
  List<AppDownloadData> downloads = const [];
  int draftSaves = 0;
  bool completed = false;

  static final _profile = AppUserProfile(
    id: 'profile-1',
    createdAt: DateTime.utc(2026, 11, 19),
    language: AppLanguage.ru,
    path: AppLearningPath.memorize,
    dailyMinutes: 10,
    strictBehavior: false,
    showFirstWord: true,
  );

  @override
  Future<Result<AppUserProfile?>> loadProfile() async => Result.ok(profile);

  @override
  Future<Result<OnboardingDraft>> loadOnboardingDraft() async =>
      Result.ok(draft);

  @override
  Future<Result<void>> saveOnboardingDraft(OnboardingDraft value) async {
    draft = value;
    draftSaves += 1;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> downloadModel({
    required void Function(PrototypeDownloadProgress progress) onProgress,
  }) async {
    onProgress(
      const PrototypeDownloadProgress(
        completedBytes: 1,
        totalBytes: 1,
        resourceName: 'test',
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<AppUserProfile>> completeOnboarding(
    OnboardingDraft value,
  ) async {
    completed = true;
    profile = _profile;
    return Result.ok(_profile);
  }

  @override
  Future<Result<TodayDashboardData>> loadToday() async => Result.ok(today);

  /// Names returned by [loadSurahNames].
  Map<int, SurahNameData> surahNames = const {};

  @override
  Future<Result<Map<int, SurahNameData>>> loadSurahNames() async =>
      Result.ok(surahNames);

  @override
  Future<Result<TodayDashboardData>> startToday(String stepId) async {
    today = TodayDashboardData(
      date: today.date,
      approximateMinutes: today.approximateMinutes,
      steps: today.steps,
      extraReview: today.extraReview,
      condition: today.condition,
      inProgress: true,
      currentStepId: stepId,
    );
    return Result.ok(today);
  }

  /// Readings written through [recordReading], in order.
  final List<ReadingResult> readings = <ReadingResult>[];

  @override
  Future<Result<RecordedReading>> recordReading(ReadingResult result) async {
    readings.add(result);
    return Result.ok(
      RecordedReading(
        sessionId: 'stored-session',
        eventIds: {
          for (final check in result.checks)
            check.eventId: 'stored-${check.eventId}',
        },
        unitId: 'unit-1',
      ),
    );
  }

  /// Reports sent through [reportProblem], with or without diagnostics.
  final List<bool> reports = [];

  @override
  Future<Result<void>> reportProblem({required bool withDiagnostics}) async {
    reports.add(withDiagnostics);
    return const Result.ok(null);
  }

  /// Reminder times.
  List<int> reminders = const [];

  @override
  Future<Result<List<int>>> loadReminders() async => Result.ok(reminders);

  @override
  Future<Result<List<int>>> saveReminders(List<int> minutesOfDay) async {
    reminders = (minutesOfDay.toSet().toList()..sort()).take(2).toList();
    return Result.ok(reminders);
  }

  /// Progress returned by [loadProgress].
  List<SurahProgress> progress = const [];

  @override
  Future<Result<List<SurahProgress>>> loadProgress() async =>
      Result.ok(progress);

  /// Plan returned by [learnPlan].
  LearnPlan? learn;

  /// Progress saved through [saveLearnProgress].
  final Map<String, int> learnProgress = {};

  @override
  Future<Result<LearnPlan>> learnPlan(String stepId) async => switch (learn) {
    final LearnPlan plan => Result.ok(plan),
    null => Result.error(Exception('no plan')),
  };

  @override
  Future<Result<void>> saveLearnProgress(String unitId, int stepIndex) async {
    learnProgress[unitId] = stepIndex;
    return const Result.ok(null);
  }

  /// Self-checks written through [recordSelfCheck], in order.
  final List<SelfCheckResult> selfChecks = <SelfCheckResult>[];

  @override
  Future<Result<void>> recordSelfCheck(SelfCheckResult result) async {
    selfChecks.add(result);
    return const Result.ok(null);
  }

  /// Events disputed through [disputeCheck], with their unit.
  final List<(String, String?)> disputed = [];

  @override
  Future<Result<void>> disputeCheck(String eventId, {String? unitId}) async {
    disputed.add((eventId, unitId));
    return const Result.ok(null);
  }

  /// Steps finished through [finishTodayStep], in order.
  final List<String> finished = <String>[];

  @override
  Future<Result<TodayDashboardData>> finishTodayStep(String stepId) async {
    finished.add(stepId);
    final steps = [
      for (final step in today.steps)
        if (step.id == stepId) step.withDone(done: true) else step,
    ];
    final allDone = steps.every((step) => step.done);
    today = TodayDashboardData(
      date: today.date,
      approximateMinutes: today.approximateMinutes,
      steps: steps,
      extraReview: today.extraReview,
      condition: allDone ? TodayCondition.completed : today.condition,
      inProgress: !allDone,
    );
    return Result.ok(today);
  }

  @override
  Future<Result<TodayDashboardData>> skipTodayStep(String stepId) async {
    today = TodayDashboardData(
      date: today.date,
      approximateMinutes: 0,
      steps: today.steps.where((step) => step.id != stepId).toList(),
      extraReview: today.extraReview,
      condition: TodayCondition.completed,
    );
    return Result.ok(today);
  }

  @override
  Future<Result<MoreSettingsData>> loadMoreSettings() async => Result.ok(more);

  @override
  Future<Result<MoreSettingsData>> updateStudySettings({
    required int dailyMinutes,
    required bool strictBehavior,
    required bool showFirstWord,
    required int listenRepeats,
    required int supportedRepeats,
  }) async {
    more = MoreSettingsData(
      profile: AppUserProfile(
        id: more.profile.id,
        createdAt: more.profile.createdAt,
        language: more.profile.language,
        path: more.profile.path,
        dailyMinutes: dailyMinutes,
        strictBehavior: strictBehavior,
        showFirstWord: showFirstWord,
      ),
      listenRepeats: listenRepeats,
      supportedRepeats: supportedRepeats,
    );
    return Result.ok(more);
  }

  @override
  Future<Result<AppUserProfile>> updateLanguage(AppLanguage language) async {
    final changed = AppUserProfile(
      id: more.profile.id,
      createdAt: more.profile.createdAt,
      language: language,
      path: more.profile.path,
      dailyMinutes: more.profile.dailyMinutes,
      strictBehavior: more.profile.strictBehavior,
      showFirstWord: more.profile.showFirstWord,
    );
    more = MoreSettingsData(
      profile: changed,
      listenRepeats: more.listenRepeats,
      supportedRepeats: more.supportedRepeats,
    );
    return Result.ok(changed);
  }

  @override
  Future<Result<List<AppDownloadData>>> listDownloads() async =>
      Result.ok(downloads);

  @override
  Future<Result<void>> deleteModels() async {
    downloads = const [];
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> exportUserData() async => const Result.ok(null);

  @override
  Future<Result<bool>> importUserData() async => const Result.ok(true);

  @override
  Future<Result<void>> eraseAllUserData() async {
    profile = null;
    return const Result.ok(null);
  }
}
