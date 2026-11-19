import 'package:logmydailytask/domain/scheduler/check_in_schedule.dart';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/data/db/database.dart';

void main() {
  test(
    'closes this device previous task and queues both records for sync',
    () async {
      final database = WorklogDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.linkSheet('account@example.test', 'shared');
      final settings = await database.ensureSheetSettings();
      final firstStart = DateTime.utc(2026, 11, 19, 7, 30);
      await database.saveCheckIn(
        title: 'Task A',
        at: firstStart,
        tzName: 'Etc/UTC',
      );
      final original = (await database.pendingSheetRecords(settings)).single;
      await database.markSheetRecords([original]);
      await database.importSheetRecords([
        (
          id: 'other-device-task',
          title: 'Other device',
          note: null,
          category: null,
          start: firstStart
              .add(const Duration(minutes: 20))
              .millisecondsSinceEpoch,
          end: null,
          zone: 'Etc/UTC',
          device: 'Phone',
          platform: 'iOS',
          deviceId: 'phone',
          updated: firstStart.millisecondsSinceEpoch,
          deleted: false,
        ),
      ], settings.deviceId);

      final secondStart = firstStart.add(const Duration(minutes: 45));
      final thirdStart = secondStart.add(const Duration(minutes: 45));
      await database.saveCheckIn(
        title: 'Task B',
        at: secondStart,
        tzName: 'Etc/UTC',
      );
      await database.markSheetRecords([original]);
      var rows = await database.select(database.entries).get();
      final first = rows.singleWhere((row) => row.id == original.id);
      expect(first.endAt, secondStart.millisecondsSinceEpoch);
      expect(first.sheetState, 'pending');
      expect(first.syncedAt, isNull);
      expect(first.updatedAt, greaterThan(original.updated));
      expect(
        rows.singleWhere((row) => row.id == 'other-device-task').endAt,
        isNull,
      );

      await database.saveCheckIn(
        title: 'Task C',
        at: thirdStart,
        tzName: 'Etc/UTC',
      );
      final pending = await database.pendingSheetRecords(settings);
      expect(
        pending.map((record) => record.title),
        unorderedEquals(['Task A', 'Task B', 'Task C']),
      );
      expect(
        pending.singleWhere((record) => record.title == 'Task B').end,
        thirdStart.millisecondsSinceEpoch,
      );
      expect(
        pending.singleWhere((record) => record.title == 'Task C').end,
        isNull,
      );

      final explicitEnd = thirdStart.add(const Duration(minutes: 50));
      await database.saveCheckIn(
        title: 'Finished task',
        at: thirdStart.add(const Duration(minutes: 10)),
        end: explicitEnd,
        tzName: 'Etc/UTC',
      );
      await database.saveCheckIn(
        title: 'Next task',
        at: explicitEnd.add(const Duration(minutes: 15)),
        tzName: 'Etc/UTC',
      );
      rows = await database.select(database.entries).get();
      expect(
        rows.where((row) => row.endAt == explicitEnd.millisecondsSinceEpoch),
        hasLength(1),
      );
      expect(
        rows.singleWhere((row) => row.id == 'other-device-task').endAt,
        isNull,
      );
    },
  );

  test(
    'rolls back the previous task end when a new task cannot be saved',
    () async {
      final database = WorklogDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final at = DateTime.utc(2026, 11, 19, 7, 30);
      await database.saveCheckIn(title: 'Existing', at: at, tzName: 'Etc/UTC');
      final original = (await database.select(database.entries).get()).single;
      await database.customStatement(
        "CREATE TRIGGER reject_new_entry BEFORE INSERT ON entries "
        "WHEN NEW.note = 'reject' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        database.saveCheckIn(
          title: 'Rejected',
          at: at.add(const Duration(minutes: 45)),
          note: 'reject',
          tzName: 'Etc/UTC',
        ),
        throwsA(isA<Exception>()),
      );
      expect((await database.select(database.entries).get()).single, original);
      expect(await database.select(database.activities).get(), hasLength(1));
    },
  );

  test('updates the category list and preserves old check-ins', () async {
    final database = WorklogDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.addCategory('Docs');
    await database.addCategory('Meetings');
    final at = DateTime.utc(2026, 11, 13);
    await database.saveCheckIn(
      title: 'Local docs',
      at: at,
      tzName: 'Etc/UTC',
      category: 'Docs',
    );

    expect(await database.renameCategory('Docs', ' meetings '), isNull);
    expect(await database.watchCategories().first, ['Docs', 'Meetings']);
    expect(await database.renameCategory('Docs', 'DOCS'), 'DOCS');
    expect(await database.renameCategory('DOCS', ' Writing '), 'Writing');
    await database.deleteCategory('Meetings');
    expect(await database.watchCategories().first, ['Writing']);

    await database.importSheetRecords([
      for (final category in ['Docs', 'Meetings', 'Support'])
        (
          id: category,
          title: 'Imported $category',
          note: null,
          category: category,
          start: at.millisecondsSinceEpoch,
          end: null,
          zone: 'Etc/UTC',
          device: 'Other device',
          platform: 'macOS',
          deviceId: 'other',
          updated: at.millisecondsSinceEpoch,
          deleted: false,
        ),
    ], 'local');
    expect(await database.watchCategories().first, ['Support', 'Writing']);
    final entries = await database.select(database.entries).get();
    expect(
      entries.map((entry) => entry.category),
      unorderedEquals(['Docs', 'Docs', 'Meetings', 'Support']),
    );

    expect(await database.addCategory('meetings'), 'meetings');
    expect(await database.watchCategories().first, [
      'meetings',
      'Support',
      'Writing',
    ]);
  });

  test('preserves the category list when upgrading from version 5', () async {
    final directory = await Directory.systemTemp.createTemp('category-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/worklog.sqlite');
    final original = WorklogDatabase(NativeDatabase(file));
    try {
      await original.addCategory('Docs');
      await original.customStatement(
        'ALTER TABLE work_categories DROP COLUMN archived',
      );
      await original.customStatement('PRAGMA user_version = 5');
    } finally {
      await original.close();
    }

    final migrated = WorklogDatabase(NativeDatabase(file));
    try {
      expect(await migrated.watchCategories().first, ['Docs']);
      await migrated.deleteCategory('Docs');
      expect(await migrated.watchCategories().first, isEmpty);
    } finally {
      await migrated.close();
    }

    final reopened = WorklogDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.watchCategories().first, isEmpty);
  });

  test('opens version 5 when the archived column already exists', () async {
    final directory = await Directory.systemTemp.createTemp('category-v5-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/worklog.sqlite');
    final original = WorklogDatabase(NativeDatabase(file));
    final at = DateTime.utc(2026, 11, 19, 7, 30);
    late WorkEntry saved;
    late SheetSetting settings;
    try {
      await original.addCategory('Docs');
      await original.addCategory('Archived');
      await original.deleteCategory('Archived');
      await original.linkSheet('account@example.test', 'existing-sheet');
      await original.renameSheetDevice('Original Mac');
      await original.saveCheckIn(
        title: 'Existing task',
        at: at,
        tzName: 'Etc/UTC',
        category: 'Docs',
      );
      saved = (await original.select(original.entries).get()).single;
      settings = await original.ensureSheetSettings();
      await original.customStatement('PRAGMA user_version = 5');
    } finally {
      await original.close();
    }

    final migrated = WorklogDatabase(NativeDatabase(file));
    try {
      expect(await migrated.watchCategories().first, ['Docs']);
      expect((await migrated.select(migrated.entries).get()).single, saved);
      expect(await migrated.ensureSheetSettings(), settings);
      expect(
        (await migrated.select(migrated.workCategories).get())
            .singleWhere((category) => category.name == 'Archived')
            .archived,
        isTrue,
      );
      await migrated.saveCheckIn(
        title: 'Next task',
        at: at.add(const Duration(minutes: 45)),
        tzName: 'Etc/UTC',
      );
      await migrated.renameSheetDevice('Updated Mac');
      await migrated.linkSheet('account@example.test', 'existing-sheet');
    } finally {
      await migrated.close();
    }

    final reopened = WorklogDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    expect(await reopened.select(reopened.entries).get(), hasLength(2));
    final restoredSettings = await reopened.ensureSheetSettings();
    expect(restoredSettings.deviceLabel, 'Updated Mac');
    expect(restoredSettings.spreadsheet, 'existing-sheet');
    expect(
      (await reopened.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      6,
    );
  });

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
          ),
        );
        await migrated.customStatement(
          "UPDATE work_schedules SET align_to_work_start = 1",
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
        await reopened.setRemindersEnabled(true);
        final enabled = await reopened.getSchedule();
        expect(enabled.enabled, isTrue);
        expect(enabled.workDays, {2, 6});
        expect(enabled.startMinute, 550);
        expect(enabled.endMinute, 1050);
        expect(enabled.intervalMinutes, 15);
      } finally {
        await reopened.close();
      }
    },
  );
  test(
    'history uses a rolling 48-hour window and export preserves the selected zone',
    () async {
      final database = WorklogDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 13);
      await database.saveCheckIn(
        title: 'Older work',
        at: now.subtract(const Duration(days: 2, seconds: 1)),
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
      await database.saveCheckIn(
        title: 'Work at the cutoff',
        at: now.subtract(const Duration(days: 2)),
        tzName: 'Etc/UTC',
      );
      final recent = await database.activitySuggestions(through: now);
      expect(recent.map((item) => item.title), [
        'New work',
        'Work at the cutoff',
      ]);
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
