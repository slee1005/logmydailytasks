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
}
