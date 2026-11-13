import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/app/worklog_app.dart';
import 'package:logmydailytask/core/local_time.dart';
import 'package:logmydailytask/data/db/database.dart';
import 'package:material_ui/material_ui.dart';
import 'package:logmydailytask/integrations/notifications/os_check_in_notifications.dart';

void main() {
  testWidgets('saves schedule settings and opens a scheduled check-in', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final database = WorklogDatabase(NativeDatabase.memory());
    await tester.runAsync(() => database.watchSchedule().first);
    var now = DateTime(2026, 11, 13, 9, 29, 59);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          osCheckInNotificationsProvider.overrideWithValue(null),
          currentDateProvider.overrideWithValue(() => now),
        ],
        child: const WorklogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Work schedule'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownMenu<int>), findsOneWidget);
    await tester.tap(find.text('Align intervals to the start of work'));
    final save = find.text('Save schedule');
    await tester.scrollUntilVisible(
      save,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Daily Worklog'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => database.watchSchedule().first,
      ))?.alignToWorkStart,
      isTrue,
    );

    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 500));
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('Time to check in. What did you work on?'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(SnackBarAction, 'Check in'));
    await tester.pumpAndSettle();
    expect(find.text('What did you work on?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
