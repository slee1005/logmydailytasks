import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../data/db/database.dart';
import 'google_session.dart';
import 'mobile_session.dart';
import 'sheets_api.dart';

bool get sheetsAvailable => sheetsMobile
    ? sheetsMobileConfigured
    : sheetsConfigured &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);

final sheetSettingsProvider = StreamProvider<SheetSetting?>(
  (ref) => ref.watch(databaseProvider).watchSheetSettings(),
);

final sheetSyncProvider = Provider<SheetSync>((ref) {
  final sync = SheetSync(ref.watch(databaseProvider));
  if (sheetsAvailable) {
    unawaited(sync.run());
    final timer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(sync.run()),
    );
    ref.onDispose(timer.cancel);
  }
  return sync;
});

class SheetSync {
  SheetSync(this.database);

  final WorklogDatabase database;
  Future<void>? _running;
  bool _rerun = false;

  Future<void> settle() async => await _running;

  Future<void> run() {
    if (!sheetsAvailable) return Future.value();
    if (_running case final running?) {
      _rerun = true;
      return running;
    }
    return _running = _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    do {
      _rerun = false;
      await _sync();
    } while (_rerun);
  }

  Future<void> _sync() async {
    try {
      final setting = await database.watchSheetSettings().first;
      final account = setting?.account;
      final id = setting?.spreadsheet;
      if (setting == null ||
          account == null ||
          id == null ||
          setting.error == 'auth') {
        return;
      }
      final records = await database.pendingSheetRecords(setting);
      try {
        final client = await (sheetsMobile
            ? mobileRestore(account)
            : restoreSheetsSession(account));
        try {
          final incoming = await SheetsApi(client).reconcile(id, records);
          await database.importSheetRecords(incoming, setting.deviceId);
          await database.markSheetRecords(records);
          await database.setSheetError(null);
        } finally {
          client.close();
        }
      } catch (error) {
        final auth =
            error is StateError ||
            error is AccessDeniedException ||
            (error is ServerRequestFailedException &&
                [400, 401, 403].contains(error.statusCode)) ||
            (error is SheetsFailure && error.requiresSignIn);
        final transient =
            error is! SheetsFailure ||
            error.status == 429 ||
            error.status >= 500;
        if (!auth && !transient) {
          await database.markSheetRecords(records, error: 'sheet');
        }
        await database.setSheetError(
          auth
              ? 'auth'
              : transient
              ? 'retry'
              : 'sheet',
        );
      }
    } catch (_) {
      // A transient local database failure should not stop the next timer run.
    }
  }
}
