import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const _scope = 'https://www.googleapis.com/auth/drive.file';
const _serverId = String.fromEnvironment('GOOGLE_SHEETS_SERVER_CLIENT_ID');
const _iosId = String.fromEnvironment('GOOGLE_SHEETS_IOS_CLIENT_ID');

bool get sheetsMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
bool get sheetsMobileConfigured =>
    _serverId.isNotEmpty &&
    (defaultTargetPlatform != TargetPlatform.iOS || _iosId.isNotEmpty);

Future<void>? _initialization;
Future<void> _initialize() =>
    _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: _serverId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS ? _iosId : null,
    );

Future<http.Client> mobileSignIn() async {
  await _initialize();
  final account = await GoogleSignIn.instance.authenticate(scopeHint: [_scope]);
  await account.authorizationClient.authorizeScopes([_scope]);
  return _MobileClient(account);
}

GoogleSignInAccount? _recentAccount;

Future<http.Client> mobileRestore(String email) async {
  await _initialize();
  final account =
      _recentAccount ??
      await GoogleSignIn.instance.attemptLightweightAuthentication();
  if (account == null || account.email.toLowerCase() != email.toLowerCase()) {
    throw StateError('Sign-in required');
  }
  return _MobileClient(account);
}

class _MobileClient extends http.BaseClient {
  _MobileClient(this.account) {
    _recentAccount = account;
  }

  final GoogleSignInAccount account;
  final _transport = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await account.authorizationClient.authorizationHeaders([
      _scope,
    ]);
    if (headers == null) throw StateError('Google consent required');
    request.headers.addAll(headers);
    return _transport.send(request);
  }

  @override
  void close() => _transport.close();
}

String? mobileEmail(http.Client client) =>
    client is _MobileClient ? client.account.email : null;

Future<void> mobileSignOut() async {
  _recentAccount = null;
  await GoogleSignIn.instance.signOut();
}
