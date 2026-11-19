import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/config/e01_config.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';
import 'package:sudur/ui/home/views/home_screen.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';

import '../../../test_helpers/fake_app_user_repository.dart';

void main() {
  testWidgets('shows all five destinations in English', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsAtLeastNWidgets(1));
    expect(find.text('Mushaf'), findsOneWidget);
    expect(find.text('Learn to read'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('selects another placeholder destination', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progress'));
    await tester.pump();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 3);
  });
}

Widget _app() {
  final repository = FakeAppUserRepository();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ChangeNotifierProvider(
        create: (_) => TodayViewModel(repository, const E01Config()),
      ),
      ChangeNotifierProvider(create: (_) => MoreViewModel(repository)),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(),
    ),
  );
}
