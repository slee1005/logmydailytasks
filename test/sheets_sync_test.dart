import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logmydailytask/data/db/database.dart';
import 'package:logmydailytask/integrations/sheets/sheet_record.dart';
import 'package:logmydailytask/integrations/sheets/sheets_api.dart';

void main() {
  test('two devices share a sheet and update by ID after a sort', () async {
    final a = WorklogDatabase(NativeDatabase.memory());
    final b = WorklogDatabase(NativeDatabase.memory());
    addTearDown(a.close);
    addTearDown(b.close);
    final rows = <List<Object?>>[logHeaders];
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        if (!request.url.path.contains('/values/')) {
          return http.Response(
            jsonEncode({
              'sheets': [
                {
                  'properties': {'sheetId': 7, 'title': 'Log'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'values': rows}), 200);
      }
      final body = jsonDecode(request.body) as Map;
      if (body.containsKey('requests')) {
        expect(body['requests'], isNotEmpty);
        return http.Response('{}', 200);
      }
      expect(
        request.url.queryParameters['valueInputOption'] ??
            body['valueInputOption'],
        'RAW',
      );
      if (request.url.path.endsWith(':append')) {
        rows.addAll((body['values'] as List).cast<List<Object?>>());
      } else {
        for (final update in body['data'] as List) {
          final index = int.parse(
            RegExp(r'A(\d+)').firstMatch(update['range'])!.group(1)!,
          );
          rows[index - 1] = (update['values'] as List).single as List<Object?>;
        }
      }
      return http.Response('{}', 200);
    });
    final api = SheetsApi(client);
    final time = DateTime.utc(2026, 11, 13, 12);
    Future<void> sync(WorklogDatabase db) async {
      final settings = await db.ensureSheetSettings();
      final records = await db.pendingSheetRecords(settings);
      final incoming = await api.reconcile('shared', records);
      await db.importSheetRecords(incoming, settings.deviceId);
      await db.markSheetRecords(records);
    }

    await a.saveCheckIn(title: 'Mac work', at: time, tzName: 'Etc/UTC');
    await a.renameSheetDevice('Mac');
    await a.linkSheet('account@example.test', 'shared');
    await sync(a);
    await b.renameSheetDevice('Phone');
    await b.linkSheet('account@example.test', 'shared');
    await b.saveCheckIn(title: 'Phone work', at: time, tzName: 'Etc/UTC');
    await sync(b);
    expect(
      (await b.exportEntries(
        time,
        time.add(const Duration(days: 1)),
      )).map((row) => (row.device, row.sheetState)),
      unorderedEquals([('Mac', 'synced'), ('Phone', 'synced')]),
    );

    final originalId = rows[1].first;
    rows.add(rows.removeAt(1));
    await a.renameSheetDevice('MacBook');
    await sync(a);
    expect(rows, hasLength(3));
    expect(rows[2].first, originalId);
    expect(rows[2][11], 'MacBook');
    expect(rows[1][11], 'Phone');
    expect(await a.pendingSheetRecords(await a.ensureSheetSettings()), isEmpty);

    await a.saveCheckIn(
      title: 'Next Mac task',
      at: time.add(const Duration(minutes: 45)),
      tzName: 'Etc/UTC',
    );
    await sync(a);
    final previousMac = rows.singleWhere((row) => row.first == originalId);
    expect(previousMac[3], isA<num>());
    expect(previousMac[4], 45);
    expect(
      decodeSheetRecord(previousMac)?.end,
      time.add(const Duration(minutes: 45)).millisecondsSinceEpoch,
    );
    final phone = rows.singleWhere((row) => row[11] == 'Phone');
    expect(phone[3], '');
    expect(phone[4], '');
  });

  test('permission errors are surfaced before a write', () async {
    final api = SheetsApi(MockClient((_) async => http.Response('{}', 403)));
    await expectLater(
      api.reconcile('shared', []),
      throwsA(
        isA<SheetsFailure>().having(
          (error) => error.requiresSignIn,
          'requiresSignIn',
          true,
        ),
      ),
    );
  });
}
