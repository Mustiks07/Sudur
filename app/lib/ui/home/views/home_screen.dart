import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/widgets/section_placeholder.dart';
import 'package:sudur/ui/home/view_models/home_view_model.dart';

/// Empty application shell with the navigation destinations from the spec.
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const new({super.key});

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
              for (final destination in destinations)
                SectionPlaceholder(
                  icon: destination.icon,
                  title: destination.label,
                ),
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
