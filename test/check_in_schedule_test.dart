import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/domain/scheduler/check_in_schedule.dart';
import 'package:logmydailytask/domain/scheduler/check_in_timer.dart';

void main() {
  test('finds the next complete slot and skips non-work days', () {
    const schedule = CheckInSchedule();
    expect(
      schedule.nextReminderAfter(DateTime(2026, 11, 13, 8)),
      DateTime(2026, 11, 13, 9, 30),
    );
    expect(
      schedule.nextReminderAfter(DateTime(2026, 11, 13, 17, 59)),
      DateTime(2026, 11, 13, 18),
    );
    expect(
      schedule.nextReminderAfter(DateTime(2026, 11, 13, 18)),
      DateTime(2026, 11, 16, 9, 30),
    );
  });

  test('supports custom intervals and a short shift', () {
    const clock = CheckInSchedule(startMinute: 550, intervalMinutes: 35);
    const shortShift = CheckInSchedule(startMinute: 545, endMinute: 575);
    final beforeWork = DateTime(2026, 11, 13, 8);
    expect(clock.nextReminderAfter(beforeWork), DateTime(2026, 11, 13, 9, 55));
    expect(
      shortShift.nextReminderAfter(beforeWork),
      DateTime(2026, 11, 13, 9, 35),
    );
    expect(
      const CheckInSchedule(enabled: false).nextReminderAfter(beforeWork),
      isNull,
    );
    expect(const CheckInSchedule(workDays: {}).isValid, isFalse);
    expect(const CheckInSchedule(intervalMinutes: 7).isValid, isFalse);
    expect(
      const CheckInSchedule(startMinute: 700, endMinute: 650).isValid,
      isFalse,
    );
  });

  testWidgets('timer fires once and cancels when reminders are turned off', (
    tester,
  ) async {
    final start = DateTime(2026, 11, 13, 9, 29, 59);
    var now = start;
    final reminders = <DateTime>[];
    final timer = CheckInTimer(now: () => now, onReminder: reminders.add);
    timer.schedule(const CheckInSchedule());
    now = start.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(reminders, [DateTime(2026, 11, 13, 9, 30)]);
    timer.schedule(const CheckInSchedule(enabled: false));
    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(hours: 1));
    expect(reminders, hasLength(1));
    timer.cancel();
  });
}
