import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/scheduler/check_in_schedule.dart';

final osCheckInNotificationsProvider = Provider<OsCheckInNotifications?>((ref) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => OsCheckInNotifications(),
    _ => null,
  };
});

final osReminderStatusProvider = NotifierProvider<OsReminderStatus, bool>(
  OsReminderStatus.new,
);

class OsReminderStatus extends Notifier<bool> {
  @override
  bool build() => false;

  void setReady(bool ready) => state = ready;
}

class OsCheckInNotifications {
  static const _payloadPrefix = 'worklog-check-in:';
  static const _channelId = 'worklog_check_ins';
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;

  Future<void> initialize(VoidCallback onTap) async {
    try {
      await (_initializing ??= _initialize(onTap));
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _initialize(VoidCallback onTap) async {
    tzdata.initializeTimeZones();
    const apple = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_check_in'),
        iOS: apple,
        macOS: apple,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (_isCheckIn(response.payload)) onTap();
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final scenePayload = defaultTargetPlatform == TargetPlatform.iOS
        ? await const MethodChannel(
            'logmydailytask/notification_launch',
          ).invokeMethod<String>('takeLaunchPayload')
        : null;
    if (_isCheckIn(scenePayload) ||
        (launch?.didNotificationLaunchApp == true &&
            _isCheckIn(launch?.notificationResponse?.payload))) {
      onTap();
    }
  }

  bool _isCheckIn(String? payload) =>
      payload?.startsWith(_payloadPrefix) ?? false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  MacOSFlutterLocalNotificationsPlugin? get _mac => _plugin
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >();

  Future<bool> isAllowed() async {
    await _initializing;
    return (await _android?.areNotificationsEnabled()) ??
        (await _ios?.checkPermissions())?.isEnabled ??
        (await _mac?.checkPermissions())?.isEnabled ??
        false;
  }

  Future<bool> requestPermission() async {
    await _initializing;
    if (!await isAllowed()) {
      await (_android?.requestNotificationsPermission() ??
          _ios?.requestPermissions(alert: true, sound: true) ??
          _mac?.requestPermissions(alert: true, sound: true));
    }
    final allowed = await isAllowed();
    if (allowed && await _android?.canScheduleExactNotifications() == false) {
      await _android?.requestExactAlarmsPermission();
    }
    return allowed;
  }

  Future<bool> sync({
    required CheckInSchedule schedule,
    required DateTime now,
    required String zone,
    required String title,
    required String body,
    required String channelName,
  }) async {
    final allowed = schedule.enabled && await isAllowed();
    final pending = await _plugin.pendingNotificationRequests();
    if (!allowed) {
      for (final item in pending.where((item) => _isCheckIn(item.payload))) {
        await _plugin.cancel(id: item.id);
      }
      return false;
    }

    final location = tz.getLocation(zone);
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final slots = checkInNotificationTimes(schedule, now, location);
    final wanted = {
      for (final slot in slots) slot.millisecondsSinceEpoch ~/ 60000: slot,
    };
    final payload = '$_payloadPrefix$zone:$exact';
    final unchanged = <int>{};
    for (final item in pending.where((item) => _isCheckIn(item.payload))) {
      if (wanted.containsKey(item.id) &&
          item.payload == payload &&
          item.title == title &&
          item.body == body) {
        unchanged.add(item.id);
      } else {
        await _plugin.cancel(id: item.id);
      }
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    for (final entry in wanted.entries) {
      if (unchanged.contains(entry.key)) continue;
      if (!entry.value.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: entry.key,
        scheduledDate: entry.value,
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    }
    return true;
  }
}

List<tz.TZDateTime> checkInNotificationTimes(
  CheckInSchedule schedule,
  DateTime now,
  tz.Location location, {
  int limit = 60,
}) {
  final localNow = tz.TZDateTime.from(now, location);
  return schedule
      .remindersAfter(
        localNow,
        days: 8,
        localDate: (year, month, day, hour, minute) =>
            tz.TZDateTime(location, year, month, day, hour, minute),
      )
      .take(limit)
      .toList();
}
