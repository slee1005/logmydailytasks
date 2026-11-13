import 'package:intl/intl.dart';

import '../core/work_time.dart';

typedef CsvWorkEntry = ({
  String id,
  DateTime start,
  DateTime? end,
  String zone,
  String title,
  String? note,
  String? category,
  String device,
  String platform,
  String sheetState,
  int? syncedAt,
});

String worklogCsv(Iterable<CsvWorkEntry> entries, List<String> headers) {
  String quote(String value) {
    // Spreadsheet programs can execute a leading formula in text cells.
    final safe =
        RegExp(r'^\s*[=+@-]|^[\t\r\n]').hasMatch(value) &&
            !RegExp(r'^-\d+$').hasMatch(value)
        ? "'$value"
        : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm');
  final rows = [
    headers,
    for (final row in entries)
      [
        row.id,
        dateFormat.format(inWorkZone(row.start, row.zone)),
        timeFormat.format(inWorkZone(row.start, row.zone)),
        if (row.end case final end?) ...[
          timeFormat.format(inWorkZone(end, row.zone)),
          end.difference(row.start).inMinutes.toString(),
        ] else ...[
          '',
          '',
        ],
        row.category ?? '',
        row.title,
        row.note ?? '',
        'checkin',
        'logged',
        row.device,
        row.platform,
        row.sheetState == 'none' ? 'not_linked' : row.sheetState,
        row.syncedAt == null
            ? ''
            : DateTime.fromMillisecondsSinceEpoch(
                row.syncedAt!,
                isUtc: true,
              ).toIso8601String(),
      ],
  ];
  return '\uFEFF${rows.map((row) => row.map(quote).join(',')).join('\r\n')}\r\n';
}
