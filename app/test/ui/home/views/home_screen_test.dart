import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sudur/app.dart';
import 'package:sudur/config/app_config.dart';
import 'package:sudur/config/dependencies.dart';

void main() {
  testWidgets('shows all five destinations in English', (tester) async {
    await tester.pumpWidget(
      const AppDependencies(config: AppConfig.dev, child: SudurApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsAtLeastNWidgets(1));
    expect(find.text('Mushaf'), findsOneWidget);
    expect(find.text('Learn to read'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('selects another placeholder destination', (tester) async {
    await tester.pumpWidget(
      const AppDependencies(config: AppConfig.dev, child: SudurApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progress'));
    await tester.pump();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 3);
  });
}
