import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sheet_record.dart';

typedef _DriveFile = ({String id, String name, DateTime created});

class SheetsFailure implements Exception {
  const SheetsFailure(this.status, {this.api, this.reason});
  final int status;
  final String? api;
  final String? reason;
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
    if (response.statusCode >= 400) {
      throw SheetsFailure(
        response.statusCode,
        api: host == _host ? 'Google Sheets API' : 'Google Drive API',
        reason: _failureReason(response),
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  String? _failureReason(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body['error'];
      if (error is! Map) return null;
      final details = error['details'];
      final errors = error['errors'];
      final reasons = [
        if (details is List)
          for (final item in details.whereType<Map>()) item['reason'],
        if (errors is List)
          for (final item in errors.whereType<Map>()) item['reason'],
        error['status'],
      ];
      return reasons
          .whereType<String>()
          .where(RegExp(r'^[a-zA-Z_]{1,64}$').hasMatch)
          .firstOrNull;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
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
  static const _title = 'LogMyDailyTask';

  _DriveFile _driveFile(Map<String, dynamic> file) => (
    id: file['id'] as String,
    name: file['name'] as String,
    created:
        DateTime.tryParse(file['createdTime'] as String? ?? '') ??
        DateTime.utc(1970),
  );

  Future<List<_DriveFile>> _matchingFiles() async {
    final found = <_DriveFile>[];
    String? page;
    do {
      final data = await _request(
        'GET',
        'www.googleapis.com',
        '/drive/v3/files',
        query: {
          'q':
              "trashed = false and (name = '$_title' or name contains '${_title}_v')",
          'fields': 'nextPageToken,files(id,name,createdTime)',
          'pageSize': '100',
          'pageToken': ?page,
        },
      );
      found.addAll(
        (data['files'] as List? ?? []).map(
          (file) => _driveFile(file as Map<String, dynamic>),
        ),
      );
      page = data['nextPageToken'] as String?;
    } while (page != null);
    return found;
  }

  String _nextTitle(List<_DriveFile> files) {
    final pattern = RegExp(r'^LogMyDailyTask_v(\d{3,})$');
    var latest = 0;
    for (final file in files) {
      final match = pattern.firstMatch(file.name);
      final version = int.tryParse(match?.group(1) ?? '') ?? 0;
      if (version > latest) latest = version;
    }
    if (latest == 0 && !files.any((file) => file.name == _title)) return _title;
    return '${_title}_v${(latest + 1).toString().padLeft(3, '0')}';
  }

  Future<void> _resolveNameCollision(_DriveFile created) async {
    var title = created.name;
    for (var attempt = 0; attempt < 5; attempt++) {
      final files = await _matchingFiles();
      final occupied = files.any(
        (file) =>
            file.id != created.id &&
            file.name == title &&
            (file.created.isBefore(created.created) ||
                (file.created == created.created &&
                    file.id.compareTo(created.id) < 0)),
      );
      if (!occupied) return;
      title = _nextTitle(files);
      await _request(
        'PATCH',
        'www.googleapis.com',
        '/drive/v3/files/${created.id}',
        body: {'name': title},
      );
    }
    throw const SheetsFailure(409, reason: 'nameCollision');
  }

  Future<String> create() async {
    final title = _nextTitle(await _matchingFiles());
    final data = await _request(
      'POST',
      _host,
      _base,
      body: {
        'properties': {'title': title},
        'sheets': [
          {
            'properties': {'title': 'Log'},
          },
        ],
      },
    );
    final id = data['spreadsheetId'] as String;
    await _write(id, 'Log!A1:S1', [logHeaders]);
    await _prepareLog(id, [logHeaders]);
    final created = await _request(
      'PATCH',
      'www.googleapis.com',
      '/drive/v3/files/$id',
      query: {'fields': 'id,name,createdTime'},
      body: {
        'appProperties': {'logmydailytask': 'v1'},
      },
    );
    await _resolveNameCollision(_driveFile(created));
    return id;
  }

  Future<List<List<Object?>>> read(String id) async {
    final data = await _request(
      'GET',
      _host,
      '$_base/$id/values/Log!A1:S',
      query: {
        'valueRenderOption': 'UNFORMATTED_VALUE',
        'dateTimeRenderOption': 'SERIAL_NUMBER',
      },
    );
    final rows = (data['values'] as List? ?? []).cast<List<Object?>>();
    if (rows.isEmpty || rows.first.join(',') != logHeaders.join(',')) {
      throw const SheetsFailure(422);
    }
    return rows;
  }

  Future<void> verify(String id) async {
    await _prepareLog(id, await read(id));
  }

  Future<void> _prepareLog(String id, List<List<Object?>> rows) async {
    final metadata = await _request(
      'GET',
      _host,
      '$_base/$id',
      query: {
        'fields':
            'sheets(properties(sheetId,title),data(startColumn,columnMetadata(pixelSize)))',
        'ranges': 'Log!A1:S1',
        'includeGridData': 'true',
      },
    );
    final sheet = (metadata['sheets'] as List? ?? []).cast<Map>().firstWhere(
      (sheet) => sheet['properties']['title'] == 'Log',
      orElse: () => throw const SheetsFailure(422),
    );
    final sheetId = sheet['properties']['sheetId'] as int;
    final widths = <int, int>{};
    for (final grid in sheet['data'] as List? ?? []) {
      final start = grid['startColumn'] as int? ?? 0;
      final columns = grid['columnMetadata'] as List? ?? [];
      for (final (index, column) in columns.indexed) {
        widths[start + index] = column['pixelSize'] as int? ?? 100;
      }
    }
    final formats = [
      (start: 1, end: 2, type: 'DATE', pattern: 'yyyy-mm-dd'),
      (start: 2, end: 4, type: 'DATE_TIME', pattern: 'yyyy-mm-dd hh:mm:ss'),
      (start: 4, end: 5, type: 'NUMBER', pattern: '0.########'),
      (
        start: 13,
        end: 14,
        type: 'DATE_TIME',
        pattern: 'yyyy-mm-dd hh:mm:ss" UTC"',
      ),
      (
        start: 16,
        end: 18,
        type: 'DATE_TIME',
        pattern: 'yyyy-mm-dd hh:mm:ss" UTC"',
      ),
    ];
    final requests = <Map<String, Object>>[
      for (final (column, width) in [
        (1, 110),
        (2, 180),
        (3, 180),
        (13, 220),
        (16, 220),
        (17, 220),
      ])
        if ((widths[column] ?? 100) < width)
          {
            'updateDimensionProperties': {
              'range': {
                'sheetId': sheetId,
                'dimension': 'COLUMNS',
                'startIndex': column,
                'endIndex': column + 1,
              },
              'properties': {'pixelSize': width},
              'fields': 'pixelSize',
            },
          },
      for (final format in formats)
        {
          'repeatCell': {
            'range': {
              'sheetId': sheetId,
              'startRowIndex': 1,
              'startColumnIndex': format.start,
              'endColumnIndex': format.end,
            },
            'cell': {
              'userEnteredFormat': {
                'numberFormat': {
                  'type': format.type,
                  'pattern': format.pattern,
                },
              },
            },
            'fields': 'userEnteredFormat.numberFormat',
          },
        },
    ];
    for (var index = 1; index < rows.length; index++) {
      final values = normalizeSheetDates(rows[index]);
      for (final (start, end) in [(1, 5), (13, 14), (16, 18)]) {
        if (end > values.length) continue;
        final columns = List.generate(end - start, (offset) => start + offset);
        if (columns.every((column) => rows[index][column] == values[column])) {
          continue;
        }
        requests.add({
          'updateCells': {
            'start': {
              'sheetId': sheetId,
              'rowIndex': index,
              'columnIndex': start,
            },
            'rows': [
              {
                'values': [
                  for (final column in columns)
                    {
                      'userEnteredValue': values[column] is num
                          ? {'numberValue': values[column]}
                          : {'stringValue': values[column]},
                    },
                ],
              },
            ],
            'fields': 'userEnteredValue',
          },
        });
      }
    }
    const batchSize = 500;
    for (var offset = 0; offset < requests.length; offset += batchSize) {
      await _request(
        'POST',
        _host,
        '$_base/$id:batchUpdate',
        body: {'requests': requests.skip(offset).take(batchSize).toList()},
      );
    }
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
    await _prepareLog(id, rows);
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
