import 'package:app_settings/app_settings.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The phone itself: keeping the screen on and opening the app's settings.
abstract interface class DeviceService {
  /// Keeps the screen on while [on] (ЭЧ-09: it does not go dark while
  /// reading).
  Future<void> keepScreenOn({required bool on});

  /// Opens the system settings of the app («Открыть настройки», 13.3).
  Future<void> openAppSettings();
}

/// `wakelock_plus` and `app_settings`.
final class PluginDeviceService implements DeviceService {
  /// Creates the service.
  const new();

  @override
  Future<void> keepScreenOn({required bool on}) =>
      on ? WakelockPlus.enable() : WakelockPlus.disable();

  @override
  Future<void> openAppSettings() => AppSettings.openAppSettings();
}
