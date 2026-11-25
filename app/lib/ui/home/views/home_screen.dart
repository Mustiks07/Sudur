import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/widgets/section_placeholder.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';
import 'package:sudur/ui/more/views/more_screen.dart';
import 'package:sudur/ui/today/view_models/today_view_model.dart';
import 'package:sudur/ui/today/views/today_screen.dart';

/// Empty application shell with the navigation destinations from the spec.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const new({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<TodayViewModel>().initialize());
      unawaited(context.read<MoreViewModel>().initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final localizations = AppLocalizations.of(context);
        final destinations = _destinations(localizations);

        return Scaffold(
          appBar: AppBar(title: Text(localizations.appName)),
          body: IndexedStack(
            index: viewModel.selectedIndex,
            children: [
              const TodayScreen(),
              for (final destination in destinations.skip(1).take(3))
                SectionPlaceholder(
                  icon: destination.icon,
                  title: destination.label,
                ),
              const MoreScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: viewModel.selectedIndex,
            onDestinationSelected: viewModel.selectDestination,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }

  List<_Destination> _destinations(AppLocalizations localizations) => [
    _Destination(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      label: localizations.today,
    ),
    _Destination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: localizations.mushaf,
    ),
    _Destination(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      label: localizations.learnToRead,
    ),
    _Destination(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      label: localizations.progress,
    ),
    _Destination(
      icon: Icons.more_horiz_outlined,
      selectedIcon: Icons.more_horiz,
      label: localizations.more,
    ),
  ];
}

final class _Destination {
  const new({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
