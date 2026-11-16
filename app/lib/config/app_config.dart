/// Values that differ between application build variants.
enum AppConfig {
  /// Development configuration.
  dev(
    contentEnvironment: 'development',
    unlockPaidFeatures: true,
    verboseLogging: true,
  ),

  /// Closed-test configuration.
  beta(
    contentEnvironment: 'testing',
    unlockPaidFeatures: false,
    verboseLogging: false,
  ),

  /// Store configuration.
  prod(
    contentEnvironment: 'production',
    unlockPaidFeatures: false,
    verboseLogging: false,
  );

  /// Creates configuration values for a build variant.
  new({
    required this.contentEnvironment,
    required this.unlockPaidFeatures,
    required this.verboseLogging,
  });

  /// Content manifest environment name.
  final String contentEnvironment;

  /// Whether paid features are unlocked for development.
  final bool unlockPaidFeatures;

  /// Whether verbose diagnostic logging is allowed.
  final bool verboseLogging;
}
