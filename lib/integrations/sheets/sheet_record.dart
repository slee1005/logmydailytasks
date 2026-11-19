import '../../core/work_time.dart';

const logHeaders = [
  'entry_id',
  'date',
  'start',
  'end',
  'minutes',
  'category',
  'project',
  'description',
  'note',
  'source',
  'status',
  'device_name',
  'device_platform',
  'updated_utc',
  'deleted',
  'device_id',
  'start_utc',
  'end_utc',
  'time_zone',
];

typedef SheetRecord = ({
  String id,
  String title,
  String? note,
  String? category,
  int start,
  int? end,
  String zone,
  String device,
  String platform,
  String deviceId,
  int updated,
  bool deleted,
});

final _sheetEpoch = DateTime.utc(1899, 12, 30);

double _dateTimeSerial(DateTime value) =>
    DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
    ).difference(_sheetEpoch).inMilliseconds /
    Duration.millisecondsPerDay;

int? _timestamp(Object? value) {
  if (value is num) {
    final milliseconds =
        value * Duration.millisecondsPerDay +
        _sheetEpoch.millisecondsSinceEpoch;
    if (!milliseconds.isFinite || milliseconds.abs() > 8640000000000000) {
      return null;
    }
    return milliseconds.round();
  }
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return parsed.isUtc
      ? parsed.millisecondsSinceEpoch
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        ).millisecondsSinceEpoch;
}

double? _timeFraction(Object? value) {
  if (value is num) {
    return value.isFinite && value >= 0 && value <= 1 ? value.toDouble() : null;
  }
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3}))?)?\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(value?.toString().trim() ?? '');
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final second = int.parse(match.group(3) ?? '0');
  final millisecond = int.parse((match.group(4) ?? '').padRight(3, '0'));
  final period = match.group(5)?.toUpperCase();
  if (period != null) {
    if (hour < 1 || hour > 12) return null;
    hour = hour % 12 + (period == 'PM' ? 12 : 0);
  }
  if (hour > 23 || minute > 59 || second > 59) return null;
  return Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond,
      ).inMilliseconds /
      Duration.millisecondsPerDay;
}

List<Object?> normalizeSheetDates(List<Object?> row) {
  final values = List<Object?>.of(row);
  final record = decodeSheetRecord(row);
  if (record != null) {
    final encoded = encodeSheetRecord(record);
    for (final column in [1, 2, 3, 4, 13, 16, 17]) {
      values[column] = encoded[column];
    }
    return values;
  }
  if (row.length < 5 ||
      (row.length > 15 && row[15]?.toString().isNotEmpty == true)) {
    return values;
  }
  for (final column in [13, 16, 17]) {
    if (column >= row.length) continue;
    final timestamp = _timestamp(row[column]);
    if (timestamp != null) {
      values[column] = _dateTimeSerial(
        DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
      );
    }
  }
  final date = row[1];
  final parsed = date is String ? DateTime.tryParse(date) : null;
  int? day;
  if (date is num && date.isFinite && date > 1) {
    day = date.floor();
  } else if (parsed != null) {
    day = _dateTimeSerial(
      DateTime.utc(parsed.year, parsed.month, parsed.day),
    ).floor();
  }
  if (day == null) return values;
  final start = _timeFraction(row[2]);
  final end = _timeFraction(row[3]);
  values[1] = day;
  if (start != null) values[2] = day + start;
  if (end != null) {
    final startValue = values[2];
    final endValue = day + end;
    values[3] = startValue is num && endValue < startValue
        ? endValue + 1
        : endValue;
  }
  if (row[4] is String) {
    final minutes = num.tryParse((row[4] as String).trim());
    if (minutes != null && minutes.isFinite) values[4] = minutes;
  }
  return values;
}

List<Object> encodeSheetRecord(SheetRecord record) {
  DateTime utc(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  final start = inWorkZone(utc(record.start), record.zone);
  final end = record.end;
  final startSerial = _dateTimeSerial(start);
  return [
    record.id,
    startSerial.floor(),
    startSerial,
    end == null ? '' : _dateTimeSerial(inWorkZone(utc(end), record.zone)),
    end == null ? '' : (end - record.start) / Duration.millisecondsPerMinute,
    record.category ?? '',
    '',
    record.title,
    record.note ?? '',
    'checkin',
    'logged',
    record.device,
    record.platform,
    _dateTimeSerial(utc(record.updated)),
    record.deleted,
    record.deviceId,
    _dateTimeSerial(utc(record.start)),
    end == null ? '' : _dateTimeSerial(utc(end)),
    record.zone,
  ];
}

SheetRecord? decodeSheetRecord(List<Object?> row) {
  if (row.length < logHeaders.length) return null;
  String cell(int index) => row[index]?.toString() ?? '';
  int? millis(int index) => _timestamp(row[index]);
  final id = cell(0), deviceId = cell(15), title = cell(7);
  final start = millis(16), updated = millis(13), end = millis(17);
  final zone = cell(18);
  if (id.isEmpty ||
      deviceId.isEmpty ||
      title.trim().isEmpty ||
      start == null ||
      updated == null ||
      !workTimeZones.containsKey(zone) ||
      (cell(17).isNotEmpty && (end == null || end <= start))) {
    return null;
  }
  return (
    id: id,
    title: title,
    note: cell(8).isEmpty ? null : cell(8),
    category: cell(5).isEmpty ? null : cell(5),
    start: start,
    end: end,
    zone: zone,
    device: cell(11),
    platform: cell(12),
    deviceId: deviceId,
    updated: updated,
    deleted: cell(14).toLowerCase() == 'true',
  );
}
