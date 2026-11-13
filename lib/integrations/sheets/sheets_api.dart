import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sheet_record.dart';

class SheetsFailure implements Exception {
  const SheetsFailure(this.status);
  final int status;
  bool get requiresSignIn => [401, 403, 404].contains(status);
}

class SheetsApi {
  SheetsApi(this.client);
  final http.Client client;

  Future<Map<String, dynamic>> _request(
    String method,
    String host,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final request = http.Request(method, Uri.https(host, path, query));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) throw SheetsFailure(response.statusCode);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<String> account() async {
    final data = await _request(
      'GET',
      'openidconnect.googleapis.com',
      '/v1/userinfo',
    );
    final email = data['email'] as String?;
    if (email == null || data['email_verified'] != true) {
      throw const SheetsFailure(401);
    }
    return email;
  }

  Future<Map<String, String>> spreadsheets() async {
    final found = <String, String>{};
    String? page;
    do {
      final data = await _request(
        'GET',
        'www.googleapis.com',
        '/drive/v3/files',
        query: {
          'q':
              "trashed = false and mimeType = 'application/vnd.google-apps.spreadsheet' and appProperties has { key='logmydailytask' and value='v1' }",
          'fields': 'nextPageToken,files(id,name)',
          'pageSize': '100',
          'pageToken': ?page,
        },
      );
      for (final file in data['files'] as List? ?? []) {
        found[file['id'] as String] = file['name'] as String;
      }
      page = data['nextPageToken'] as String?;
    } while (page != null);
    return found;
  }

  static const _host = 'sheets.googleapis.com';
  static const _base = '/v4/spreadsheets';

  Future<String> create() async {
    final data = await _request(
      'POST',
      _host,
      _base,
      body: {
        'properties': {'title': 'LogMyDailyTask Log'},
        'sheets': [
          {
            'properties': {'title': 'Log'},
          },
        ],
      },
    );
    final id = data['spreadsheetId'] as String;
    await _write(id, 'Log!A1:S1', [logHeaders]);
    await _request(
      'PATCH',
      'www.googleapis.com',
      '/drive/v3/files/$id',
      body: {
        'appProperties': {'logmydailytask': 'v1'},
      },
    );
    return id;
  }

  Future<List<List<Object?>>> read(String id) async {
    final data = await _request(
      'GET',
      _host,
      '$_base/$id/values/Log!A1:S',
      query: {'valueRenderOption': 'UNFORMATTED_VALUE'},
    );
    final rows = (data['values'] as List? ?? []).cast<List<Object?>>();
    if (rows.isEmpty || rows.first.join(',') != logHeaders.join(',')) {
      throw const SheetsFailure(422);
    }
    return rows;
  }

  Future<void> verify(String id) async {
    await read(id);
    // Rewrite the identical header to check write access without leaving a test row.
    await _write(id, 'Log!A1:S1', [logHeaders]);
  }

  Future<void> _write(String id, String range, List<List<Object>> rows) async {
    await _request(
      'PUT',
      _host,
      '$_base/$id/values/$range',
      query: {'valueInputOption': 'RAW'},
      body: {'values': rows},
    );
  }

  Future<List<SheetRecord>> reconcile(
    String id,
    List<SheetRecord> outgoing,
  ) async {
    final rows = await read(id);
    final byId = <String, int>{
      for (var i = 1; i < rows.length; i++)
        if (rows[i].isNotEmpty) rows[i].first.toString(): i + 1,
    };
    final updates = <Map<String, Object>>[];
    final inserts = <List<Object>>[];
    for (final record in outgoing) {
      final index = byId[record.id];
      final values = encodeSheetRecord(record);
      if (index == null) {
        inserts.add(values);
      } else {
        if (rows[index - 1].length > 15 &&
            rows[index - 1][15] != record.deviceId) {
          throw const SheetsFailure(409);
        }
        updates.add({
          'range': 'Log!A$index:S$index',
          'values': [values],
        });
      }
    }
    if (updates.isNotEmpty) {
      await _request(
        'POST',
        _host,
        '$_base/$id/values:batchUpdate',
        body: {'valueInputOption': 'RAW', 'data': updates},
      );
    }
    if (inserts.isNotEmpty) {
      await _request(
        'POST',
        _host,
        '$_base/$id/values/Log!A:S:append',
        query: {'valueInputOption': 'RAW', 'insertDataOption': 'INSERT_ROWS'},
        body: {'values': inserts},
      );
    }
    return rows.skip(1).map(decodeSheetRecord).nonNulls.toList();
  }
}
