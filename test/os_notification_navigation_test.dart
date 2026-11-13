import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/app/worklog_app.dart';
import 'package:logmydailytask/data/db/database.dart';
import 'package:logmydailytask/integrations/notifications/os_check_in_notifications.dart';
import 'package:material_ui/material_ui.dart';

class _ColdStartNotification extends OsCheckInNotifications {
  @override
  Future<void> initialize(VoidCallback onTap) async => onTap();
}

void main() {
  testWidgets('notification cold start opens the check-in route', (
    tester,
  ) async {
    final database = WorklogDatabase(NativeDatabase.memory());
    await tester.runAsync(() => database.watchSchedule().first);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          osCheckInNotificationsProvider.overrideWithValue(
            _ColdStartNotification(),
          ),
        ],
        child: const WorklogApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('What did you work on?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
