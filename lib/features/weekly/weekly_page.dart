import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_time.dart';
import '../../core/work_time.dart';
import '../../data/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../export/csv_export_button.dart';

final _monthEntries = StreamProvider.autoDispose
    .family<List<WeeklyActivity>, DateTime>(
      (ref, month) => ref
          .watch(databaseProvider)
          .watchActivities(month, DateTime(month.year, month.month + 1)),
    );

class WeeklyPage extends ConsumerStatefulWidget {
  const WeeklyPage({super.key});

  @override
  ConsumerState<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends ConsumerState<WeeklyPage> {
  DateTime? _visibleMonth;
  final _todayScroll = ScrollController();

  @override
  void dispose() {
    _todayScroll.dispose();
    super.dispose();
  }

  Widget _entry(BuildContext context, WeeklyActivity entry) {
    final strings = AppLocalizations.of(context)!;
    String time(DateTime instant) =>
        TimeOfDay.fromDateTime(instant).format(context);
    final start = inWorkZone(entry.at, entry.zone);
    final end = entry.end;
    return ListTile(
      title: Text(entry.title),
      subtitle: Text(
        [
          if (end == null)
            time(entry.at)
          else
            '${formatWorkDate(start)} ${time(start)} – ${formatWorkDate(inWorkZone(end, entry.zone))} ${time(inWorkZone(end, entry.zone))} (${entry.zone})',
          ?entry.device,
          ?entry.category,
          ?entry.note,
        ].join('\n'),
      ),
      trailing: Text(switch (entry.sheetState) {
        'synced' => strings.sheetSynced,
        'pending' => strings.sheetPending,
        'failed' => strings.sheetFailure,
        _ => strings.sheetNotLinked,
      }),
    );
  }

  void _showDay(DateTime date, List<WeeklyActivity> entries) {
    final strings = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(formatWorkDate(date)),
        content: SizedBox(
          width: 460,
          height: entries.isEmpty
              ? null
              : MediaQuery.sizeOf(context).height * .45,
          child: entries.isEmpty
              ? Text(strings.noEntries)
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final entry in entries) _entry(context, entry),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final today = dayAtOffset(ref.watch(currentDateProvider)(), 0);
    final todayMonth = DateTime(today.year, today.month);
    final month = _visibleMonth ?? todayMonth;
    final todayEntries = ref.watch(_monthEntries(todayMonth));
    final calendarEntries = ref.watch(_monthEntries(month));
    final firstWeekday = dates.firstDayOfWeekIndex;
    final leading = (month.weekday % 7 - firstWeekday) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final byDay = <int, List<WeeklyActivity>>{};
    for (final entry
        in (calendarEntries.value ?? const <WeeklyActivity>[]).reversed) {
      (byDay[entry.at.day] ??= []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dailyTitle),
        actions: [
          IconButton(
            tooltip: strings.sheetTitle,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => context.push('/settings/sheets'),
          ),
          CsvExportButton(monday: dayAtOffset(today, 1 - today.weekday)),
          IconButton(
            tooltip: strings.scheduleTitle,
            icon: const Icon(Icons.schedule),
            onPressed: () => context.push('/schedule'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/check-in'),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.openCheckIn),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatWorkDate(today),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SizedBox(
                      height: 230,
                      child: todayEntries.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Center(child: Text(strings.loadError)),
                        data: (entries) {
                          final logs = entries.reversed
                              .where((e) => dayAtOffset(e.at, 0) == today)
                              .toList();
                          if (logs.isEmpty) {
                            return Center(child: Text(strings.noEntries));
                          }
                          return Scrollbar(
                            controller: _todayScroll,
                            child: ListView.builder(
                              primary: false,
                              controller: _todayScroll,
                              itemCount: logs.length,
                              itemBuilder: (context, index) =>
                                  _entry(context, logs[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: dates.previousMonthTooltip,
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(
                          () => _visibleMonth = DateTime(
                            month.year,
                            month.month - 1,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          dates.formatMonthYear(month),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: dates.nextMonthTooltip,
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(
                          () => _visibleMonth = DateTime(
                            month.year,
                            month.month + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (calendarEntries.hasError) Text(strings.loadError),
                  if (calendarEntries.isLoading)
                    const LinearProgressIndicator(),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              dates.narrowWeekdays[(firstWeekday + i) % 7],
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var row = 0; row * 7 < leading + days; row++)
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          Expanded(
                            child: _calendarCell(
                              context,
                              month,
                              row * 7 + column - leading + 1,
                              days,
                              today,
                              byDay,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCell(
    BuildContext context,
    DateTime month,
    int day,
    int days,
    DateTime today,
    Map<int, List<WeeklyActivity>> byDay,
  ) {
    if (day < 1 || day > days) return const SizedBox(height: 48);
    final date = DateTime(month.year, month.month, day);
    final logs = byDay[day] ?? const <WeeklyActivity>[];
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context)!;
    return Tooltip(
      message: strings.calendarDay(formatWorkDate(date), logs.length),
      child: InkWell(
        onTap: () => _showDay(date, logs),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: date == today
                    ? TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      )
                    : null,
              ),
              SizedBox(
                height: 8,
                child: logs.isEmpty
                    ? null
                    : Icon(Icons.circle, size: 6, color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
