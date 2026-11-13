import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/domain/scheduler/check_in_schedule.dart';
import 'package:logmydailytask/integrations/notifications/os_check_in_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('caps pending alerts and skips the spring-forward gap', () {
    tzdata.initializeTimeZones();
    final zone = tz.getLocation('America/Los_Angeles');
    final slots = checkInNotificationTimes(
      const CheckInSchedule(
        workDays: {DateTime.sunday},
        startMinute: 60,
        endMinute: 210,
      ),
      tz.TZDateTime(zone, 2026, 3, 8, 1),
      zone,
    );
    expect(slots.take(3).map((slot) => (slot.hour, slot.minute)), [
      (1, 30),
      (3, 0),
      (3, 30),
    ]);
    expect(
      checkInNotificationTimes(
        const CheckInSchedule(intervalMinutes: 5),
        tz.TZDateTime(zone, 2026, 11, 16, 8),
        zone,
      ),
      hasLength(60),
    );
  });

  test('routes a cold-start tap and replaces or cancels OS requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final pending = <int, Map<String, Object?>>{};
    final scheduled = <int>[];
    var taps = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
        case 'areNotificationsEnabled':
        case 'canScheduleExactNotifications':
          return true;
        case 'getNotificationAppLaunchDetails':
          return {
            'notificationLaunchedApp': true,
            'notificationResponse': {
              'notificationId': 1,
              'notificationResponseType': 0,
              'payload': 'worklog-check-in:Etc/UTC:true',
            },
          };
        case 'pendingNotificationRequests':
          return pending.values.toList();
        case 'zonedSchedule':
          final args = Map<String, Object?>.from(call.arguments as Map);
          final id = args['id']! as int;
          scheduled.add(id);
          pending[id] = {
            for (final key in ['id', 'title', 'body', 'payload'])
              key: args[key],
          };
          return null;
        case 'cancel':
          pending.remove((call.arguments as Map)['id']);
          return null;
      }
      throw UnsupportedError(call.method);
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final notifications = OsCheckInNotifications();
    await notifications.initialize(() => taps++);
    expect(taps, 1);
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('didReceiveNotificationResponse', {
          'notificationId': 1,
          'notificationResponseType': 0,
          'payload': 'worklog-check-in:Etc/UTC:true',
        }),
      ),
      (_) {},
    );
    expect(taps, 2);

    final future = DateTime.now().toUtc().add(const Duration(days: 7));
    final monday = DateTime.utc(
      future.year,
      future.month,
      future.day - future.weekday + 1,
    );
    Future<bool> sync(CheckInSchedule schedule) => notifications.sync(
      schedule: schedule,
      now: monday,
      zone: 'Etc/UTC',
      title: 'Check in',
      body: 'What did you work on?',
      channelName: 'Check-in reminders',
    );

    const schedule = CheckInSchedule();
    expect(await sync(schedule), isTrue);
    final firstBatch = scheduled.length;
    expect(firstBatch, 60);
    expect(await sync(schedule), isTrue);
    expect(scheduled, hasLength(firstBatch));
    expect(await sync(const CheckInSchedule(enabled: false)), isFalse);
    expect(pending, isEmpty);
  });
}
