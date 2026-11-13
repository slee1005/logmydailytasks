import 'package:logmydailytask/domain/scheduler/check_in_schedule.dart';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/data/db/database.dart';

void main() {
  test(
    'streams saved records and reads them after reopening the database',
    () async {
      final directory = await Directory.systemTemp.createTemp('worklog-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/worklog.sqlite');
      final monday = DateTime(2026, 11, 9);
      final friday = DateTime(2026, 11, 13, 16);
      final sunday = DateTime(2026, 11, 15, 12);
      final nextMonday = DateTime(2026, 11, 16);
      const zone = 'America/Los_Angeles';

      final database = WorklogDatabase(NativeDatabase(file));
      try {
        final updates = expectLater(
          database
              .watchWeek(monday)
              .map((week) => week.map((e) => e.title).toList()),
          emitsInOrder([
            isEmpty,
            ['Write docs'],
            ['Write docs', 'Write docs'],
          ]),
        );
        await database.watchWeek(monday).first;
        await database.saveCheckIn(
          title: '  Write docs  ',
          at: friday,
          tzName: zone,
        );
        await database.watchWeek(monday).firstWhere((week) => week.length == 1);
        await database.saveCheckIn(
          title: 'write docs',
          at: sunday,
          tzName: zone,
        );
        await updates;
        await database.saveCheckIn(
          title: 'Next week',
          at: nextMonday,
          tzName: zone,
        );
      } finally {
        await database.close();
      }

      final reopened = WorklogDatabase(NativeDatabase(file));
      try {
        expect(await reopened.watchWeek(monday).first, [
          (at: friday, title: 'Write docs'),
          (at: sunday, title: 'Write docs'),
        ]);
        expect(await reopened.watchWeek(nextMonday).first, [
          (at: nextMonday, title: 'Next week'),
        ]);
        final saved = await reopened.select(reopened.entries).get();
        expect(saved.map((entry) => entry.tzName), everyElement(zone));
        expect(await reopened.select(reopened.activities).get(), hasLength(2));
      } finally {
        await reopened.close();
      }
    },
  );
  test(
    'upgrades v1 records and keeps saved work settings after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('schedule-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/worklog.sqlite');
      final friday = DateTime(2026, 11, 13, 16);
      final monday = DateTime(2026, 11, 9);
      final original = WorklogDatabase(NativeDatabase(file));
      try {
        await original.saveCheckIn(
          title: 'Existing work',
          at: friday,
          tzName: 'Etc/UTC',
        );
        // Recreate the previous schema: v2 added only the work schedule table.
        await original.customStatement('DROP TABLE work_schedules');
        await original.customStatement('DROP TABLE sheet_settings');
        await original.customStatement('DROP TABLE work_categories');
        for (final column in [
          'end_at',
          'device_name',
          'device_platform',
          'origin_device',
          'sheet_state',
          'synced_at',
          'sheet_error',
          'note',
          'category',
        ]) {
          await original.customStatement(
            'ALTER TABLE entries DROP COLUMN $column',
          );
        }
        await original.customStatement('PRAGMA user_version = 1');
      } finally {
        await original.close();
      }

      final migrated = WorklogDatabase(NativeDatabase(file));
      try {
        expect(await migrated.watchWeek(monday).first, [
          (at: friday, title: 'Existing work'),
        ]);
        expect((await migrated.watchSchedule().first).intervalMinutes, 30);
        await migrated.saveSchedule(
          const CheckInSchedule(
            workDays: {2, 6},
            startMinute: 550,
            endMinute: 1050,
            intervalMinutes: 15,
            enabled: false,
            alignToWorkStart: true,
          ),
        );
      } finally {
        await migrated.close();
      }

      final reopened = WorklogDatabase(NativeDatabase(file));
      try {
        final schedule = await reopened.watchSchedule().first;
        expect(schedule.workDays, {2, 6});
        expect(schedule.startMinute, 550);
        expect(schedule.endMinute, 1050);
        expect(schedule.intervalMinutes, 15);
        expect(schedule.enabled, isFalse);
        expect(schedule.alignToWorkStart, isTrue);
      } finally {
        await reopened.close();
      }
    },
  );
  test(
    'history uses a seven-day window and export preserves the selected zone',
    () async {
      final database = WorklogDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 13);
      await database.saveCheckIn(
        title: 'Older work',
        at: now.subtract(const Duration(days: 8)),
        tzName: 'Etc/UTC',
      );
      await database.saveCheckIn(
        title: 'New work',
        at: now,
        end: now.add(const Duration(hours: 1)),
        tzName: 'Asia/Seoul',
        deviceName: 'iOS',
        devicePlatform: 'iOS',
      );
      final recent = await database.activitySuggestions(through: now);
      expect(recent.map((item) => item.title), ['New work']);
      final all = await database.activitySuggestions(
        through: now,
        recentOnly: false,
      );
      expect(
        all.map((item) => item.title),
        unorderedEquals(['New work', 'Older work']),
      );
      await database.customStatement(
        'UPDATE entries SET created_at = start_at',
      );
      final row = (await database.exportEntries(
        now,
        now.add(const Duration(days: 1)),
      )).single;
      expect(row.start, now);
      expect(row.end, isNull);
      expect(row.zone, 'Asia/Seoul');
      expect(row.device, 'iOS');

      final nextRegistration = now.add(const Duration(days: 2, minutes: 15));
      await database.saveCheckIn(
        title: 'Later work',
        at: now.add(const Duration(days: 2)),
        tzName: 'Etc/UTC',
      );
      await database.customStatement(
        "UPDATE entries SET created_at = ? WHERE start_at = ?",
        [
          nextRegistration.millisecondsSinceEpoch,
          now.add(const Duration(days: 2)).millisecondsSinceEpoch,
        ],
      );
      final updated = (await database.exportEntries(
        now,
        now.add(const Duration(days: 1)),
      )).single;
      expect(updated.end, nextRegistration);
    },
  );
}
