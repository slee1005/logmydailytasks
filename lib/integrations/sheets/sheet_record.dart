import 'package:intl/intl.dart';

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
  int start,
  int? end,
  String zone,
  String device,
  String platform,
  String deviceId,
  int updated,
  bool deleted,
});

List<Object> encodeSheetRecord(SheetRecord record) {
  DateTime utc(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  final start = inWorkZone(utc(record.start), record.zone);
  final end = record.end;
  final time = DateFormat('HH:mm', 'en_US');
  return [
    record.id,
    DateFormat('yyyy-MM-dd', 'en_US').format(start),
    time.format(start),
    end == null ? '' : time.format(inWorkZone(utc(end), record.zone)),
    end == null ? '' : (end - record.start) ~/ 60000,
    '',
    '',
    record.title,
    '',
    'checkin',
    'logged',
    record.device,
    record.platform,
    utc(record.updated).toIso8601String(),
    record.deleted,
    record.deviceId,
    utc(record.start).toIso8601String(),
    end == null ? '' : utc(end).toIso8601String(),
    record.zone,
  ];
}

SheetRecord? decodeSheetRecord(List<Object?> row) {
  if (row.length < logHeaders.length) return null;
  String cell(int index) => row[index]?.toString() ?? '';
  int? millis(int index) =>
      DateTime.tryParse(cell(index))?.millisecondsSinceEpoch;
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
