import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logmydailytask/integrations/sheets/sheet_record.dart';
import 'package:logmydailytask/integrations/sheets/sheets_api.dart';

http.Response response(Object data) => http.Response(jsonEncode(data), 200);

const logMetadata = {
  'sheets': [
    {
      'properties': {'sheetId': 42, 'title': 'Log'},
    },
  ],
};

void main() {
  test(
    'converts existing timestamps without rewriting other log fields',
    () async {
      final legacy = <Object?>[
        'existing-id',
        '2026-11-19',
        '07:30',
        '08:15',
        45,
        'Reports',
        'Keep this project',
        'Keep this title',
        'Keep this note',
        'manual',
        'reviewed',
        'Mac',
        'macOS',
        '2026-11-19T16:15:00.000Z',
        false,
        'device',
        '2026-11-19T15:30:00.000Z',
        '2026-11-19T16:15:00.000Z',
        'America/Los_Angeles',
      ];
      final original = List<Object?>.of(legacy);
      final invalid = List<Object?>.of(legacy)
        ..[16] = 'invalid original timestamp';
      final invalidOriginal = List<Object?>.of(invalid);
      final rows = <List<Object?>>[logHeaders, legacy, invalid];
      final batches = <List<dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/values/')) {
          expect(
            request.url.queryParameters['dateTimeRenderOption'],
            'SERIAL_NUMBER',
          );
          return response({'values': rows});
        }
        if (request.method == 'GET') {
          return response({
            'sheets': [
              {
                'properties': {'sheetId': 42, 'title': 'Log'},
                'data': [
                  {
                    'startColumn': 1,
                    'columnMetadata': [
                      {'pixelSize': 260},
                      {'pixelSize': 260},
                      {'pixelSize': 80},
                    ],
                  },
                ],
              },
            ],
          });
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/v4/spreadsheets/existing:batchUpdate');
        final requests = (jsonDecode(request.body) as Map)['requests'] as List;
        batches.add(requests);
        for (final item in requests) {
          if (item['repeatCell'] case final Map format) {
            expect(format['range']['sheetId'], 42);
            expect(format['range']['startRowIndex'], 1);
            expect(format['fields'], 'userEnteredFormat.numberFormat');
          }
          if (item['updateCells'] case final Map update) {
            expect(update['fields'], 'userEnteredValue');
            final row = update['start']['rowIndex'] as int;
            final column = update['start']['columnIndex'] as int;
            final values = update['rows'][0]['values'] as List;
            for (var index = 0; index < values.length; index++) {
              final value = values[index]['userEnteredValue'] as Map;
              rows[row][column + index] =
                  value['numberValue'] ?? value['stringValue'];
            }
          }
        }
        return response({});
      });
      addTearDown(client.close);
      final api = SheetsApi(client);
      await api.verify('existing');
      for (final column in [1, 2, 3, 4, 13, 16, 17]) {
        expect(rows[1][column], isA<num>());
      }
      for (final column in [0, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 18]) {
        expect(rows[1][column], original[column]);
      }
      expect(rows[2], invalidOriginal);
      expect(decodeSheetRecord(rows[1]), decodeSheetRecord(original));
      final formats = batches.single
          .where((request) => request['repeatCell'] != null)
          .map((request) => request['repeatCell'] as Map)
          .toList();
      expect(formats.map((format) => format['range']['startColumnIndex']), [
        1,
        2,
        4,
        13,
        16,
      ]);
      expect(formats[1]['cell']['userEnteredFormat']['numberFormat'], {
        'type': 'DATE_TIME',
        'pattern': 'yyyy-mm-dd hh:mm:ss',
      });
      final resized = batches.single
          .where((request) => request['updateDimensionProperties'] != null)
          .map((request) => request['updateDimensionProperties'] as Map)
          .toList();
      expect(
        resized.any((request) => request['range']['startIndex'] == 1),
        isFalse,
      );
      expect(
        resized.any((request) => request['range']['startIndex'] == 2),
        isFalse,
      );
      expect(
        resized.singleWhere(
          (request) => request['range']['startIndex'] == 3,
        )['properties']['pixelSize'],
        180,
      );
      await api.verify('existing');
      expect(
        batches.last.where((request) => request['updateCells'] != null),
        isEmpty,
      );
    },
  );

  test(
    'retries a partially converted history without losing log rows',
    () async {
      final start = DateTime.utc(2026, 11, 19, 15, 30);
      final end = start.add(const Duration(minutes: 45));
      final rows = <List<Object?>>[
        logHeaders,
        for (var index = 0; index < 200; index++)
          encodeSheetRecord((
              id: 'entry-$index',
              title: 'Preserve task $index',
              note: 'Preserve note $index',
              category: 'Reports',
              start: start.millisecondsSinceEpoch,
              end: end.millisecondsSinceEpoch,
              zone: 'America/Los_Angeles',
              device: 'Mac',
              platform: 'macOS',
              deviceId: 'device',
              updated: end.millisecondsSinceEpoch,
              deleted: false,
            ))
            ..[1] = '2026-11-19'
            ..[2] = '07:30'
            ..[3] = '08:15'
            ..[13] = end.toIso8601String()
            ..[16] = start.toIso8601String()
            ..[17] = end.toIso8601String(),
      ];
      final sizes = <int>[];
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.contains('/values/')) {
          return response({'values': rows});
        }
        if (request.method == 'GET') return response(logMetadata);
        final requests = (jsonDecode(request.body) as Map)['requests'] as List;
        sizes.add(requests.length);
        if (sizes.length == 2) return http.Response('{}', 503);
        for (final item in requests) {
          if (item['updateCells'] case final Map update) {
            final row = update['start']['rowIndex'] as int;
            final column = update['start']['columnIndex'] as int;
            final values = update['rows'][0]['values'] as List;
            for (var index = 0; index < values.length; index++) {
              final value = values[index]['userEnteredValue'] as Map;
              rows[row][column + index] =
                  value['numberValue'] ?? value['stringValue'];
            }
          }
        }
        return response({});
      });
      addTearDown(client.close);
      final api = SheetsApi(client);
      await expectLater(
        api.verify('history'),
        throwsA(
          isA<SheetsFailure>().having((error) => error.status, 'status', 503),
        ),
      );
      await api.verify('history');
      expect(sizes, hasLength(3));
      expect(sizes.first, 500);
      expect(sizes.every((size) => size <= 500), isTrue);
      expect(rows, hasLength(201));
      for (var index = 1; index < rows.length; index++) {
        final record = decodeSheetRecord(rows[index]);
        expect(record?.id, 'entry-${index - 1}');
        expect(record?.note, 'Preserve note ${index - 1}');
        expect(rows[index][16], isA<num>());
        expect(rows[index][17], isA<num>());
      }
    },
  );

  for (final (names, expected) in [
    (<String>[], 'LogMyDailyTask'),
    (['LogMyDailyTask'], 'LogMyDailyTask_v001'),
    (['LogMyDailyTask_v001'], 'LogMyDailyTask_v002'),
    (
      ['LogMyDailyTask', 'LogMyDailyTask_v001', 'LogMyDailyTask_v003'],
      'LogMyDailyTask_v004',
    ),
    (['LogMyDailyTask', 'LogMyDailyTask_v999'], 'LogMyDailyTask_v1000'),
  ]) {
    test(
      'creates $expected while preserving ${names.length} existing files',
      () async {
        var createdName = '';
        var creations = 0;
        final writes = <http.Request>[];
        final files = [
          for (final (index, name) in names.indexed)
            {
              'id': 'old-$index',
              'name': name,
              'createdTime': '2026-11-18T00:00:00Z',
            },
        ];
        final client = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.host == 'www.googleapis.com') {
            expect(
              request.url.queryParameters['q'],
              isNot(contains('appProperties')),
            );
            final visible = [
              ...files,
              if (creations > 0)
                {
                  'id': 'new',
                  'name': createdName,
                  'createdTime': '2026-11-19T00:00:00Z',
                },
            ];
            if (request.url.queryParameters['pageToken'] == 'rest') {
              return response({'files': visible.skip(1).toList()});
            }
            return response({
              'files': visible.take(1).toList(),
              if (visible.length > 1) 'nextPageToken': 'rest',
            });
          }
          if (request.method == 'GET') return response(logMetadata);
          writes.add(request);
          final body = jsonDecode(request.body) as Map;
          if (request.url.path == '/v4/spreadsheets') {
            creations++;
            createdName = body['properties']['title'] as String;
            return response({'spreadsheetId': 'new'});
          }
          if (request.method == 'PATCH') {
            expect(request.url.path, '/drive/v3/files/new');
            expect(body['appProperties'], {'logmydailytask': 'v1'});
            return response({
              'id': 'new',
              'name': createdName,
              'createdTime': '2026-11-19T00:00:00Z',
            });
          }
          expect(request.url.path, startsWith('/v4/spreadsheets/new'));
          return response({});
        });
        addTearDown(client.close);
        expect(await SheetsApi(client).create(), 'new');
        expect(createdName, expected);
        expect(creations, 1);
        expect(files.map((file) => file['name']), names);
        expect(
          writes.any((request) => request.url.path.contains('/old-')),
          isFalse,
        );
      },
    );
  }

  test(
    'resolves a simultaneous name collision by renaming only the new file',
    () async {
      var reads = 0;
      var name = '';
      final renamed = <String>[];
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.host == 'www.googleapis.com') {
          reads++;
          return response({
            'files': [
              if (reads > 1) ...[
                {
                  'id': 'existing',
                  'name': 'LogMyDailyTask',
                  'createdTime': '2026-11-19T00:00:00.000Z',
                },
                {
                  'id': 'new',
                  'name': name,
                  'createdTime': '2026-11-19T00:00:00.001Z',
                },
              ],
            ],
          });
        }
        if (request.method == 'GET') return response(logMetadata);
        final body = jsonDecode(request.body) as Map;
        if (request.url.path == '/v4/spreadsheets') {
          name = body['properties']['title'] as String;
          return response({'spreadsheetId': 'new'});
        }
        if (request.method == 'PATCH') {
          expect(request.url.path, '/drive/v3/files/new');
          if (body['name'] case final String changed) {
            name = changed;
            renamed.add(name);
          }
          return response({
            'id': 'new',
            'name': name,
            'createdTime': '2026-11-19T00:00:00.001Z',
          });
        }
        return response({});
      });
      addTearDown(client.close);
      expect(await SheetsApi(client).create(), 'new');
      expect(renamed, ['LogMyDailyTask_v001']);
    },
  );
}
