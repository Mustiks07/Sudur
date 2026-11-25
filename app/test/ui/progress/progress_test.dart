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

final class _Notifications implements NotificationService {
  List<int>? scheduled;

  @override
  Future<void> scheduleDaily(List<int> minutesOfDay, String text) async =>
      scheduled = minutesOfDay;
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
  test('11.8: at most two reminders, none on a done day', () {
    expect(remindersOfDay([900, 60, 600], dayDone: false, maxPerDay: 2), [
      60,
      600,
    ]);
    expect(remindersOfDay([60], dayDone: true, maxPerDay: 2), isEmpty);
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

  test('reminder times are saved and scheduled, at most two', () async {
    final notifications = _Notifications();
    final viewModel = RemindersViewModel(
      FakeAppUserRepository(),
      notifications,
      const E01Config(),
    );
    await viewModel.add(600, 'text');
    await viewModel.add(60, 'text');
    expect(viewModel.times, [60, 600]);
    expect(viewModel.canAdd, isFalse);
    expect(notifications.scheduled, [60, 600]);
    await viewModel.remove(60, 'text');
    expect(notifications.scheduled, [600]);
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
