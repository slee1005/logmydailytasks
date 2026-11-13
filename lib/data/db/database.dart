import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DataClassName('Activity')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get titleNorm => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkEntry')
@TableIndex(name: 'entry_start_idx', columns: {#startAt})
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get activityId => text().references(Activities, #id)();
  IntColumn get startAt => integer()();
  TextColumn get tzName => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Activities, Entries])
class WorklogDatabase extends _$WorklogDatabase {
  WorklogDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX active_activity_title_idx '
        'ON activities (title_norm) WHERE deleted_at IS NULL',
      );
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> saveCheckIn({
    required String title,
    required DateTime at,
    required String tzName,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.characters.length > 200) {
      throw ArgumentError('Invalid activity title length');
    }
    final timestamp = at.millisecondsSinceEpoch;
    final normalized = trimmed.toLowerCase();
    const uuid = Uuid();

    await transaction(() async {
      await into(activities).insert(
        ActivitiesCompanion.insert(
          id: uuid.v7(),
          title: trimmed,
          titleNorm: normalized,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      final activity =
          await (select(activities)..where(
                (row) =>
                    row.titleNorm.equals(normalized) & row.deletedAt.isNull(),
              ))
              .getSingle();
      await into(entries).insert(
        EntriesCompanion.insert(
          id: uuid.v7(),
          activityId: activity.id,
          startAt: timestamp,
          tzName: tzName,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    });
  }

  Stream<List<({DateTime at, String title})>> watchWeek(DateTime monday) {
    // Calendar arithmetic keeps the range correct when a DST change occurs.
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    final query =
        select(entries).join([
            innerJoin(activities, activities.id.equalsExp(entries.activityId)),
          ])
          ..where(
            entries.startAt.isBiggerOrEqualValue(
                  monday.millisecondsSinceEpoch,
                ) &
                entries.startAt.isSmallerThanValue(
                  nextMonday.millisecondsSinceEpoch,
                ) &
                entries.deletedAt.isNull() &
                activities.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(entries.startAt),
            OrderingTerm.asc(entries.id),
          ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            at: DateTime.fromMillisecondsSinceEpoch(
              row.readTable(entries).startAt,
            ),
            title: row.readTable(activities).title,
          ),
      ],
    );
  }
}

final databaseProvider = Provider<WorklogDatabase>((ref) {
  final database = WorklogDatabase(
    LazyDatabase(() async {
      final key = kIsWeb ? null : await _loadDatabaseKey();
      return driftDatabase(
        name: 'logmydailytask',
        native: DriftNativeOptions(
          setup: key == null
              ? null
              : (db) {
                  if (db.select('PRAGMA cipher_version').isEmpty) {
                    throw StateError('SQLCipher is unavailable');
                  }
                  db.execute("PRAGMA key = \"x'$key'\"");
                },
        ),
        web: DriftWebOptions(
          sqlite3Wasm: Uri.base.resolve('sqlite3.wasm'),
          driftWorker: Uri.base.resolve('drift_worker.dart.js'),
          onResult: (result) {
            if (result.chosenImplementation ==
                WasmStorageImplementation.inMemory) {
              throw StateError('Persistent browser storage is unavailable');
            }
          },
        ),
      );
    }),
  );
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final weeklyEntriesProvider = StreamProvider.autoDispose
    .family<List<({DateTime at, String title})>, DateTime>(
      (ref, monday) => ref.watch(databaseProvider).watchWeek(monday),
    );

Future<String> _loadDatabaseKey() async {
  const storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    aOptions: AndroidOptions(resetOnError: false),
  );
  const name = 'logmydailytask.sqlite.key';
  final existing = await storage.read(key: name);
  if (existing != null) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(existing)) {
      throw StateError('Invalid database key');
    }
    return existing;
  }
  final random = Random.secure();
  final key = List.generate(
    32,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  await storage.write(key: name, value: key);
  return key;
}
