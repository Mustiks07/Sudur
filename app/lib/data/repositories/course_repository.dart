import 'dart:io';

import 'package:contracts/contracts.dart';
import 'package:lessons/lessons.dart' as lessons;
import 'package:planner/planner.dart';
import 'package:storage/storage.dart' as storage;
import 'package:sudur/data/repositories/plan_state_codec.dart';
import 'package:sudur/data/services/app_storage_service.dart';
import 'package:sudur/data/services/prototype_asset_installer.dart';

// The class names keep the repository easy to scan.
// ignore_for_file: unnecessary_type_name_in_constructor
// ignore_for_file: prefer_initializing_formals

/// The course as the screens see it (docs/tz 13.9).
final class CourseData {
  /// Creates the data.
  CourseData({
    required List<lessons.LessonPackage> packages,
    required Map<String, lessons.LessonState> states,
  }) : packages = List.unmodifiable(packages),
       states = Map.unmodifiable(states);

  /// Installed stages, in order.
  final List<lessons.LessonPackage> packages;

  /// State of every lesson.
  final Map<String, lessons.LessonState> states;

  /// Lessons available in the app (УЧ-08).
  int get lessonCount => packages.fold(0, (n, p) => n + p.lessons.length);

  /// The next lesson to take: in progress, else the first available.
  lessons.Lesson? get next {
    final all = [for (final p in packages) ...p.lessons];
    return all
            .where(
              (l) =>
                  states[l.id] == lessons.LessonState.inProgress ||
                  states[l.id] == lessons.LessonState.quiz ||
                  states[l.id] == lessons.LessonState.failed,
            )
            .firstOrNull ??
        all
            .where((l) => states[l.id] == lessons.LessonState.available)
            .firstOrNull;
  }

  /// The lesson [id].
  lessons.Lesson? lesson(String id) {
    for (final p in packages) {
      for (final l in p.lessons) {
        if (l.id == id) return l;
      }
    }
    return null;
  }
}

/// Lesson packages and lesson progress (docs/tz 3.1, 11.2).
abstract interface class CourseRepository {
  /// Installs the lesson packages if needed and reads the progress.
  Future<Result<CourseData>> load();

  /// Writes what [events] of a lesson mean: progress after every step,
  /// the passed lesson, and its skills as plan units (3.4).
  Future<Result<void>> record(
    List<lessons.LessonEvent> events,
    lessons.LessonProgress? progress,
  );
}

/// File- and storage-backed implementation.
final class LocalCourseRepository implements CourseRepository {
  /// Creates the repository.
  LocalCourseRepository({
    required PrototypeAssetInstaller installer,
    required AppStorageService storage,
    required Clock clock,
    required String Function() createId,
  }) : _installer = installer,
       _storage = storage,
       _clock = clock,
       _createId = createId;

  final PrototypeAssetInstaller _installer;
  final AppStorageService _storage;
  final Clock _clock;
  final String Function() _createId;

  @override
  Future<Result<CourseData>> load() async {
    try {
      final path = await _installer.installLessons();
      final package = _unwrap(
        lessons.parseLessonPackage(await File(path).readAsString()),
      );
      final db = await _storage.storage;
      final saved = {
        for (final row in _unwrap(await db.lessons.list()))
          row.lessonId: lessons.LessonProgress(
            lessonId: row.lessonId,
            state: lessons.LessonState.values.byName(row.state.name),
            stepIndex: row.stepIndex,
            // Stored as whole percent, 0–100, like QuizScored.percent.
            quizPercent: row.quizPercent.toDouble(),
            contentVersion: row.contentVersion,
          ),
      };
      return Result.ok(
        CourseData(
          packages: [package],
          states: lessons.lessonStates(package, saved, stageOpen: true),
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> record(
    List<lessons.LessonEvent> events,
    lessons.LessonProgress? progress,
  ) async {
    try {
      final db = await _storage.storage;
      final now = _clock.now().toUtc();
      final written = await db.transaction(() async {
        if (progress != null) {
          _unwrap(
            await db.lessons.put((
              lessonId: progress.lessonId,
              state: storage.LessonState.values.byName(progress.state.name),
              stepIndex: progress.stepIndex,
              quizPercent: (progress.quizPercent ?? 0).round(),
              contentVersion: progress.contentVersion,
              updatedAt: now.millisecondsSinceEpoch,
            )),
          );
        }
        for (final event in events) {
          if (event is lessons.SkillsLearned) {
            await _addSkills(db, event.skills, now);
          }
        }
      });
      _unwrap(written);
      return const Result.ok(null);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  /// A passed lesson's skills become plan units (3.4: «После урока курса»).
  Future<void> _addSkills(
    storage.StorageService db,
    List<String> skills,
    DateTime now,
  ) async {
    final profiles = _unwrap(await db.profiles.list());
    if (profiles.isEmpty) return;
    final profileId = profiles.first.id;
    final existing = {
      for (final u in _unwrap(await db.units.listForProfile(profileId)))
        ?u.skillId,
    };
    for (final skill in skills.where((s) => !existing.contains(s))) {
      final id = _createId();
      _unwrap(
        await db.units.putUnit((
          id: id,
          profileId: profileId,
          kind: storage.UnitKind.skill,
          fromWordIndex: null,
          toWordIndex: null,
          skillId: skill,
          surah: null,
          origin: storage.UnitOrigin.lesson,
          parentUnitId: null,
          createdAt: now.millisecondsSinceEpoch,
        )),
      );
      _unwrap(
        await db.units.putState((
          unitId: id,
          queue: storage.UnitQueue.learning,
          memoryState: storage.JsonObjectData.fromJson(
            const PlanMemoryState(skillStage: SkillStage.learning).toJson(),
          ),
          fsrsCard: storage.JsonObjectData.fromJson(
            encodeFsrsCard(
              FsrsCardSnapshot.initial(
                cardId: now.microsecondsSinceEpoch + existing.length,
                now: now,
              ),
            ),
          ),
          dueAt: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
          recentSince: null,
          lastAttemptAt: now.millisecondsSinceEpoch,
          lastMethod: null,
          updatedAt: now.millisecondsSinceEpoch,
        )),
      );
    }
  }
}

T _unwrap<T>(Result<T> result) => switch (result) {
  Ok<T>(:final value) => value,
  Error<T>(:final error) => throw error,
};
