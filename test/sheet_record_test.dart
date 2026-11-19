import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/integrations/sheets/sheet_record.dart';

void main() {
  final start = DateTime.utc(2026, 11, 19, 15, 35, 22, 123);
  final SheetRecord record = (
    id: 'entry',
    title: 'Review report',
    note: 'Keep the original note',
    category: 'Reports',
    start: start.millisecondsSinceEpoch,
    end: start
        .add(const Duration(minutes: 45, seconds: 30))
        .millisecondsSinceEpoch,
    zone: 'America/Los_Angeles',
    device: 'Mac',
    platform: 'macOS',
    deviceId: 'device',
    updated: start.add(const Duration(hours: 1)).millisecondsSinceEpoch,
    deleted: false,
  );

  test('writes numeric dates with seconds and actual elapsed minutes', () {
    final row = encodeSheetRecord(record);
    final day = DateTime.utc(
      2026,
      11,
      19,
    ).difference(DateTime.utc(1899, 12, 30)).inDays;
    expect(row[1], day);
    expect(row[2], closeTo(day + 7 / 24 + 35 / 1440 + 22.123 / 86400, 1e-9));
    expect(row[3], isA<num>());
    expect(row[4], 45.5);
    for (final column in [13, 16, 17]) {
      expect(row[column], isA<num>());
    }
    expect(decodeSheetRecord(row), record);
  });

  test('reads existing ISO timestamps and rejects invalid numeric dates', () {
    final row = encodeSheetRecord(record);
    row[1] = '2026-11-19';
    row[2] = '07:35';
    row[3] = '08:20';
    row[13] = DateTime.fromMillisecondsSinceEpoch(
      record.updated,
      isUtc: true,
    ).toIso8601String();
    row[16] = start.toIso8601String();
    row[17] = DateTime.fromMillisecondsSinceEpoch(
      record.end!,
      isUtc: true,
    ).toIso8601String();
    expect(decodeSheetRecord(row), record);
    row[16] = double.nan;
    expect(decodeSheetRecord(row), isNull);
    row[16] = double.infinity;
    expect(decodeSheetRecord(row), isNull);
  });

  test('combines existing calendar date and numeric time values', () {
    final day = DateTime.utc(
      2026,
      11,
      19,
    ).difference(DateTime.utc(1899, 12, 30)).inDays;
    final row = List<Object?>.filled(19, '');
    row[0] = 'calendar-event';
    row[1] = day;
    row[2] = 7.5 / 24;
    row[3] = 8.25 / 24;
    row[4] = 45;
    row[7] = 'Existing meeting';
    row[8] = 'Existing note';
    row[9] = 'Outlook';
    row[16] = '2026-11-19T15:30:00Z';
    row[17] = '2026-11-19T16:15:00Z';
    row[18] = 'America/Los_Angeles';
    final normalized = normalizeSheetDates(row);
    expect(normalized[2], closeTo(day + 7.5 / 24, 1e-9));
    expect(normalized[3], closeTo(day + 8.25 / 24, 1e-9));
    expect(normalized[4], 45);
    expect(normalized[16], closeTo(day + 15.5 / 24, 1e-9));
    expect(normalized[17], closeTo(day + 16.25 / 24, 1e-9));
    for (final column in [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18]) {
      expect(normalized[column], row[column]);
    }
    expect(normalizeSheetDates(normalized), normalized);
  });

  test('converts calendar time strings and preserves overnight boundaries', () {
    final row = <Object?>[
      'calendar-event',
      '2026-11-19',
      '23:30:00',
      '00:15:00',
      '45',
    ];
    final normalized = normalizeSheetDates(row);
    final day = normalized[1] as num;
    expect(normalized[2], closeTo(day + 23.5 / 24, 1e-9));
    expect(normalized[3], closeTo(day + 1 + 0.25 / 24, 1e-9));
    expect(normalized[4], 45);
    expect(normalizeSheetDates(normalized), normalized);
  });

  test('calculates minutes across a daylight saving time change in UTC', () {
    final start = DateTime.utc(2026, 11, 1, 8, 30);
    final end = DateTime.utc(2026, 11, 1, 9, 45);
    final crossing = (
      id: record.id,
      title: record.title,
      note: record.note,
      category: record.category,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      zone: record.zone,
      device: record.device,
      platform: record.platform,
      deviceId: record.deviceId,
      updated: end.millisecondsSinceEpoch,
      deleted: false,
    );
    final row = encodeSheetRecord(crossing);
    expect(row[4], 75);
    expect(((row[3] as num) - (row[2] as num)) * 1440, closeTo(15, 1e-6));
    expect(decodeSheetRecord(row), crossing);
  });

  test(
    'normalizes legacy calendar AM and PM times including noon and midnight',
    () {
      for (final (start, end, startHour, endHour) in [
        ('9:30:00 AM', '10:00:00 AM', 9.5, 10.0),
        ('12:00:00 PM', '1:00:00 pm', 12.0, 13.0),
        ('11:30 PM', '12:15 AM', 23.5, 24.25),
        ('12:00 AM', '12:00 PM', 0.0, 12.0),
      ]) {
        final normalized = normalizeSheetDates([
          'calendar-event',
          '2026-11-18',
          start,
          end,
          '',
        ]);
        final day = normalized[1] as num;
        expect(normalized[2], closeTo(day + startHour / 24, 1e-9));
        expect(normalized[3], closeTo(day + endHour / 24, 1e-9));
        expect(normalizeSheetDates(normalized), normalized);
      }
    },
  );
}
