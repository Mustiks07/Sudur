import 'package:material_ui/material_ui.dart';
import 'package:sudur/ui/core/theme/app_tokens.dart';

/// Light and dark application themes built from shared design tokens.
abstract final class AppTheme {
  /// Light application theme.
  static final ThemeData light = _theme(
    brightness: Brightness.light,
    seedColor: const Color(0xFF336A5B),
    calm: const Color(0xFF28755E),
    muted: const Color(0xFF5F6F69),
  );

  /// Dark application theme.
  static final ThemeData dark = _theme(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF8ED5BF),
    calm: const Color(0xFF8ED5BF),
    muted: const Color(0xFFB6C8C1),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color seedColor,
    required Color calm,
    required Color muted,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(AppSpacing.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: AppComponentSize.navigationBar,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      extensions: [SudurColors(calm: calm, muted: muted)],
    );
  }
}
