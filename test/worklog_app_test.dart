import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/app/worklog_app.dart';
import 'package:logmydailytask/core/local_time.dart';
import 'package:logmydailytask/data/db/database.dart';

void main() {
  Future<WorklogDatabase> launch(
    WidgetTester tester,
    Locale locale, {
    Future<void> Function(WorklogDatabase)? seed,
  }) async {
    tester.binding.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final database = WorklogDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await database.customSelect('SELECT 1').get();
    });
    final seeded = seed?.call(database);
    await tester.pump();
    await seeded;
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

  testWidgets('Navigates months without changing the daily worklog', (
    tester,
  ) async {
    final database = await launch(tester, const Locale('en'));
    expect(find.text('Daily Worklog'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);

    final checkIn = find.text('Check in');
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(find.text('What did you work on?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Documentation');
    expect(find.text('Documentation'), findsOneWidget);

    await tester.tap(find.text('Back to worklog'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });

  testWidgets('Renames and deletes a selected category from check-in', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = await launch(
      tester,
      const Locale('en'),
      seed: (database) async {
        await database.addCategory('Docs');
        await database.addCategory('Meetings');
      },
    );
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButton<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docs').hitTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Manage categories'));
    await tester.pumpAndSettle();
    Finder actionFor(String category, String tooltip) => find.descendant(
      of: find.widgetWithText(ListTile, category),
      matching: find.byTooltip(tooltip),
    );
    await tester.tap(actionFor('Docs', 'Rename category'));
    await tester.pumpAndSettle();
    final editor = find.byType(TextFormField);
    await tester.enterText(editor, 'Meetings');
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();
    expect(
      find.text('A category with this name already exists.'),
      findsOneWidget,
    );
    await tester.enterText(editor, 'Writing');
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(dropdown).value, 'Writing');

    await tester.tap(actionFor('Writing', 'Delete category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(actionFor('Writing', 'Delete category'), findsOneWidget);
    await tester.tap(actionFor('Writing', 'Delete category'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete category'));
    await tester.pumpAndSettle();
    expect(actionFor('Writing', 'Delete category'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<String>>(dropdown).value, '');
    expect(
      tester
          .widget<DropdownButton<String>>(dropdown)
          .items
          ?.map((item) => item.value),
      ['', 'Meetings'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });

  testWidgets('Saves a Korean check-in and shows it on the worklog', (
    tester,
  ) async {
    final database = await launch(tester, const Locale('ko'));
    expect(find.text('일일 업무 기록'), findsOneWidget);
    final checkIn = find.text('체크인');
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(find.text('어떤 일을 하셨나요?'), findsOneWidget);
    await tester.ensureVisible(find.text('체크인 저장'));
    await tester.tap(find.text('체크인 저장'));
    await tester.pumpAndSettle();
    expect(find.text('업무를 입력해 주세요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '주간 보고서 작성');
    await tester.enterText(find.byType(TextField).at(1), '회의 후 초안 정리');
    await tester.ensureVisible(find.byTooltip('카테고리 추가'));
    await tester.tap(find.byTooltip('카테고리 추가'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      '보고서',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('카테고리 추가')).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('체크인 저장'));
    await tester.tap(find.text('체크인 저장'));
    await tester.pumpAndSettle();
    final activity = find.text('주간 보고서 작성');

    expect(activity, findsOneWidget);
    expect(find.textContaining('회의 후 초안 정리'), findsOneWidget);
    final markedDay = find.byTooltip('Fri, 11/13/2026, 기록 1건');
    await tester.ensureVisible(markedDay);
    await tester.tap(markedDay);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: activity),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.runAsync(database.close);
  });
}
