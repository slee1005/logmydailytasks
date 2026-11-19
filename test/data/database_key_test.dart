import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/data/db/database_key_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const name = 'logmydailytask.sqlite.key';
  final oldKey = 'a' * 64;
  final modernKey = 'b' * 64;
  late Map<String, String> modern;
  late Map<String, String> legacy;
  late List<(String, bool)> calls;
  bool? deniedRead;
  var denyWrite = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    modern = {};
    legacy = {};
    calls = [];
    deniedRead = null;
    denyWrite = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = call.arguments as Map;
          expect(arguments['key'], name);
          final options = arguments['options'] as Map;
          final isModern = options['usesDataProtectionKeychain'] == 'true';
          calls.add((call.method, isModern));
          final items = isModern ? modern : legacy;
          if (call.method == 'read') {
            if (deniedRead == isModern) {
              throw PlatformException(code: 'keychain_access_denied');
            }
            return items[name];
          }
          if (call.method == 'write') {
            if (denyWrite) throw PlatformException(code: 'write_failed');
            items[name] = arguments['value'] as String;
            return null;
          }
          fail('Keys must not be deleted during database initialization');
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('migrates the existing key once and keeps the legacy item', () async {
    legacy[name] = oldKey;
    expect(await loadDatabaseKey(databaseExists: () async => true), oldKey);
    expect(modern[name], oldKey);
    expect(legacy[name], oldKey);
    expect(calls, [('read', true), ('read', false), ('write', true)]);

    calls.clear();
    expect(await loadDatabaseKey(databaseExists: () async => true), oldKey);
    expect(calls, [('read', true)]);
  });

  test('uses the modern key without accessing a denied legacy item', () async {
    modern[name] = modernKey;
    legacy[name] = oldKey;
    deniedRead = false;
    expect(await loadDatabaseKey(databaseExists: () async => true), modernKey);
    expect(calls, [('read', true)]);
    expect(legacy[name], oldKey);
  });

  test(
    'does not generate a replacement key for an existing database',
    () async {
      await expectLater(
        loadDatabaseKey(databaseExists: () async => true),
        throwsStateError,
      );
      expect(modern, isEmpty);
      expect(legacy, isEmpty);
      expect(calls.where((call) => call.$1 == 'write'), isEmpty);
    },
  );

  for (final isModern in [true, false]) {
    test(
      'does not regenerate a key when keychain $isModern is denied',
      () async {
        deniedRead = isModern;
        await expectLater(
          loadDatabaseKey(databaseExists: () async => false),
          throwsA(isA<PlatformException>()),
        );
        expect(modern, isEmpty);
        expect(legacy, isEmpty);
        expect(calls.where((call) => call.$1 == 'write'), isEmpty);
      },
    );

    test('rejects an invalid key in keychain $isModern', () async {
      (isModern ? modern : legacy)[name] = 'invalid';
      await expectLater(
        loadDatabaseKey(databaseExists: () async => true),
        throwsStateError,
      );
      expect(calls.where((call) => call.$1 == 'write'), isEmpty);
    });
  }

  test('a failed migration preserves the original key for retry', () async {
    legacy[name] = oldKey;
    denyWrite = true;
    await expectLater(
      loadDatabaseKey(databaseExists: () async => true),
      throwsA(isA<PlatformException>()),
    );
    expect(legacy[name], oldKey);
    expect(modern, isEmpty);
    denyWrite = false;
    expect(await loadDatabaseKey(databaseExists: () async => true), oldKey);
    expect(modern[name], oldKey);
    expect(legacy[name], oldKey);
  });

  test('creates a stable key only for a new installation', () async {
    final key = await loadDatabaseKey(databaseExists: () async => false);
    expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(modern[name], key);
    expect(legacy, isEmpty);
    expect(await loadDatabaseKey(databaseExists: () async => true), key);
    expect(calls.where((call) => call.$1 == 'write'), hasLength(1));
  });

  test('standalone Mac builds keep using the existing file keychain', () async {
    legacy[name] = oldKey;
    deniedRead = true;
    expect(
      await loadDatabaseKey(
        databaseExists: () async => true,
        useMacFileKeychain: true,
      ),
      oldKey,
    );
    expect(calls, [('read', false)]);
    expect(modern, isEmpty);
  });

  test('a new standalone Mac installation saves a stable file key', () async {
    final key = await loadDatabaseKey(
      databaseExists: () async => false,
      useMacFileKeychain: true,
    );
    expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(legacy[name], key);
    expect(modern, isEmpty);
    expect(
      await loadDatabaseKey(
        databaseExists: () async => true,
        useMacFileKeychain: true,
      ),
      key,
    );
    expect(calls, [('read', false), ('write', false), ('read', false)]);
  });

  test('standalone Mac builds never replace a missing existing key', () async {
    await expectLater(
      loadDatabaseKey(
        databaseExists: () async => true,
        useMacFileKeychain: true,
      ),
      throwsStateError,
    );
    expect(calls, [('read', false)]);
    expect(legacy, isEmpty);
    expect(modern, isEmpty);
  });

  test('standalone Mac builds propagate denied file keychain access', () async {
    legacy[name] = oldKey;
    deniedRead = false;
    await expectLater(
      loadDatabaseKey(
        databaseExists: () async => false,
        useMacFileKeychain: true,
      ),
      throwsA(isA<PlatformException>()),
    );
    expect(calls, [('read', false)]);
    expect(legacy[name], oldKey);
    expect(modern, isEmpty);
  });
}
