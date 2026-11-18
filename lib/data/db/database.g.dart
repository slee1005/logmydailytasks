// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleNormMeta = const VerificationMeta(
    'titleNorm',
  );
  @override
  late final GeneratedColumn<String> titleNorm = GeneratedColumn<String>(
    'title_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    titleNorm,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_norm')) {
      context.handle(
        _titleNormMeta,
        titleNorm.isAcceptableOrUnknown(data['title_norm']!, _titleNormMeta),
      );
    } else if (isInserting) {
      context.missing(_titleNormMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_norm'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final String id;
  final String title;
  final String titleNorm;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Activity({
    required this.id,
    required this.title,
    required this.titleNorm,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['title_norm'] = Variable<String>(titleNorm);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      title: Value(title),
      titleNorm: Value(titleNorm),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleNorm: serializer.fromJson<String>(json['titleNorm']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'titleNorm': serializer.toJson<String>(titleNorm),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Activity copyWith({
    String? id,
    String? title,
    String? titleNorm,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Activity(
    id: id ?? this.id,
    title: title ?? this.title,
    titleNorm: titleNorm ?? this.titleNorm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleNorm: data.titleNorm.present ? data.titleNorm.value : this.titleNorm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleNorm: $titleNorm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, titleNorm, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleNorm == this.titleNorm &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> titleNorm;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleNorm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required String title,
    required String titleNorm,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       titleNorm = Value(titleNorm),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Activity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? titleNorm,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleNorm != null) 'title_norm': titleNorm,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? titleNorm,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleNorm: titleNorm ?? this.titleNorm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleNorm.present) {
      map['title_norm'] = Variable<String>(titleNorm.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleNorm: $titleNorm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, WorkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES activities (id)',
    ),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _devicePlatformMeta = const VerificationMeta(
    'devicePlatform',
  );
  @override
  late final GeneratedColumn<String> devicePlatform = GeneratedColumn<String>(
    'device_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sheetStateMeta = const VerificationMeta(
    'sheetState',
  );
  @override
  late final GeneratedColumn<String> sheetState = GeneratedColumn<String>(
    'sheet_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sheetErrorMeta = const VerificationMeta(
    'sheetError',
  );
  @override
  late final GeneratedColumn<String> sheetError = GeneratedColumn<String>(
    'sheet_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tzNameMeta = const VerificationMeta('tzName');
  @override
  late final GeneratedColumn<String> tzName = GeneratedColumn<String>(
    'tz_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    startAt,
    note,
    category,
    endAt,
    deviceName,
    devicePlatform,
    originDevice,
    sheetState,
    syncedAt,
    sheetError,
    tzName,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('device_platform')) {
      context.handle(
        _devicePlatformMeta,
        devicePlatform.isAcceptableOrUnknown(
          data['device_platform']!,
          _devicePlatformMeta,
        ),
      );
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    }
    if (data.containsKey('sheet_state')) {
      context.handle(
        _sheetStateMeta,
        sheetState.isAcceptableOrUnknown(data['sheet_state']!, _sheetStateMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('sheet_error')) {
      context.handle(
        _sheetErrorMeta,
        sheetError.isAcceptableOrUnknown(data['sheet_error']!, _sheetErrorMeta),
      );
    }
    if (data.containsKey('tz_name')) {
      context.handle(
        _tzNameMeta,
        tzName.isAcceptableOrUnknown(data['tz_name']!, _tzNameMeta),
      );
    } else if (isInserting) {
      context.missing(_tzNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      devicePlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_platform'],
      ),
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      ),
      sheetState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_state'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
      sheetError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_error'],
      ),
      tzName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class WorkEntry extends DataClass implements Insertable<WorkEntry> {
  final String id;
  final String activityId;
  final int startAt;
  final String? note;
  final String? category;
  final int? endAt;
  final String? deviceName;
  final String? devicePlatform;
  final String? originDevice;
  final String sheetState;
  final int? syncedAt;
  final String? sheetError;
  final String tzName;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkEntry({
    required this.id,
    required this.activityId,
    required this.startAt,
    this.note,
    this.category,
    this.endAt,
    this.deviceName,
    this.devicePlatform,
    this.originDevice,
    required this.sheetState,
    this.syncedAt,
    this.sheetError,
    required this.tzName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activity_id'] = Variable<String>(activityId);
    map['start_at'] = Variable<int>(startAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<int>(endAt);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    if (!nullToAbsent || devicePlatform != null) {
      map['device_platform'] = Variable<String>(devicePlatform);
    }
    if (!nullToAbsent || originDevice != null) {
      map['origin_device'] = Variable<String>(originDevice);
    }
    map['sheet_state'] = Variable<String>(sheetState);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    if (!nullToAbsent || sheetError != null) {
      map['sheet_error'] = Variable<String>(sheetError);
    }
    map['tz_name'] = Variable<String>(tzName);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      activityId: Value(activityId),
      startAt: Value(startAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      devicePlatform: devicePlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(devicePlatform),
      originDevice: originDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(originDevice),
      sheetState: Value(sheetState),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      sheetError: sheetError == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetError),
      tzName: Value(tzName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkEntry(
      id: serializer.fromJson<String>(json['id']),
      activityId: serializer.fromJson<String>(json['activityId']),
      startAt: serializer.fromJson<int>(json['startAt']),
      note: serializer.fromJson<String?>(json['note']),
      category: serializer.fromJson<String?>(json['category']),
      endAt: serializer.fromJson<int?>(json['endAt']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      devicePlatform: serializer.fromJson<String?>(json['devicePlatform']),
      originDevice: serializer.fromJson<String?>(json['originDevice']),
      sheetState: serializer.fromJson<String>(json['sheetState']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      sheetError: serializer.fromJson<String?>(json['sheetError']),
      tzName: serializer.fromJson<String>(json['tzName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activityId': serializer.toJson<String>(activityId),
      'startAt': serializer.toJson<int>(startAt),
      'note': serializer.toJson<String?>(note),
      'category': serializer.toJson<String?>(category),
      'endAt': serializer.toJson<int?>(endAt),
      'deviceName': serializer.toJson<String?>(deviceName),
      'devicePlatform': serializer.toJson<String?>(devicePlatform),
      'originDevice': serializer.toJson<String?>(originDevice),
      'sheetState': serializer.toJson<String>(sheetState),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'sheetError': serializer.toJson<String?>(sheetError),
      'tzName': serializer.toJson<String>(tzName),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkEntry copyWith({
    String? id,
    String? activityId,
    int? startAt,
    Value<String?> note = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<int?> endAt = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
    Value<String?> devicePlatform = const Value.absent(),
    Value<String?> originDevice = const Value.absent(),
    String? sheetState,
    Value<int?> syncedAt = const Value.absent(),
    Value<String?> sheetError = const Value.absent(),
    String? tzName,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkEntry(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    startAt: startAt ?? this.startAt,
    note: note.present ? note.value : this.note,
    category: category.present ? category.value : this.category,
    endAt: endAt.present ? endAt.value : this.endAt,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    devicePlatform: devicePlatform.present
        ? devicePlatform.value
        : this.devicePlatform,
    originDevice: originDevice.present ? originDevice.value : this.originDevice,
    sheetState: sheetState ?? this.sheetState,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    sheetError: sheetError.present ? sheetError.value : this.sheetError,
    tzName: tzName ?? this.tzName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkEntry copyWithCompanion(EntriesCompanion data) {
    return WorkEntry(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      note: data.note.present ? data.note.value : this.note,
      category: data.category.present ? data.category.value : this.category,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      devicePlatform: data.devicePlatform.present
          ? data.devicePlatform.value
          : this.devicePlatform,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      sheetState: data.sheetState.present
          ? data.sheetState.value
          : this.sheetState,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      sheetError: data.sheetError.present
          ? data.sheetError.value
          : this.sheetError,
      tzName: data.tzName.present ? data.tzName.value : this.tzName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkEntry(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('startAt: $startAt, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('endAt: $endAt, ')
          ..write('deviceName: $deviceName, ')
          ..write('devicePlatform: $devicePlatform, ')
          ..write('originDevice: $originDevice, ')
          ..write('sheetState: $sheetState, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('sheetError: $sheetError, ')
          ..write('tzName: $tzName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activityId,
    startAt,
    note,
    category,
    endAt,
    deviceName,
    devicePlatform,
    originDevice,
    sheetState,
    syncedAt,
    sheetError,
    tzName,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkEntry &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.startAt == this.startAt &&
          other.note == this.note &&
          other.category == this.category &&
          other.endAt == this.endAt &&
          other.deviceName == this.deviceName &&
          other.devicePlatform == this.devicePlatform &&
          other.originDevice == this.originDevice &&
          other.sheetState == this.sheetState &&
          other.syncedAt == this.syncedAt &&
          other.sheetError == this.sheetError &&
          other.tzName == this.tzName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class EntriesCompanion extends UpdateCompanion<WorkEntry> {
  final Value<String> id;
  final Value<String> activityId;
  final Value<int> startAt;
  final Value<String?> note;
  final Value<String?> category;
  final Value<int?> endAt;
  final Value<String?> deviceName;
  final Value<String?> devicePlatform;
  final Value<String?> originDevice;
  final Value<String> sheetState;
  final Value<int?> syncedAt;
  final Value<String?> sheetError;
  final Value<String> tzName;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.endAt = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.devicePlatform = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.sheetState = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.sheetError = const Value.absent(),
    this.tzName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String activityId,
    required int startAt,
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.endAt = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.devicePlatform = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.sheetState = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.sheetError = const Value.absent(),
    required String tzName,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       activityId = Value(activityId),
       startAt = Value(startAt),
       tzName = Value(tzName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkEntry> custom({
    Expression<String>? id,
    Expression<String>? activityId,
    Expression<int>? startAt,
    Expression<String>? note,
    Expression<String>? category,
    Expression<int>? endAt,
    Expression<String>? deviceName,
    Expression<String>? devicePlatform,
    Expression<String>? originDevice,
    Expression<String>? sheetState,
    Expression<int>? syncedAt,
    Expression<String>? sheetError,
    Expression<String>? tzName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (startAt != null) 'start_at': startAt,
      if (note != null) 'note': note,
      if (category != null) 'category': category,
      if (endAt != null) 'end_at': endAt,
      if (deviceName != null) 'device_name': deviceName,
      if (devicePlatform != null) 'device_platform': devicePlatform,
      if (originDevice != null) 'origin_device': originDevice,
      if (sheetState != null) 'sheet_state': sheetState,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (sheetError != null) 'sheet_error': sheetError,
      if (tzName != null) 'tz_name': tzName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? activityId,
    Value<int>? startAt,
    Value<String?>? note,
    Value<String?>? category,
    Value<int?>? endAt,
    Value<String?>? deviceName,
    Value<String?>? devicePlatform,
    Value<String?>? originDevice,
    Value<String>? sheetState,
    Value<int?>? syncedAt,
    Value<String?>? sheetError,
    Value<String>? tzName,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      startAt: startAt ?? this.startAt,
      note: note ?? this.note,
      category: category ?? this.category,
      endAt: endAt ?? this.endAt,
      deviceName: deviceName ?? this.deviceName,
      devicePlatform: devicePlatform ?? this.devicePlatform,
      originDevice: originDevice ?? this.originDevice,
      sheetState: sheetState ?? this.sheetState,
      syncedAt: syncedAt ?? this.syncedAt,
      sheetError: sheetError ?? this.sheetError,
      tzName: tzName ?? this.tzName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (devicePlatform.present) {
      map['device_platform'] = Variable<String>(devicePlatform.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (sheetState.present) {
      map['sheet_state'] = Variable<String>(sheetState.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (sheetError.present) {
      map['sheet_error'] = Variable<String>(sheetError.value);
    }
    if (tzName.present) {
      map['tz_name'] = Variable<String>(tzName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('startAt: $startAt, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('endAt: $endAt, ')
          ..write('deviceName: $deviceName, ')
          ..write('devicePlatform: $devicePlatform, ')
          ..write('originDevice: $originDevice, ')
          ..write('sheetState: $sheetState, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('sheetError: $sheetError, ')
          ..write('tzName: $tzName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkSchedulesTable extends WorkSchedules
    with TableInfo<$WorkSchedulesTable, WorkSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workDaysMeta = const VerificationMeta(
    'workDays',
  );
  @override
  late final GeneratedColumn<String> workDays = GeneratedColumn<String>(
    'work_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMinutesMeta = const VerificationMeta(
    'intervalMinutes',
  );
  @override
  late final GeneratedColumn<int> intervalMinutes = GeneratedColumn<int>(
    'interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alignToWorkStartMeta = const VerificationMeta(
    'alignToWorkStart',
  );
  @override
  late final GeneratedColumn<bool> alignToWorkStart = GeneratedColumn<bool>(
    'align_to_work_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("align_to_work_start" IN (0, 1))',
    ),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workDays,
    startMinute,
    endMinute,
    intervalMinutes,
    alignToWorkStart,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('work_days')) {
      context.handle(
        _workDaysMeta,
        workDays.isAcceptableOrUnknown(data['work_days']!, _workDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_workDaysMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMinuteMeta);
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    } else if (isInserting) {
      context.missing(_endMinuteMeta);
    }
    if (data.containsKey('interval_minutes')) {
      context.handle(
        _intervalMinutesMeta,
        intervalMinutes.isAcceptableOrUnknown(
          data['interval_minutes']!,
          _intervalMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalMinutesMeta);
    }
    if (data.containsKey('align_to_work_start')) {
      context.handle(
        _alignToWorkStartMeta,
        alignToWorkStart.isAcceptableOrUnknown(
          data['align_to_work_start']!,
          _alignToWorkStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_alignToWorkStartMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_days'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      )!,
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      )!,
      intervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_minutes'],
      )!,
      alignToWorkStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}align_to_work_start'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $WorkSchedulesTable createAlias(String alias) {
    return $WorkSchedulesTable(attachedDatabase, alias);
  }
}

class WorkSchedule extends DataClass implements Insertable<WorkSchedule> {
  final int id;
  final String workDays;
  final int startMinute;
  final int endMinute;
  final int intervalMinutes;
  final bool alignToWorkStart;
  final bool enabled;
  const WorkSchedule({
    required this.id,
    required this.workDays,
    required this.startMinute,
    required this.endMinute,
    required this.intervalMinutes,
    required this.alignToWorkStart,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['work_days'] = Variable<String>(workDays);
    map['start_minute'] = Variable<int>(startMinute);
    map['end_minute'] = Variable<int>(endMinute);
    map['interval_minutes'] = Variable<int>(intervalMinutes);
    map['align_to_work_start'] = Variable<bool>(alignToWorkStart);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  WorkSchedulesCompanion toCompanion(bool nullToAbsent) {
    return WorkSchedulesCompanion(
      id: Value(id),
      workDays: Value(workDays),
      startMinute: Value(startMinute),
      endMinute: Value(endMinute),
      intervalMinutes: Value(intervalMinutes),
      alignToWorkStart: Value(alignToWorkStart),
      enabled: Value(enabled),
    );
  }

  factory WorkSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkSchedule(
      id: serializer.fromJson<int>(json['id']),
      workDays: serializer.fromJson<String>(json['workDays']),
      startMinute: serializer.fromJson<int>(json['startMinute']),
      endMinute: serializer.fromJson<int>(json['endMinute']),
      intervalMinutes: serializer.fromJson<int>(json['intervalMinutes']),
      alignToWorkStart: serializer.fromJson<bool>(json['alignToWorkStart']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workDays': serializer.toJson<String>(workDays),
      'startMinute': serializer.toJson<int>(startMinute),
      'endMinute': serializer.toJson<int>(endMinute),
      'intervalMinutes': serializer.toJson<int>(intervalMinutes),
      'alignToWorkStart': serializer.toJson<bool>(alignToWorkStart),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  WorkSchedule copyWith({
    int? id,
    String? workDays,
    int? startMinute,
    int? endMinute,
    int? intervalMinutes,
    bool? alignToWorkStart,
    bool? enabled,
  }) => WorkSchedule(
    id: id ?? this.id,
    workDays: workDays ?? this.workDays,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    alignToWorkStart: alignToWorkStart ?? this.alignToWorkStart,
    enabled: enabled ?? this.enabled,
  );
  WorkSchedule copyWithCompanion(WorkSchedulesCompanion data) {
    return WorkSchedule(
      id: data.id.present ? data.id.value : this.id,
      workDays: data.workDays.present ? data.workDays.value : this.workDays,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      intervalMinutes: data.intervalMinutes.present
          ? data.intervalMinutes.value
          : this.intervalMinutes,
      alignToWorkStart: data.alignToWorkStart.present
          ? data.alignToWorkStart.value
          : this.alignToWorkStart,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkSchedule(')
          ..write('id: $id, ')
          ..write('workDays: $workDays, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('intervalMinutes: $intervalMinutes, ')
          ..write('alignToWorkStart: $alignToWorkStart, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workDays,
    startMinute,
    endMinute,
    intervalMinutes,
    alignToWorkStart,
    enabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkSchedule &&
          other.id == this.id &&
          other.workDays == this.workDays &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.intervalMinutes == this.intervalMinutes &&
          other.alignToWorkStart == this.alignToWorkStart &&
          other.enabled == this.enabled);
}

class WorkSchedulesCompanion extends UpdateCompanion<WorkSchedule> {
  final Value<int> id;
  final Value<String> workDays;
  final Value<int> startMinute;
  final Value<int> endMinute;
  final Value<int> intervalMinutes;
  final Value<bool> alignToWorkStart;
  final Value<bool> enabled;
  const WorkSchedulesCompanion({
    this.id = const Value.absent(),
    this.workDays = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.intervalMinutes = const Value.absent(),
    this.alignToWorkStart = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  WorkSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required String workDays,
    required int startMinute,
    required int endMinute,
    required int intervalMinutes,
    required bool alignToWorkStart,
    required bool enabled,
  }) : workDays = Value(workDays),
       startMinute = Value(startMinute),
       endMinute = Value(endMinute),
       intervalMinutes = Value(intervalMinutes),
       alignToWorkStart = Value(alignToWorkStart),
       enabled = Value(enabled);
  static Insertable<WorkSchedule> custom({
    Expression<int>? id,
    Expression<String>? workDays,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<int>? intervalMinutes,
    Expression<bool>? alignToWorkStart,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workDays != null) 'work_days': workDays,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (intervalMinutes != null) 'interval_minutes': intervalMinutes,
      if (alignToWorkStart != null) 'align_to_work_start': alignToWorkStart,
      if (enabled != null) 'enabled': enabled,
    });
  }

  WorkSchedulesCompanion copyWith({
    Value<int>? id,
    Value<String>? workDays,
    Value<int>? startMinute,
    Value<int>? endMinute,
    Value<int>? intervalMinutes,
    Value<bool>? alignToWorkStart,
    Value<bool>? enabled,
  }) {
    return WorkSchedulesCompanion(
      id: id ?? this.id,
      workDays: workDays ?? this.workDays,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      alignToWorkStart: alignToWorkStart ?? this.alignToWorkStart,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workDays.present) {
      map['work_days'] = Variable<String>(workDays.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (intervalMinutes.present) {
      map['interval_minutes'] = Variable<int>(intervalMinutes.value);
    }
    if (alignToWorkStart.present) {
      map['align_to_work_start'] = Variable<bool>(alignToWorkStart.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('workDays: $workDays, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('intervalMinutes: $intervalMinutes, ')
          ..write('alignToWorkStart: $alignToWorkStart, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $SheetSettingsTable extends SheetSettings
    with TableInfo<$SheetSettingsTable, SheetSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheetSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceLabelMeta = const VerificationMeta(
    'deviceLabel',
  );
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
    'device_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spreadsheetMeta = const VerificationMeta(
    'spreadsheet',
  );
  @override
  late final GeneratedColumn<String> spreadsheet = GeneratedColumn<String>(
    'spreadsheet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    deviceLabel,
    account,
    spreadsheet,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sheet_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SheetSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_label')) {
      context.handle(
        _deviceLabelMeta,
        deviceLabel.isAcceptableOrUnknown(
          data['device_label']!,
          _deviceLabelMeta,
        ),
      );
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('spreadsheet')) {
      context.handle(
        _spreadsheetMeta,
        spreadsheet.isAcceptableOrUnknown(
          data['spreadsheet']!,
          _spreadsheetMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SheetSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SheetSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_label'],
      ),
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      spreadsheet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spreadsheet'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $SheetSettingsTable createAlias(String alias) {
    return $SheetSettingsTable(attachedDatabase, alias);
  }
}

class SheetSetting extends DataClass implements Insertable<SheetSetting> {
  final int id;
  final String deviceId;
  final String? deviceLabel;
  final String? account;
  final String? spreadsheet;
  final String? error;
  const SheetSetting({
    required this.id,
    required this.deviceId,
    this.deviceLabel,
    this.account,
    this.spreadsheet,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deviceLabel != null) {
      map['device_label'] = Variable<String>(deviceLabel);
    }
    if (!nullToAbsent || account != null) {
      map['account'] = Variable<String>(account);
    }
    if (!nullToAbsent || spreadsheet != null) {
      map['spreadsheet'] = Variable<String>(spreadsheet);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  SheetSettingsCompanion toCompanion(bool nullToAbsent) {
    return SheetSettingsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      deviceLabel: deviceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceLabel),
      account: account == null && nullToAbsent
          ? const Value.absent()
          : Value(account),
      spreadsheet: spreadsheet == null && nullToAbsent
          ? const Value.absent()
          : Value(spreadsheet),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory SheetSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SheetSetting(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceLabel: serializer.fromJson<String?>(json['deviceLabel']),
      account: serializer.fromJson<String?>(json['account']),
      spreadsheet: serializer.fromJson<String?>(json['spreadsheet']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceLabel': serializer.toJson<String?>(deviceLabel),
      'account': serializer.toJson<String?>(account),
      'spreadsheet': serializer.toJson<String?>(spreadsheet),
      'error': serializer.toJson<String?>(error),
    };
  }

  SheetSetting copyWith({
    int? id,
    String? deviceId,
    Value<String?> deviceLabel = const Value.absent(),
    Value<String?> account = const Value.absent(),
    Value<String?> spreadsheet = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => SheetSetting(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    deviceLabel: deviceLabel.present ? deviceLabel.value : this.deviceLabel,
    account: account.present ? account.value : this.account,
    spreadsheet: spreadsheet.present ? spreadsheet.value : this.spreadsheet,
    error: error.present ? error.value : this.error,
  );
  SheetSetting copyWithCompanion(SheetSettingsCompanion data) {
    return SheetSetting(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceLabel: data.deviceLabel.present
          ? data.deviceLabel.value
          : this.deviceLabel,
      account: data.account.present ? data.account.value : this.account,
      spreadsheet: data.spreadsheet.present
          ? data.spreadsheet.value
          : this.spreadsheet,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SheetSetting(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('account: $account, ')
          ..write('spreadsheet: $spreadsheet, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deviceId, deviceLabel, account, spreadsheet, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetSetting &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.deviceLabel == this.deviceLabel &&
          other.account == this.account &&
          other.spreadsheet == this.spreadsheet &&
          other.error == this.error);
}

class SheetSettingsCompanion extends UpdateCompanion<SheetSetting> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String?> deviceLabel;
  final Value<String?> account;
  final Value<String?> spreadsheet;
  final Value<String?> error;
  const SheetSettingsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.account = const Value.absent(),
    this.spreadsheet = const Value.absent(),
    this.error = const Value.absent(),
  });
  SheetSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.deviceLabel = const Value.absent(),
    this.account = const Value.absent(),
    this.spreadsheet = const Value.absent(),
    this.error = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SheetSetting> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? deviceLabel,
    Expression<String>? account,
    Expression<String>? spreadsheet,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceLabel != null) 'device_label': deviceLabel,
      if (account != null) 'account': account,
      if (spreadsheet != null) 'spreadsheet': spreadsheet,
      if (error != null) 'error': error,
    });
  }

  SheetSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String?>? deviceLabel,
    Value<String?>? account,
    Value<String?>? spreadsheet,
    Value<String?>? error,
  }) {
    return SheetSettingsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      account: account ?? this.account,
      spreadsheet: spreadsheet ?? this.spreadsheet,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceLabel.present) {
      map['device_label'] = Variable<String>(deviceLabel.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (spreadsheet.present) {
      map['spreadsheet'] = Variable<String>(spreadsheet.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheetSettingsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('account: $account, ')
          ..write('spreadsheet: $spreadsheet, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $WorkCategoriesTable extends WorkCategories
    with TableInfo<$WorkCategoriesTable, WorkCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [normalized, name, archived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {normalized};
  @override
  WorkCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkCategory(
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $WorkCategoriesTable createAlias(String alias) {
    return $WorkCategoriesTable(attachedDatabase, alias);
  }
}

class WorkCategory extends DataClass implements Insertable<WorkCategory> {
  final String normalized;
  final String name;
  final bool archived;
  const WorkCategory({
    required this.normalized,
    required this.name,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['normalized'] = Variable<String>(normalized);
    map['name'] = Variable<String>(name);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  WorkCategoriesCompanion toCompanion(bool nullToAbsent) {
    return WorkCategoriesCompanion(
      normalized: Value(normalized),
      name: Value(name),
      archived: Value(archived),
    );
  }

  factory WorkCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkCategory(
      normalized: serializer.fromJson<String>(json['normalized']),
      name: serializer.fromJson<String>(json['name']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'normalized': serializer.toJson<String>(normalized),
      'name': serializer.toJson<String>(name),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  WorkCategory copyWith({String? normalized, String? name, bool? archived}) =>
      WorkCategory(
        normalized: normalized ?? this.normalized,
        name: name ?? this.name,
        archived: archived ?? this.archived,
      );
  WorkCategory copyWithCompanion(WorkCategoriesCompanion data) {
    return WorkCategory(
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
      name: data.name.present ? data.name.value : this.name,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkCategory(')
          ..write('normalized: $normalized, ')
          ..write('name: $name, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(normalized, name, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkCategory &&
          other.normalized == this.normalized &&
          other.name == this.name &&
          other.archived == this.archived);
}

class WorkCategoriesCompanion extends UpdateCompanion<WorkCategory> {
  final Value<String> normalized;
  final Value<String> name;
  final Value<bool> archived;
  final Value<int> rowid;
  const WorkCategoriesCompanion({
    this.normalized = const Value.absent(),
    this.name = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkCategoriesCompanion.insert({
    required String normalized,
    required String name,
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : normalized = Value(normalized),
       name = Value(name);
  static Insertable<WorkCategory> custom({
    Expression<String>? normalized,
    Expression<String>? name,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (normalized != null) 'normalized': normalized,
      if (name != null) 'name': name,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkCategoriesCompanion copyWith({
    Value<String>? normalized,
    Value<String>? name,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return WorkCategoriesCompanion(
      normalized: normalized ?? this.normalized,
      name: name ?? this.name,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkCategoriesCompanion(')
          ..write('normalized: $normalized, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WorklogDatabase extends GeneratedDatabase {
  _$WorklogDatabase(QueryExecutor e) : super(e);
  $WorklogDatabaseManager get managers => $WorklogDatabaseManager(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $WorkSchedulesTable workSchedules = $WorkSchedulesTable(this);
  late final $SheetSettingsTable sheetSettings = $SheetSettingsTable(this);
  late final $WorkCategoriesTable workCategories = $WorkCategoriesTable(this);
  late final Index entryStartIdx = Index(
    'entry_start_idx',
    'CREATE INDEX entry_start_idx ON entries (start_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activities,
    entries,
    workSchedules,
    sheetSettings,
    workCategories,
    entryStartIdx,
  ];
}

typedef $$ActivitiesTableCreateCompanionBuilder =
    ActivitiesCompanion Function({
      required String id,
      required String title,
      required String titleNorm,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$ActivitiesTableUpdateCompanionBuilder =
    ActivitiesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> titleNorm,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$ActivitiesTableReferences
    extends BaseReferences<_$WorklogDatabase, $ActivitiesTable, Activity> {
  $$ActivitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<WorkEntry>> _entriesRefsTable(
    _$WorklogDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'activities__id__entries__activity_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.activityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActivitiesTableFilterComposer
    extends Composer<_$WorklogDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleNorm => $composableBuilder(
    column: $table.titleNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$WorklogDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleNorm => $composableBuilder(
    column: $table.titleNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$WorklogDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleNorm =>
      $composableBuilder(column: $table.titleNorm, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.activityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$WorklogDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, $$ActivitiesTableReferences),
          Activity,
          PrefetchHooks Function({bool entriesRefs})
        > {
  $$ActivitiesTableTableManager(_$WorklogDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleNorm = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                title: title,
                titleNorm: titleNorm,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String titleNorm,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivitiesCompanion.insert(
                id: id,
                title: title,
                titleNorm: titleNorm,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, Activity>(table),
                  $$ActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedDataByColumns<
                      Activity,
                      $ActivitiesTable,
                      WorkEntry,
                      $EntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ActivitiesTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ActivitiesTableReferences(
                            db,
                            table,
                            p0,
                          ).entriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'activity_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$WorklogDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, $$ActivitiesTableReferences),
      Activity,
      PrefetchHooks Function({bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      required String activityId,
      required int startAt,
      Value<String?> note,
      Value<String?> category,
      Value<int?> endAt,
      Value<String?> deviceName,
      Value<String?> devicePlatform,
      Value<String?> originDevice,
      Value<String> sheetState,
      Value<int?> syncedAt,
      Value<String?> sheetError,
      required String tzName,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<String> activityId,
      Value<int> startAt,
      Value<String?> note,
      Value<String?> category,
      Value<int?> endAt,
      Value<String?> deviceName,
      Value<String?> devicePlatform,
      Value<String?> originDevice,
      Value<String> sheetState,
      Value<int?> syncedAt,
      Value<String?> sheetError,
      Value<String> tzName,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$WorklogDatabase, $EntriesTable, WorkEntry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ActivitiesTable _activityIdTable(_$WorklogDatabase db) =>
      db.activities.createAlias('entries__activity_id__activities__id');

  $$ActivitiesTableProcessedTableManager get activityId {
    final $_column = $_itemColumn<String>('activity_id')!;

    final manager = $$ActivitiesTableTableManager(
      $_db,
      $_db.activities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$WorklogDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devicePlatform => $composableBuilder(
    column: $table.devicePlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sheetState => $composableBuilder(
    column: $table.sheetState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sheetError => $composableBuilder(
    column: $table.sheetError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tzName => $composableBuilder(
    column: $table.tzName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ActivitiesTableFilterComposer get activityId {
    final $$ActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$WorklogDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devicePlatform => $composableBuilder(
    column: $table.devicePlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sheetState => $composableBuilder(
    column: $table.sheetState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sheetError => $composableBuilder(
    column: $table.sheetError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tzName => $composableBuilder(
    column: $table.tzName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ActivitiesTableOrderingComposer get activityId {
    final $$ActivitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableOrderingComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$WorklogDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devicePlatform => $composableBuilder(
    column: $table.devicePlatform,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sheetState => $composableBuilder(
    column: $table.sheetState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get sheetError => $composableBuilder(
    column: $table.sheetError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tzName =>
      $composableBuilder(column: $table.tzName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ActivitiesTableAnnotationComposer get activityId {
    final $$ActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activityId,
      referencedTable: $db.activities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.activities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$WorklogDatabase,
          $EntriesTable,
          WorkEntry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (WorkEntry, $$EntriesTableReferences),
          WorkEntry,
          PrefetchHooks Function({bool activityId})
        > {
  $$EntriesTableTableManager(_$WorklogDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> devicePlatform = const Value.absent(),
                Value<String?> originDevice = const Value.absent(),
                Value<String> sheetState = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<String?> sheetError = const Value.absent(),
                Value<String> tzName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                activityId: activityId,
                startAt: startAt,
                note: note,
                category: category,
                endAt: endAt,
                deviceName: deviceName,
                devicePlatform: devicePlatform,
                originDevice: originDevice,
                sheetState: sheetState,
                syncedAt: syncedAt,
                sheetError: sheetError,
                tzName: tzName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String activityId,
                required int startAt,
                Value<String?> note = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> devicePlatform = const Value.absent(),
                Value<String?> originDevice = const Value.absent(),
                Value<String> sheetState = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<String?> sheetError = const Value.absent(),
                required String tzName,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                activityId: activityId,
                startAt: startAt,
                note: note,
                category: category,
                endAt: endAt,
                deviceName: deviceName,
                devicePlatform: devicePlatform,
                originDevice: originDevice,
                sheetState: sheetState,
                syncedAt: syncedAt,
                sheetError: sheetError,
                tzName: tzName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, WorkEntry>(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (activityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.activityId,
                                referencedTable: $$EntriesTableReferences
                                    ._activityIdTable(db),
                                referencedColumn: $$EntriesTableReferences
                                    ._activityIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$WorklogDatabase,
      $EntriesTable,
      WorkEntry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (WorkEntry, $$EntriesTableReferences),
      WorkEntry,
      PrefetchHooks Function({bool activityId})
    >;
typedef $$WorkSchedulesTableCreateCompanionBuilder =
    WorkSchedulesCompanion Function({
      Value<int> id,
      required String workDays,
      required int startMinute,
      required int endMinute,
      required int intervalMinutes,
      required bool alignToWorkStart,
      required bool enabled,
    });
typedef $$WorkSchedulesTableUpdateCompanionBuilder =
    WorkSchedulesCompanion Function({
      Value<int> id,
      Value<String> workDays,
      Value<int> startMinute,
      Value<int> endMinute,
      Value<int> intervalMinutes,
      Value<bool> alignToWorkStart,
      Value<bool> enabled,
    });

class $$WorkSchedulesTableFilterComposer
    extends Composer<_$WorklogDatabase, $WorkSchedulesTable> {
  $$WorkSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workDays => $composableBuilder(
    column: $table.workDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alignToWorkStart => $composableBuilder(
    column: $table.alignToWorkStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkSchedulesTableOrderingComposer
    extends Composer<_$WorklogDatabase, $WorkSchedulesTable> {
  $$WorkSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workDays => $composableBuilder(
    column: $table.workDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alignToWorkStart => $composableBuilder(
    column: $table.alignToWorkStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkSchedulesTableAnnotationComposer
    extends Composer<_$WorklogDatabase, $WorkSchedulesTable> {
  $$WorkSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workDays =>
      $composableBuilder(column: $table.workDays, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get alignToWorkStart => $composableBuilder(
    column: $table.alignToWorkStart,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$WorkSchedulesTableTableManager
    extends
        RootTableManager<
          _$WorklogDatabase,
          $WorkSchedulesTable,
          WorkSchedule,
          $$WorkSchedulesTableFilterComposer,
          $$WorkSchedulesTableOrderingComposer,
          $$WorkSchedulesTableAnnotationComposer,
          $$WorkSchedulesTableCreateCompanionBuilder,
          $$WorkSchedulesTableUpdateCompanionBuilder,
          (
            WorkSchedule,
            BaseReferences<
              _$WorklogDatabase,
              $WorkSchedulesTable,
              WorkSchedule
            >,
          ),
          WorkSchedule,
          PrefetchHooks Function()
        > {
  $$WorkSchedulesTableTableManager(
    _$WorklogDatabase db,
    $WorkSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workDays = const Value.absent(),
                Value<int> startMinute = const Value.absent(),
                Value<int> endMinute = const Value.absent(),
                Value<int> intervalMinutes = const Value.absent(),
                Value<bool> alignToWorkStart = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
              }) => WorkSchedulesCompanion(
                id: id,
                workDays: workDays,
                startMinute: startMinute,
                endMinute: endMinute,
                intervalMinutes: intervalMinutes,
                alignToWorkStart: alignToWorkStart,
                enabled: enabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workDays,
                required int startMinute,
                required int endMinute,
                required int intervalMinutes,
                required bool alignToWorkStart,
                required bool enabled,
              }) => WorkSchedulesCompanion.insert(
                id: id,
                workDays: workDays,
                startMinute: startMinute,
                endMinute: endMinute,
                intervalMinutes: intervalMinutes,
                alignToWorkStart: alignToWorkStart,
                enabled: enabled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkSchedulesTable, WorkSchedule>(table),
                  BaseReferences<
                    _$WorklogDatabase,
                    $WorkSchedulesTable,
                    WorkSchedule
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$WorklogDatabase,
      $WorkSchedulesTable,
      WorkSchedule,
      $$WorkSchedulesTableFilterComposer,
      $$WorkSchedulesTableOrderingComposer,
      $$WorkSchedulesTableAnnotationComposer,
      $$WorkSchedulesTableCreateCompanionBuilder,
      $$WorkSchedulesTableUpdateCompanionBuilder,
      (
        WorkSchedule,
        BaseReferences<_$WorklogDatabase, $WorkSchedulesTable, WorkSchedule>,
      ),
      WorkSchedule,
      PrefetchHooks Function()
    >;
typedef $$SheetSettingsTableCreateCompanionBuilder =
    SheetSettingsCompanion Function({
      Value<int> id,
      required String deviceId,
      Value<String?> deviceLabel,
      Value<String?> account,
      Value<String?> spreadsheet,
      Value<String?> error,
    });
typedef $$SheetSettingsTableUpdateCompanionBuilder =
    SheetSettingsCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String?> deviceLabel,
      Value<String?> account,
      Value<String?> spreadsheet,
      Value<String?> error,
    });

class $$SheetSettingsTableFilterComposer
    extends Composer<_$WorklogDatabase, $SheetSettingsTable> {
  $$SheetSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spreadsheet => $composableBuilder(
    column: $table.spreadsheet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SheetSettingsTableOrderingComposer
    extends Composer<_$WorklogDatabase, $SheetSettingsTable> {
  $$SheetSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spreadsheet => $composableBuilder(
    column: $table.spreadsheet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SheetSettingsTableAnnotationComposer
    extends Composer<_$WorklogDatabase, $SheetSettingsTable> {
  $$SheetSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get spreadsheet => $composableBuilder(
    column: $table.spreadsheet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$SheetSettingsTableTableManager
    extends
        RootTableManager<
          _$WorklogDatabase,
          $SheetSettingsTable,
          SheetSetting,
          $$SheetSettingsTableFilterComposer,
          $$SheetSettingsTableOrderingComposer,
          $$SheetSettingsTableAnnotationComposer,
          $$SheetSettingsTableCreateCompanionBuilder,
          $$SheetSettingsTableUpdateCompanionBuilder,
          (
            SheetSetting,
            BaseReferences<
              _$WorklogDatabase,
              $SheetSettingsTable,
              SheetSetting
            >,
          ),
          SheetSetting,
          PrefetchHooks Function()
        > {
  $$SheetSettingsTableTableManager(
    _$WorklogDatabase db,
    $SheetSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheetSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheetSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheetSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> deviceLabel = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<String?> spreadsheet = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SheetSettingsCompanion(
                id: id,
                deviceId: deviceId,
                deviceLabel: deviceLabel,
                account: account,
                spreadsheet: spreadsheet,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                Value<String?> deviceLabel = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<String?> spreadsheet = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => SheetSettingsCompanion.insert(
                id: id,
                deviceId: deviceId,
                deviceLabel: deviceLabel,
                account: account,
                spreadsheet: spreadsheet,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SheetSettingsTable, SheetSetting>(table),
                  BaseReferences<
                    _$WorklogDatabase,
                    $SheetSettingsTable,
                    SheetSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SheetSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$WorklogDatabase,
      $SheetSettingsTable,
      SheetSetting,
      $$SheetSettingsTableFilterComposer,
      $$SheetSettingsTableOrderingComposer,
      $$SheetSettingsTableAnnotationComposer,
      $$SheetSettingsTableCreateCompanionBuilder,
      $$SheetSettingsTableUpdateCompanionBuilder,
      (
        SheetSetting,
        BaseReferences<_$WorklogDatabase, $SheetSettingsTable, SheetSetting>,
      ),
      SheetSetting,
      PrefetchHooks Function()
    >;
typedef $$WorkCategoriesTableCreateCompanionBuilder =
    WorkCategoriesCompanion Function({
      required String normalized,
      required String name,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$WorkCategoriesTableUpdateCompanionBuilder =
    WorkCategoriesCompanion Function({
      Value<String> normalized,
      Value<String> name,
      Value<bool> archived,
      Value<int> rowid,
    });

class $$WorkCategoriesTableFilterComposer
    extends Composer<_$WorklogDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkCategoriesTableOrderingComposer
    extends Composer<_$WorklogDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkCategoriesTableAnnotationComposer
    extends Composer<_$WorklogDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$WorkCategoriesTableTableManager
    extends
        RootTableManager<
          _$WorklogDatabase,
          $WorkCategoriesTable,
          WorkCategory,
          $$WorkCategoriesTableFilterComposer,
          $$WorkCategoriesTableOrderingComposer,
          $$WorkCategoriesTableAnnotationComposer,
          $$WorkCategoriesTableCreateCompanionBuilder,
          $$WorkCategoriesTableUpdateCompanionBuilder,
          (
            WorkCategory,
            BaseReferences<
              _$WorklogDatabase,
              $WorkCategoriesTable,
              WorkCategory
            >,
          ),
          WorkCategory,
          PrefetchHooks Function()
        > {
  $$WorkCategoriesTableTableManager(
    _$WorklogDatabase db,
    $WorkCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> normalized = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkCategoriesCompanion(
                normalized: normalized,
                name: name,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String normalized,
                required String name,
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkCategoriesCompanion.insert(
                normalized: normalized,
                name: name,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkCategoriesTable, WorkCategory>(table),
                  BaseReferences<
                    _$WorklogDatabase,
                    $WorkCategoriesTable,
                    WorkCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$WorklogDatabase,
      $WorkCategoriesTable,
      WorkCategory,
      $$WorkCategoriesTableFilterComposer,
      $$WorkCategoriesTableOrderingComposer,
      $$WorkCategoriesTableAnnotationComposer,
      $$WorkCategoriesTableCreateCompanionBuilder,
      $$WorkCategoriesTableUpdateCompanionBuilder,
      (
        WorkCategory,
        BaseReferences<_$WorklogDatabase, $WorkCategoriesTable, WorkCategory>,
      ),
      WorkCategory,
      PrefetchHooks Function()
    >;

class $WorklogDatabaseManager {
  final _$WorklogDatabase _db;
  $WorklogDatabaseManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$WorkSchedulesTableTableManager get workSchedules =>
      $$WorkSchedulesTableTableManager(_db, _db.workSchedules);
  $$SheetSettingsTableTableManager get sheetSettings =>
      $$SheetSettingsTableTableManager(_db, _db.sheetSettings);
  $$WorkCategoriesTableTableManager get workCategories =>
      $$WorkCategoriesTableTableManager(_db, _db.workCategories);
}
