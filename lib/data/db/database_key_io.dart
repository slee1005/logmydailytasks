import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

const _keyName = 'logmydailytask.sqlite.key';
const _storage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: true),
  aOptions: AndroidOptions(resetOnError: false),
);
const _legacyStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: false),
);

String _validated(String key) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
    throw StateError('Invalid database key');
  }
  return key;
}

Future<bool> _databaseExists() async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/logmydailytask.sqlite').exists();
}

Future<String> loadDatabaseKey({
  Future<bool> Function() databaseExists = _databaseExists,
  bool useMacFileKeychain = const bool.fromEnvironment(
    'WORKLOG_MAC_FILE_KEYCHAIN',
  ),
}) async {
  // Standalone DMGs have no provisioning profile for Data Protection Keychain.
  final fileKeychain =
      defaultTargetPlatform == TargetPlatform.macOS && useMacFileKeychain;
  final storage = fileKeychain ? _legacyStorage : _storage;
  final existing = await storage.read(key: _keyName);
  if (existing != null) return _validated(existing);

  if (defaultTargetPlatform == TargetPlatform.macOS && !fileKeychain) {
    final legacy = await _legacyStorage.read(key: _keyName);
    if (legacy != null) {
      final key = _validated(legacy);
      // Keep the original item so older builds can still open the same database.
      await storage.write(key: _keyName, value: key);
      return key;
    }
  }

  // An inaccessible key must never replace the key for an existing database.
  if (await databaseExists()) {
    throw StateError('The existing database encryption key is unavailable');
  }

  final random = Random.secure();
  final key = List.generate(
    32,
    (_) => random.nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  await storage.write(key: _keyName, value: key);
  return key;
}
