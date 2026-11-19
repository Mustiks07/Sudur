import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/ui/home/views/home_screen.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';
import 'package:sudur/ui/start/views/start_screen.dart';

// Keep the constructor spelling consistent with the rest of the application.
// ignore_for_file: unnecessary_type_name_in_constructor

/// Chooses first run or the regular application shell from persisted state.
class RootScreen extends StatelessWidget {
  /// Creates the root screen.
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      context.watch<StartViewModel>().completed
      ? const HomeScreen()
      : const StartScreen();
}
