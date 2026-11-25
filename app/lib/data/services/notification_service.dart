import 'package:contracts/contracts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Words of a reminder in the interface language (docs/tz 11.8).
final class ReminderText {
  /// Creates the words.
  const new({required this.body, required this.channel});

  /// The neutral text: «Время для занятия — около 10 минут».
  final String body;

  /// Name of the reminder group in the phone's settings (Android).
  final String channel;
}

/// Local reminders (docs/tz 11.8): shown by the phone, no server.
abstract interface class NotificationService {
  /// Asks the phone to allow reminders; `true` when they are allowed.
  Future<Result<bool>> requestPermission();

  /// Replaces every scheduled reminder with one at each moment of [at].
  Future<Result<void>> scheduleAt(List<DateTime> at, ReminderText text);
}

/// Shows nothing: for tests and for builds without reminders.
final class NoNotificationService implements NotificationService {
  /// Creates the service.
  const new();

  @override
  Future<Result<bool>> requestPermission() async => const Result.ok(false);

  @override
  Future<Result<void>> scheduleAt(List<DateTime> at, ReminderText text) async =>
      const Result.ok(null);
}

/// Reminders through `flutter_local_notifications`.
///
/// Each reminder is a single one at an exact moment rather than a repeating
/// one: a repeating reminder cannot skip a day whose session is done (11.8)
/// on iOS, and one moment per day stays right across clock changes.
final class LocalNotificationService implements NotificationService {
  /// Creates the service; the plugin starts on first use.
  new();

  static const _channelId = 'reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _start() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      )
      .then((_) {});

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      await _start();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final allowed =
          await android?.requestNotificationsPermission() ??
          await ios?.requestPermissions(alert: true, sound: true) ??
          false;
      return Result.ok(allowed);
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }

  @override
  Future<Result<void>> scheduleAt(List<DateTime> at, ReminderText text) async {
    try {
      await _start();
      await _plugin.cancelAllPendingNotifications();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(_channelId, text.channel),
        iOS: const DarwinNotificationDetails(),
      );
      for (final (id, moment) in at.indexed) {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(moment, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          body: text.body,
        );
      }
      return const Result.ok(null);
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }
}

/// Reminder times of a day (11.8): at most [maxPerDay], in order.
List<int> remindersOfDay(List<int> minutesOfDay, {required int maxPerDay}) {
  final sorted = minutesOfDay.toSet().toList()..sort();
  return List.unmodifiable(sorted.take(maxPerDay));
}

/// Moments of the reminders at [minutesOfDay] for [days] days from [now]
/// on, in local time, only those still ahead; none today when today's
/// session is already done (11.8).
List<DateTime> reminderMoments(
  List<int> minutesOfDay, {
  required DateTime now,
  required bool todayDone,
  required int days,
}) {
  final local = now.toLocal();
  return [
    for (var day = todayDone ? 1 : 0; day < days; day++)
      for (final minute in minutesOfDay)
        DateTime(local.year, local.month, local.day + day, 0, minute),
  ].where((moment) => moment.isAfter(local)).toList(growable: false);
}
