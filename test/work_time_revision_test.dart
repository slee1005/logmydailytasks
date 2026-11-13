import 'package:flutter_test/flutter_test.dart';
import 'package:logmydailytask/core/work_time.dart';
import 'package:logmydailytask/domain/activity_suggestions.dart';
import 'package:logmydailytask/domain/worklog_csv.dart';

void main() {
  test('resolves wall times in the selected zone and rejects DST gaps', () {
    final day = DateTime(2026, 11, 13);
    expect(
      resolveWorkTime('Asia/Seoul', day, 9, 0),
      DateTime.utc(2026, 11, 13),
    );
    expect(
      resolveWorkTime('America/Los_Angeles', DateTime(2026, 3, 8), 2, 30),
      isNull,
    );
    expect(formatWorkDate(day), 'Fri, 11/13/2026');
  });

  test('ranks prefixes and Korean initials', () {
    final activities = [
      ActivitySuggestion('Documentation', 2, 1),
      ActivitySuggestion('Product docs', 1, 1),
      ActivitySuggestion('매뉴얼 작성', 3, 1),
    ];
    expect(rankActivities(activities, 'doc').map((item) => item.title), [
      'Documentation',
      'Product docs',
    ]);
    expect(rankActivities(activities, 'ㅁㄴ').single.title, '매뉴얼 작성');
  });

  test('CSV emits BOM, quoted text, local times and device metadata', () {
    final csv = worklogCsv(
      [
        (
          id: 'id',
          start: DateTime.utc(2026, 11, 13),
          end: DateTime.utc(2026, 11, 13, 1),
          zone: 'Asia/Seoul',
          title: '작업, "문서"',
          device: 'Phone',
          platform: 'ios',
          note: null,
          category: null,
          sheetState: 'none',
          syncedAt: null,
        ),
      ],
      ['entry_id'],
    );
    expect(csv, startsWith('\uFEFF"entry_id"\r\n'));
    expect(csv, contains('"09:00","10:00","60","","작업, ""문서"""'));
    expect(csv, contains('"Phone","ios","not_linked",""'));
  });
}
