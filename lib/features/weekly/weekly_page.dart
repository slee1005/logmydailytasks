import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_time.dart';
import '../../data/db/database.dart';
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
    final today = ref.watch(currentDateProvider)();
    final monday = dayAtOffset(today, 1 - today.weekday + _weekOffset * 7);

    final entries = ref.watch(weeklyEntriesProvider(monday));
    final byDay = <DateTime, List<({DateTime at, String title})>>{};
    for (final entry
        in entries.value ?? const <({DateTime at, String title})>[]) {
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
                      dates.formatMediumDate(monday),
                      dates.formatMediumDate(dayAtOffset(monday, dayCount - 1)),
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
                      final saved = await context.push<bool>('/check-in');
                      if (mounted && saved == true) _selectWeek(0);
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
                                dates.formatFullDate(dayAtOffset(monday, day)),
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
                                subtitle: Text(
                                  dates.formatTimeOfDay(
                                    TimeOfDay.fromDateTime(entry.at),
                                    alwaysUse24HourFormat:
                                        MediaQuery.alwaysUse24HourFormatOf(
                                          context,
                                        ),
                                  ),
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
