import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/activity_suggestions.dart';
import '../../domain/worklog_csv.dart';
import '../../domain/scheduler/check_in_schedule.dart';

import '../../integrations/sheets/sheet_record.dart';

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
  TextColumn get note => text().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get endAt => integer().nullable()();
  TextColumn get deviceName => text().nullable()();
  TextColumn get devicePlatform => text().nullable()();
  TextColumn get originDevice => text().nullable()();
  TextColumn get sheetState => text().withDefault(const Constant('none'))();
  IntColumn get syncedAt => integer().nullable()();
  TextColumn get sheetError => text().nullable()();
  TextColumn get tzName => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkSchedules extends Table {
  IntColumn get id => integer()();
  TextColumn get workDays => text()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  IntColumn get intervalMinutes => integer()();
  BoolColumn get alignToWorkStart => boolean()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class SheetSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get deviceId => text()();
  TextColumn get deviceLabel => text().nullable()();
  TextColumn get account => text().nullable()();
  TextColumn get spreadsheet => text().nullable()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkCategories extends Table {
  TextColumn get normalized => text()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {normalized};
}

@DriftDatabase(
  tables: [Activities, Entries, WorkSchedules, SheetSettings, WorkCategories],
)
class WorklogDatabase extends _$WorklogDatabase {
  WorklogDatabase(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX active_activity_title_idx '
        'ON activities (title_norm) WHERE deleted_at IS NULL',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(workSchedules);
      if (from < 3) {
        await m.addColumn(entries, entries.endAt);
        await m.addColumn(entries, entries.deviceName);
        await m.addColumn(entries, entries.devicePlatform);
      }
      if (from < 4) {
        await m.createTable(sheetSettings);
        await m.addColumn(entries, entries.originDevice);
        await m.addColumn(entries, entries.sheetState);
        await m.addColumn(entries, entries.syncedAt);
        await m.addColumn(entries, entries.sheetError);
      }
      if (from < 5) {
        await m.addColumn(entries, entries.note);
        await m.addColumn(entries, entries.category);
        await m.createTable(workCategories);
      } else if (from < 6) {
        await m.addColumn(workCategories, workCategories.archived);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Stream<CheckInSchedule> watchSchedule() {
    return (select(
      workSchedules,
    )..where((row) => row.id.equals(1))).watchSingleOrNull().map(
      (row) => row == null
          ? const CheckInSchedule()
          : CheckInSchedule(
              workDays: row.workDays.split(',').map(int.parse).toSet(),
              startMinute: row.startMinute,
              endMinute: row.endMinute,
              intervalMinutes: row.intervalMinutes,
              alignToWorkStart: row.alignToWorkStart,
              enabled: row.enabled,
            ),
    );
  }

  Future<void> saveSchedule(CheckInSchedule schedule) async {
    if (!schedule.isValid) throw ArgumentError('Invalid work schedule');
    await into(workSchedules).insertOnConflictUpdate(
      WorkSchedulesCompanion.insert(
        id: const Value(1),
        workDays: (schedule.workDays.toList()..sort()).join(','),
        startMinute: schedule.startMinute,
        endMinute: schedule.endMinute,
        intervalMinutes: schedule.intervalMinutes,
        alignToWorkStart: schedule.alignToWorkStart,
        enabled: schedule.enabled,
      ),
    );
  }

  SimpleSelectStatement<$SheetSettingsTable, SheetSetting> _sheetSetting() =>
      select(sheetSettings)..where((row) => row.id.equals(1));

  Stream<SheetSetting?> watchSheetSettings() =>
      _sheetSetting().watchSingleOrNull();

  Future<SheetSetting> ensureSheetSettings() async {
    await into(sheetSettings).insert(
      SheetSettingsCompanion.insert(
        id: const Value(1),
        deviceId: const Uuid().v7(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return _sheetSetting().getSingle();
  }

  Future<void> renameSheetDevice(String name) async {
    await ensureSheetSettings();
    await transaction(() async {
      final setting = await _sheetSetting().getSingle();
      await update(
        sheetSettings,
      ).write(SheetSettingsCompanion(deviceLabel: Value(name)));
      await (update(entries)..where((row) => row.originDevice.isNull())).write(
        EntriesCompanion(
          deviceName: Value(name),
          sheetState: Value(setting.spreadsheet == null ? 'none' : 'pending'),
          syncedAt: const Value(null),
          sheetError: const Value(null),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  Future<void> linkSheet(String account, String spreadsheet) async {
    await ensureSheetSettings();
    await transaction(() async {
      final current = await _sheetSetting().getSingle();
      await update(sheetSettings).write(
        SheetSettingsCompanion(
          account: Value(account),
          spreadsheet: Value(spreadsheet),
          error: const Value(null),
        ),
      );
      if (current.spreadsheet != spreadsheet) {
        await (delete(
          entries,
        )..where((row) => row.originDevice.isNotNull())).go();
        await (update(
          entries,
        )..where((row) => row.originDevice.isNull())).write(
          const EntriesCompanion(
            sheetState: Value('pending'),
            syncedAt: Value(null),
            sheetError: Value(null),
          ),
        );
      }
    });
  }

  Future<void> unlinkSheet() => transaction(() async {
    await update(sheetSettings).write(
      const SheetSettingsCompanion(
        account: Value(null),
        spreadsheet: Value(null),
        error: Value(null),
      ),
    );
    await (update(entries)..where((row) => row.originDevice.isNull())).write(
      const EntriesCompanion(
        sheetState: Value('none'),
        syncedAt: Value(null),
        sheetError: Value(null),
      ),
    );
  });

  Future<void> setSheetError(String? error) =>
      update(sheetSettings).write(SheetSettingsCompanion(error: Value(error)));

  Future<List<SheetRecord>> pendingSheetRecords(SheetSetting setting) async {
    final rows =
        await (select(entries).join([
                innerJoin(
                  activities,
                  activities.id.equalsExp(entries.activityId),
                ),
              ])
              ..where(
                entries.originDevice.isNull() &
                    entries.sheetState.isIn(['pending', 'failed']),
              )
              ..orderBy([OrderingTerm.asc(entries.updatedAt)])
              ..limit(200))
            .get();
    return [
      for (final row in rows)
        (
          id: row.readTable(entries).id,
          title: row.readTable(activities).title,
          note: row.readTable(entries).note,
          category: row.readTable(entries).category,
          start: row.readTable(entries).startAt,
          end: row.readTable(entries).endAt,
          zone: row.readTable(entries).tzName,
          device:
              setting.deviceLabel ?? row.readTable(entries).deviceName ?? '',
          platform: row.readTable(entries).devicePlatform ?? '',
          deviceId: setting.deviceId,
          updated: row.readTable(entries).updatedAt,
          deleted: row.readTable(entries).deletedAt != null,
        ),
    ];
  }

  Future<void> markSheetRecords(
    List<SheetRecord> records, {
    String? error,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batch((batch) {
      for (final record in records) {
        batch.update(
          entries,
          EntriesCompanion(
            sheetState: Value(error == null ? 'synced' : 'failed'),
            syncedAt: Value(error == null ? now : null),
            sheetError: Value(error),
          ),
          where: (row) =>
              row.id.equals(record.id) & row.updatedAt.equals(record.updated),
        );
      }
    });
  }

  Future<void> importSheetRecords(
    List<SheetRecord> records,
    String deviceId,
  ) async {
    await transaction(() async {
      for (final record in records) {
        if (record.deviceId == deviceId) continue;
        final existing = await (select(
          entries,
        )..where((row) => row.id.equals(record.id))).getSingleOrNull();
        if (existing != null &&
            (existing.originDevice != record.deviceId ||
                existing.updatedAt >= record.updated)) {
          continue;
        }
        final titleNorm = record.title.trim().toLowerCase();
        await into(activities).insert(
          ActivitiesCompanion.insert(
            id: const Uuid().v7(),
            title: record.title,
            titleNorm: titleNorm,
            createdAt: record.updated,
            updatedAt: record.updated,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        final activity =
            await (select(activities)..where(
                  (row) =>
                      row.titleNorm.equals(titleNorm) & row.deletedAt.isNull(),
                ))
                .getSingle();
        final category = record.category;
        if (category != null &&
            category.trim().isNotEmpty &&
            category.trim().characters.length <= 80) {
          final name = category.trim();
          await into(workCategories).insert(
            WorkCategoriesCompanion.insert(
              normalized: name.toLowerCase(),
              name: name,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
        await into(entries).insertOnConflictUpdate(
          EntriesCompanion.insert(
            id: record.id,
            activityId: activity.id,
            startAt: record.start,
            endAt: Value(record.end),
            note: Value(record.note),
            category: Value(record.category),
            tzName: record.zone,
            deviceName: Value(record.device),
            devicePlatform: Value(record.platform),
            originDevice: Value(record.deviceId),
            sheetState: const Value('synced'),
            syncedAt: Value(record.updated),
            deletedAt: Value(record.deleted ? record.updated : null),
            createdAt: record.updated,
            updatedAt: record.updated,
          ),
        );
      }
    });
  }

  String _categoryName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.characters.length > 80) {
      throw ArgumentError('Invalid category name');
    }
    return trimmed;
  }

  Future<WorkCategory?> _findCategory(String normalized) => (select(
    workCategories,
  )..where((row) => row.normalized.equals(normalized))).getSingleOrNull();

  Future<void> _storeCategory(String name) =>
      into(workCategories).insertOnConflictUpdate(
        WorkCategoriesCompanion.insert(
          normalized: name.toLowerCase(),
          name: name,
          archived: const Value(false),
        ),
      );

  Future<String> addCategory(String name) => transaction(() async {
    final trimmed = _categoryName(name);
    final existing = await _findCategory(trimmed.toLowerCase());
    if (existing != null && !existing.archived) return existing.name;
    await _storeCategory(trimmed);
    return trimmed;
  });

  /// Returns null when another selectable category already has the new name.
  Future<String?> renameCategory(String current, String name) =>
      transaction(() async {
        final trimmed = _categoryName(name);
        final currentKey = current.trim().toLowerCase();
        final newKey = trimmed.toLowerCase();
        final source = await _findCategory(currentKey);
        if (source == null || source.archived) {
          throw StateError('Category is no longer available');
        }
        if (currentKey != newKey) {
          final destination = await _findCategory(newKey);
          if (destination != null && !destination.archived) return null;
          await deleteCategory(current);
        }
        await _storeCategory(trimmed);
        return trimmed;
      });

  // Keep the key so older Google Sheets records cannot restore this category.
  Future<void> deleteCategory(String name) =>
      (update(workCategories)
            ..where((row) => row.normalized.equals(name.trim().toLowerCase())))
          .write(const WorkCategoriesCompanion(archived: Value(true)));

  Stream<List<String>> watchCategories() =>
      (select(workCategories)
            ..where((row) => row.archived.equals(false))
            ..orderBy([(row) => OrderingTerm.asc(row.normalized)]))
          .watch()
          .map((rows) => rows.map((row) => row.name).toList());

  Future<void> saveCheckIn({
    required String title,
    required DateTime at,
    required String tzName,
    DateTime? end,
    String? note,
    String? category,
    String? deviceName,
    String? devicePlatform,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.characters.length > 200) {
      throw ArgumentError('Invalid activity title length');
    }
    if (end != null && !end.isAfter(at)) {
      throw ArgumentError('Work end must follow its start');
    }
    final timestamp = at.millisecondsSinceEpoch;
    final normalized = trimmed.toLowerCase();
    final savedAt = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();

    await transaction(() async {
      final settings = await _sheetSetting().getSingleOrNull();
      await into(activities).insert(
        ActivitiesCompanion.insert(
          id: uuid.v7(),
          title: trimmed,
          titleNorm: normalized,
          createdAt: savedAt,
          updatedAt: savedAt,
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
          endAt: Value(end?.millisecondsSinceEpoch),
          note: Value(note),
          category: Value(category),
          deviceName: Value(settings?.deviceLabel ?? deviceName),
          sheetState: Value(settings?.spreadsheet == null ? 'none' : 'pending'),
          devicePlatform: Value(devicePlatform),
          tzName: tzName,
          createdAt: savedAt,
          updatedAt: savedAt,
        ),
      );
    });
  }

  Future<List<ActivitySuggestion>> activitySuggestions({
    required DateTime through,
    bool recentOnly = true,
  }) async {
    final rows = await customSelect(
      """SELECT a.title, COUNT(e.id) AS uses, MAX(e.start_at) AS latest
      FROM activities a JOIN entries e ON e.activity_id = a.id
      WHERE a.deleted_at IS NULL AND e.deleted_at IS NULL
        AND (? = 0 OR e.start_at BETWEEN ? AND ?)
      GROUP BY a.id""",
      variables: [
        Variable<int>(recentOnly ? 1 : 0),
        Variable<int>(
          through.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
        ),
        Variable<int>(through.millisecondsSinceEpoch),
      ],
      readsFrom: {activities, entries},
    ).get();
    return [
      for (final row in rows)
        ActivitySuggestion(
          row.read<String>('title'),
          row.read<int>('uses'),
          row.read<int>('latest'),
        ),
    ];
  }

  Stream<List<({DateTime at, String title})>> watchWeek(DateTime monday) =>
      watchWeeklyActivities(
        monday,
      ).map((rows) => [for (final row in rows) (at: row.at, title: row.title)]);

  Future<List<CsvWorkEntry>> exportEntries(DateTime start, DateTime end) async {
    // Look beyond the export range so its last row can still have an end time.
    const nextCheckIn = CustomExpression<int>('''
      (SELECT next.created_at
       FROM entries AS next JOIN activities AS activity
         ON activity.id = next.activity_id
       WHERE next.deleted_at IS NULL AND activity.deleted_at IS NULL
         AND (next.created_at, next.id) > (entries.created_at, entries.id)
       ORDER BY next.created_at, next.id
       LIMIT 1)
    ''');
    final rows = await (_entriesInRange(
      start,
      end,
    )..addColumns([nextCheckIn])).get();
    return [
      for (final row in rows)
        (
          id: row.readTable(entries).id,
          start: DateTime.fromMillisecondsSinceEpoch(
            row.readTable(entries).startAt,
            isUtc: true,
          ),
          end: switch (row.read(nextCheckIn)) {
            final value? => DateTime.fromMillisecondsSinceEpoch(
              value,
              isUtc: true,
            ),
            null => null,
          },
          title: row.readTable(activities).title,
          note: row.readTable(entries).note,
          category: row.readTable(entries).category,
          zone: row.readTable(entries).tzName,
          device: row.readTable(entries).deviceName ?? '',
          platform: row.readTable(entries).devicePlatform ?? '',
          sheetState: row.readTable(entries).sheetState,
          syncedAt: row.readTable(entries).syncedAt,
        ),
    ];
  }

  JoinedSelectStatement _entriesInRange(DateTime start, DateTime end) =>
      select(entries).join([
          innerJoin(activities, activities.id.equalsExp(entries.activityId)),
        ])
        ..where(
          entries.startAt.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
              entries.startAt.isSmallerThanValue(end.millisecondsSinceEpoch) &
              entries.deletedAt.isNull() &
              activities.deletedAt.isNull(),
        )
        ..orderBy([
          OrderingTerm.asc(entries.startAt),
          OrderingTerm.asc(entries.id),
        ]);

  Stream<List<WeeklyActivity>> watchWeeklyActivities(DateTime monday) {
    // Calendar arithmetic keeps the range correct when a DST change occurs.
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    return watchActivities(monday, nextMonday);
  }

  Stream<List<WeeklyActivity>> watchActivities(DateTime start, DateTime end) {
    final query = _entriesInRange(start, end);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            at: DateTime.fromMillisecondsSinceEpoch(
              row.readTable(entries).startAt,
            ),
            title: row.readTable(activities).title,
            note: row.readTable(entries).note,
            category: row.readTable(entries).category,
            end: switch (row.readTable(entries).endAt) {
              final value? => DateTime.fromMillisecondsSinceEpoch(value),
              null => null,
            },
            zone: row.readTable(entries).tzName,
            device: row.readTable(entries).deviceName,
            sheetState: row.readTable(entries).sheetState,
            sheetError: row.readTable(entries).sheetError,
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

typedef WeeklyActivity = ({
  DateTime at,
  DateTime? end,
  String title,
  String? note,
  String? category,
  String zone,
  String? device,
  String sheetState,
  String? sheetError,
});

final weeklyEntriesProvider = StreamProvider.autoDispose
    .family<List<WeeklyActivity>, DateTime>(
      (ref, monday) =>
          ref.watch(databaseProvider).watchWeeklyActivities(monday),
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

final workScheduleProvider = StreamProvider<CheckInSchedule>(
  (ref) => ref.watch(databaseProvider).watchSchedule(),
);
