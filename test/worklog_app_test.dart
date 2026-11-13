import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/app/worklog_app.dart';
import 'package:logmydailytask/core/local_time.dart';
import 'package:logmydailytask/data/db/database.dart';

void main() {
  Future<WorklogDatabase> launch(WidgetTester tester, Locale locale) async {
    tester.binding.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final database = WorklogDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await database.customSelect('SELECT 1').get();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          timeZoneProvider.overrideWithValue(() async => 'America/Los_Angeles'),
          currentDateProvider.overrideWithValue(() => DateTime(2026, 11, 13)),
        ],
        child: const WorklogApp(),
      ),
    );
    await tester.pumpAndSettle();
    return database;
  }

  testWidgets('Navigates weeks and returns to the selected week', (
    tester,
  ) async {
    final database = await launch(tester, const Locale('en'));
    expect(find.text('Weekly worklog'), findsOneWidget);
    expect(find.textContaining('November 9, 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('November 16, 2026'), findsOneWidget);

    final checkIn = find.text('Check in');
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(find.text('What did you work on?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Documentation');
    expect(find.text('Documentation'), findsOneWidget);

    await tester.tap(find.text('Back to worklog'));
    await tester.pumpAndSettle();
    expect(find.textContaining('November 16, 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });

  testWidgets('Saves a Korean check-in and shows it on the worklog', (
    tester,
  ) async {
    final database = await launch(tester, const Locale('ko'));
    expect(find.text('주간 업무 기록'), findsOneWidget);
    final checkIn = find.text('체크인');
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(find.text('어떤 일을 하셨나요?'), findsOneWidget);
    await tester.tap(find.text('체크인 저장'));
    await tester.pumpAndSettle();
    expect(find.text('업무를 입력해 주세요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '주간 보고서 작성');
    await tester.tap(find.text('체크인 저장'));
    await tester.pumpAndSettle();
    final activity = find.text('주간 보고서 작성');
    await tester.scrollUntilVisible(activity, 150);
    expect(activity, findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
