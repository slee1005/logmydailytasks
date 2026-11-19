import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'sheet_scopes.dart';

const _serverId = String.fromEnvironment('GOOGLE_SHEETS_SERVER_CLIENT_ID');
const _iosId = String.fromEnvironment('GOOGLE_SHEETS_IOS_CLIENT_ID');
const _macSignIn = bool.fromEnvironment('WORKLOG_MAC_GOOGLE_SIGN_IN');
// Public OAuth client ID registered for the Apple bundle identifier.
const _macId =
    '1064814892452-dq40vbhtbt6039ordq2n6enqj6hfhs5p.apps.googleusercontent.com';

bool get sheetsMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        (defaultTargetPlatform == TargetPlatform.macOS && _macSignIn));
bool get sheetsMobileConfigured => switch (defaultTargetPlatform) {
  TargetPlatform.macOS => true,
  TargetPlatform.iOS => _iosId.isNotEmpty,
  _ => _serverId.isNotEmpty,
};

Future<void>? _initialization;
Future<void> _initialize() =>
    _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: defaultTargetPlatform == TargetPlatform.android
          ? _serverId
          : null,
      clientId: switch (defaultTargetPlatform) {
        TargetPlatform.macOS => _macId,
        TargetPlatform.iOS => _iosId,
        _ => null,
      },
    );

Future<http.Client> mobileSignIn() async {
  await _initialize();
  final account = await GoogleSignIn.instance.authenticate(
    scopeHint: sheetsConnectionScopes,
  );
  await account.authorizationClient.authorizeScopes(sheetsConnectionScopes);
  return _MobileClient(account, scopes: sheetsConnectionScopes);
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
  _MobileClient(this.account, {this.scopes = const [sheetsFileScope]}) {
    _recentAccount = account;
  }

  final GoogleSignInAccount account;
  final List<String> scopes;
  final _transport = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await account.authorizationClient.authorizationHeaders(
      scopes,
    );
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
