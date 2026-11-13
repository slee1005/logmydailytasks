import 'package:http/http.dart' as http;

const sheetsConfigured = false;
Future<http.Client> signInToSheets(void Function(Uri) unused) async =>
    throw UnsupportedError('Google sign-in is unavailable');
Future<http.Client> restoreSheetsSession(String account) async =>
    throw StateError('Google sign-in is unavailable');
Future<void> rememberSheetsSession(String account, http.Client client) async {}

Future<void> forgetSheetsSession(String account) async {}
