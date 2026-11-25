import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sudur/data/models/user_models.dart';
import 'package:sudur/l10n/app_localizations.dart';
import 'package:sudur/ui/core/theme/app_theme.dart';
import 'package:sudur/ui/more/view_models/more_view_model.dart';
import 'package:sudur/ui/start/view_models/start_view_model.dart';

/// Root widget of the Sudur application.
class SudurApp extends StatelessWidget {
  /// Creates the root application widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final start = context.read<StartViewModel>();
    final more = context.read<MoreViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([start, more]),
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: _locale(
          more.settings?.profile.language ?? start.draft.language,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: context.read<GoRouter>(),
      ),
    );
  }

  Locale? _locale(AppLanguage? language) => switch (language) {
    AppLanguage.ru => const Locale('ru'),
    AppLanguage.kk => const Locale('kk'),
    AppLanguage.uz => const Locale('uz'),
    AppLanguage.en => const Locale('en'),
    null => null,
  };
}
