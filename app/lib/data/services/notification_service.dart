/// Local reminders (docs/tz 11.8): shown by the phone, no server.
abstract interface class NotificationService {
  /// Schedules daily reminders at [minutesOfDay] with [text], replacing
  /// the earlier ones; an empty list cancels them.
  Future<void> scheduleDaily(List<int> minutesOfDay, String text);
}

/// No reminders are shown yet: the notification plugin
/// (`flutter_local_notifications`) needs the owner's approval (rule 7).
final class NoNotificationService implements NotificationService {
  /// Creates the service.
  const new();

  @override
  Future<void> scheduleDaily(List<int> minutesOfDay, String text) async {}
}

/// Reminder times of a day (11.8): at most [maxPerDay], in order, and none
/// when the day's session is already done.
List<int> remindersOfDay(
  List<int> minutesOfDay, {
  required bool dayDone,
  required int maxPerDay,
}) {
  if (dayDone) return const [];
  final sorted = minutesOfDay.toSet().toList()..sort();
  return List.unmodifiable(sorted.take(maxPerDay));
}
