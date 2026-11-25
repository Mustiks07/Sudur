import 'package:contracts/contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/data/models/reading_models.dart';
import 'package:sudur/data/services/notification_service.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/progress/view_models/progress_view_model.dart';
import 'package:sudur/ui/progress/views/progress_screens.dart';

import '../../test_helpers/fake_app_user_repository.dart';
import '../read/read_test_helpers.dart';

final class _Notifications implements NotificationService {
  bool allowed = true;
  int asked = 0;

  @override
  Future<Result<bool>> requestPermission() async {
    asked++;
    return Result.ok(allowed);
  }

  @override
  Future<Result<void>> scheduleAt(List<DateTime> at, ReminderText text) async =>
      const Result.ok(null);
}

PassageProgress _passage(String id, MemoryStatus status) => PassageProgress(
  unitId: id,
  from: const WordKey(78, 1, 1),
  to: const WordKey(78, 5, 2),
  status: status,
  hints: 0,
  hardSpots: status == MemoryStatus.hardSpot ? 1 : 0,
);

void main() {
  test('11.8: at most two reminders, in order', () {
    expect(remindersOfDay([900, 60, 600, 60], maxPerDay: 2), [60, 600]);
  });

  test('a surah shows what needs attention first; no overall percent', () {
    final surah = SurahProgress(
      surah: 78,
      passages: [
        _passage('a', MemoryStatus.confirmed),
        _passage('b', MemoryStatus.stale),
        _passage('c', MemoryStatus.withHelp),
      ],
    );
    expect(surah.status, MemoryStatus.stale);
    expect(
      SurahProgress(surah: 1, passages: const []).status,
      MemoryStatus.notStarted,
    );
  });

  test('reminder times are saved, at most two; the phone is asked to allow '
      'them', () async {
    final notifications = _Notifications();
    final viewModel = RemindersViewModel(
      FakeAppUserRepository(),
      notifications,
      FakeDevice(),
      const E01Config(),
    );
    await viewModel.add(600);
    await viewModel.add(60);
    expect(viewModel.times, [60, 600]);
    expect(viewModel.canAdd, isFalse);
    expect(notifications.asked, 2);
    expect(viewModel.blocked, isFalse);
    await viewModel.remove(60);
    expect(viewModel.times, [600]);
  });

  testWidgets('reminders refused by the phone: a way to the settings', (
    tester,
  ) async {
    final device = FakeDevice();
    final viewModel = RemindersViewModel(
      FakeAppUserRepository(),
      _Notifications()..allowed = false,
      device,
      const E01Config(),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<RemindersViewModel>.value(
        value: viewModel,
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: RemindersScreen(),
        ),
      ),
    );
    await viewModel.add(600);
    await tester.pump();
    expect(viewModel.times, [600]);
    await tester.tap(find.byKey(const ValueKey('reminders-open-settings')));
    expect(device.settingsOpened, 1);
  });

  testWidgets('the grid shows 114 surahs and the legend', (tester) async {
    final user = FakeAppUserRepository()
      ..progress = [
        SurahProgress(
          surah: 78,
          passages: [_passage('a', MemoryStatus.hardSpot)],
        ),
      ];
    final viewModel = ProgressViewModel(user);
    await viewModel.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProgressScreen()),
        ),
      ),
    );
    expect(find.text('Есть трудное место'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-surah-1')), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
