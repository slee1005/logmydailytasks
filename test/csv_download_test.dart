import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/features/export/csv_export_button.dart';

void main() {
  test(
    'CSV exports keep their contents and do not overwrite earlier files',
    () async {
      final directory = await Directory.systemTemp.createTemp('worklog-csv-');
      addTearDown(() => directory.delete(recursive: true));
      final original = Uint8List.fromList(utf8.encode('activity\r\n업무\r\n'));
      final updated = Uint8List.fromList(utf8.encode('activity\r\n회의\r\n'));

      expect(
        await saveCsvFile(directory, 'report.csv', original),
        'report.csv',
      );
      expect(
        await saveCsvFile(directory, 'report.csv', updated),
        'report (2).csv',
      );
      expect(
        await File('${directory.path}/report.csv').readAsBytes(),
        original,
      );
      expect(
        await File('${directory.path}/report (2).csv').readAsBytes(),
        updated,
      );
    },
  );
}
