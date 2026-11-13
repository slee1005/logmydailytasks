import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_time.dart';
import '../../core/work_time.dart';
import '../../data/db/database.dart';
import '../export/csv_export_button.dart';
import '../../l10n/generated/app_localizations.dart';

class WeeklyPage extends ConsumerStatefulWidget {
  const WeeklyPage({super.key});

  @override
  ConsumerState<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends ConsumerState<WeeklyPage> {
  int _weekOffset = 0;

  void _selectWeek(int offset) => setState(() => _weekOffset = offset);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    String formatTime(DateTime instant) => dates.formatTimeOfDay(
      TimeOfDay.fromDateTime(instant),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final today = ref.watch(currentDateProvider)();
    final monday = dayAtOffset(today, 1 - today.weekday + _weekOffset * 7);

    final entries = ref.watch(weeklyEntriesProvider(monday));
    final byDay = <DateTime, List<WeeklyActivity>>{};
    for (final entry in entries.value ?? const <WeeklyActivity>[]) {
      (byDay[dayAtOffset(entry.at, 0)] ??= []).add(entry);
    }
    final dayCount = byDay.keys.any((day) => day.weekday >= DateTime.saturday)
        ? 7
        : 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            tooltip: strings.sheetTitle,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => context.push('/settings/sheets'),
          ),
          CsvExportButton(monday: monday),
          IconButton(
            tooltip: strings.scheduleTitle,
            onPressed: () => context.push('/schedule'),
            icon: const Icon(Icons.schedule),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.weeklyTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.weekRange(
                      formatWorkDate(monday),
                      formatWorkDate(dayAtOffset(monday, dayCount - 1)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: strings.previousWeek,
                        onPressed: () => _selectWeek(_weekOffset - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      TextButton(
                        onPressed: _weekOffset == 0
                            ? null
                            : () => _selectWeek(0),
                        child: Text(strings.thisWeek),
                      ),
                      IconButton(
                        tooltip: strings.nextWeek,
                        onPressed: () => _selectWeek(_weekOffset + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final saved = await context.push<DateTime>('/check-in');
                      if (!mounted || saved == null) return;
                      final local = saved.toLocal();
                      final savedMonday = DateTime.utc(
                        local.year,
                        local.month,
                        local.day - local.weekday + 1,
                      );
                      final currentMonday = DateTime.utc(
                        today.year,
                        today.month,
                        today.day - today.weekday + 1,
                      );
                      _selectWeek(
                        savedMonday.difference(currentMonday).inDays ~/ 7,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(strings.openCheckIn),
                  ),
                  const SizedBox(height: 12),
                  entries.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => Text(strings.loadError),
                    data: (_) => Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var day = 0; day < dayCount; day++) ...[
                            ListTile(
                              title: Text(
                                formatWorkDate(dayAtOffset(monday, day)),
                              ),
                              subtitle:
                                  byDay.containsKey(dayAtOffset(monday, day))
                                  ? null
                                  : Text(strings.noEntries),
                            ),
                            for (final entry
                                in byDay[dayAtOffset(monday, day)] ?? const [])
                              ListTile(
                                dense: true,
                                title: Text(entry.title),
                                trailing: Text(switch (entry.sheetState) {
                                  'synced' => strings.sheetSynced,
                                  'pending' => strings.sheetPending,
                                  'failed' => strings.sheetFailure,
                                  _ => strings.sheetNotLinked,
                                }),
                                subtitle: Text(
                                  entry.end == null
                                      ? '${formatTime(entry.at)} ${entry.device ?? ''}'
                                      : '${formatWorkDate(inWorkZone(entry.at, entry.zone))} '
                                            '${formatTime(inWorkZone(entry.at, entry.zone))} – '
                                            '${formatWorkDate(inWorkZone(entry.end!, entry.zone))} '
                                            '${formatTime(inWorkZone(entry.end!, entry.zone))} (${entry.zone}) ${entry.device ?? ''}',
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
