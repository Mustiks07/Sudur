import 'package:material_ui/material_ui.dart';

/// Spacing values used by the application UI.
abstract final class AppSpacing {
  /// Compact gap.
  static const double small = 8;

  /// Default gap.
  static const double medium = 16;

  /// Spacious gap.
  static const double large = 24;

  /// Extra-spacious gap.
  static const double extraLarge = 32;
}

/// Corner radius values used by the application UI.
abstract final class AppRadius {
  /// Compact corner radius.
  static const double small = 8;

  /// Default corner radius.
  static const double medium = 16;

  /// Large corner radius.
  static const double large = 24;
}

/// Icon size values used by the application UI.
abstract final class AppIconSize {
  /// Default icon size.
  static const double regular = 24;

  /// Large illustrative icon size.
  static const double large = 48;
}

/// Standard component dimensions.
abstract final class AppComponentSize {
  /// Bottom navigation bar height.
  static const double navigationBar = 72;
}

/// Theme colors that are not represented by Material's [ColorScheme].
@immutable
final class SudurColors extends ThemeExtension<SudurColors> {
  /// Creates additional application theme colors.
  const new({required this.calm, required this.muted});

  /// Accent for calm, non-error feedback.
  final Color calm;

  /// Color for secondary content.
  final Color muted;

  @override
  SudurColors copyWith({Color? calm, Color? muted}) =>
      SudurColors(calm: calm ?? this.calm, muted: muted ?? this.muted);

  @override
  SudurColors lerp(covariant SudurColors? other, double t) {
    if (other == null) return this;
    return SudurColors(
      calm: Color.lerp(calm, other.calm, t) ?? calm,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
    );
  }
}
