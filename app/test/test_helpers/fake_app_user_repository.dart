import 'package:contracts/contracts.dart';
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
    memorizationRepeats: 3,
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

  @override
  Future<Result<TodayDashboardData>> startToday(String stepId) async {
    today = TodayDashboardData(
      date: today.date,
      approximateMinutes: today.approximateMinutes,
      steps: today.steps,
      extraReview: today.extraReview,
      condition: today.condition,
      inProgress: true,
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
    required int memorizationRepeats,
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
      memorizationRepeats: memorizationRepeats,
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
      memorizationRepeats: more.memorizationRepeats,
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
