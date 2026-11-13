import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _clientId = String.fromEnvironment('GOOGLE_SHEETS_CLIENT_ID');
const _clientSecret = String.fromEnvironment('GOOGLE_SHEETS_CLIENT_SECRET');
const sheetsConfigured = _clientId != '' && _clientSecret != '';
const _scope = 'https://www.googleapis.com/auth/drive.file';
final _oauth = ClientId(_clientId, _clientSecret);
const _storage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: false),
);

String _key(String account) => 'worklog.sheets.v1.$account';

Future<http.Client> signInToSheets(void Function(Uri) browserFallback) async {
  final transport = http.Client();
  try {
    final credentials = await obtainAccessCredentialsViaUserConsent(
      _oauth,
      [_scope, 'openid', 'email'],
      transport,
      (url) async {
        final uri = Uri.parse(url);
        try {
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            return;
          }
        } catch (_) {
          // The settings screen provides a copyable link.
        }
        browserFallback(uri);
      },
      customPostAuthPage: 'Google sign-in complete. Return to LogMyDailyTask.',
    );
    return _authenticated(credentials);
  } finally {
    transport.close();
  }
}

Future<http.Client> restoreSheetsSession(String account) async {
  final json = await _storage.read(key: _key(account));
  if (json == null) throw StateError('Sign-in required');
  return _authenticated(
    AccessCredentials.fromJson(jsonDecode(json) as Map<String, dynamic>),
  );
}

AutoRefreshingAuthClient _authenticated(AccessCredentials credentials) =>
    autoRefreshingClient(_oauth, credentials, http.Client());

Future<void> rememberSheetsSession(String account, http.Client client) async {
  final auth = client as AutoRefreshingAuthClient;
  await _storage.write(
    key: _key(account),
    value: jsonEncode(auth.credentials.toJson()),
  );
}

Future<void> forgetSheetsSession(String account) =>
    _storage.delete(key: _key(account));
