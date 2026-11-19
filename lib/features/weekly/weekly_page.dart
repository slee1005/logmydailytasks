import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/widgets/date_swipe_container.dart';
import '../../app/widgets/worklog_layout.dart';
import '../../core/local_time.dart';
import '../../core/work_time.dart';
import '../../data/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../export/csv_export_button.dart';

final _privacyPolicyUrl = Uri.parse(
  'https://www.johnajc.com/privacy/logmydailytask',
);

final _monthEntries = StreamProvider.autoDispose
    .family<List<WeeklyActivity>, DateTime>(
      (ref, month) => ref
          .watch(databaseProvider)
          .watchActivities(month, DateTime(month.year, month.month + 1)),
    );

final _dayEntries = StreamProvider.autoDispose
    .family<List<WeeklyActivity>, DateTime>(
      (ref, date) => ref
          .watch(databaseProvider)
          .watchActivities(date, dayAtOffset(date, 1)),
    );

class WeeklyPage extends ConsumerStatefulWidget {
  const WeeklyPage({super.key});

  @override
  ConsumerState<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends ConsumerState<WeeklyPage> {
  DateTime? _visibleMonth;
  DateTime? _selectedDate;

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      _privacyPolicyUrl,
      mode: defaultTargetPlatform == TargetPlatform.macOS
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
    );
    if (!opened && mounted) {
      final strings = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.privacyPolicyOpenError)));
    }
  }

  void _selectDate(DateTime date, DateTime previousDate) {
    if (date == previousDate) return;
    setState(() {
      _selectedDate = date;
      _visibleMonth = DateTime(date.year, date.month);
    });
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
              : ListView.separated(
                  primary: false,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => EntryCard(entry: entries[index]),
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
    final today = dayAtOffset(ref.watch(currentDateProvider)(), 0);
    final selected = _selectedDate ?? today;
    final month = _visibleMonth ?? DateTime(today.year, today.month);
    return AppContainer(
      title: strings.dailyTitle,
      leadingIcon: Icons.view_agenda_outlined,
      actions: [
        ActionButton(
          label: strings.openCheckIn,
          icon: Icons.add,
          onPressed: () => context.push('/check-in'),
        ),
        WorklogIconButton(
          tooltip: strings.sheetTitle,
          icon: Icons.cloud_outlined,
          onPressed: () => context.push('/settings/sheets'),
        ),
        CsvExportButton(monday: dayAtOffset(today, 1 - today.weekday)),
        WorklogIconButton(
          tooltip: strings.scheduleTitle,
          icon: Icons.schedule,
          onPressed: () => context.push('/schedule'),
        ),
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS))
          PopupMenuButton<String>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            icon: const Icon(Icons.more_horiz),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              foregroundColor: Theme.of(context).colorScheme.tertiary,
              minimumSize: const Size.square(44),
            ),
            onSelected: (_) => _openPrivacyPolicy(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'privacy',
                child: Text(strings.privacyPolicy),
              ),
            ],
          ),
      ],
      body: AppContent(
        children: [
          DateSwipeContainer(
            date: selected,
            today: today,
            onDateChanged: (date) => _selectDate(date, _selectedDate ?? today),
            builder: (_, date) => _DateEntries(date: date),
          ),
          _CalendarCard(
            month: month,
            today: today,
            selected: selected,
            onMonthChanged: (month) => setState(() => _visibleMonth = month),
            onDayPressed: (date, entries) {
              _selectDate(date, selected);
              _showDay(date, entries);
            },
          ),
        ],
      ),
    );
  }
}

class _DateEntries extends ConsumerWidget {
  const _DateEntries({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return ref
        .watch(_dayEntries(date))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(strings.loadError)),
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.surfaceContainerHigh,
                      foregroundColor: colors.tertiary,
                      child: const Icon(Icons.event_note_outlined),
                    ),
                    const SizedBox(height: 10),
                    Text(strings.noEntries),
                  ],
                ),
              );
            }
            return ListView.separated(
              key: PageStorageKey(date),
              primary: false,
              padding: const EdgeInsets.symmetric(vertical: 2),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) =>
                  EntryCard(entry: entries[entries.length - 1 - index]),
            );
          },
        );
  }
}

class EntryCard extends StatefulWidget {
  const EntryCard({super.key, required this.entry});

  final WeeklyActivity entry;

  @override
  State<EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<EntryCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant EntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = entry.note?.trim() ?? '';
    final category = entry.category?.trim() ?? '';
    final hasDetails = note.isNotEmpty || category.isNotEmpty;
    String time(DateTime instant) =>
        TimeOfDay.fromDateTime(instant).format(context);
    final start = inWorkZone(entry.at, entry.zone);
    final end = entry.end;
    final zonedEnd = end == null ? null : inWorkZone(end, entry.zone);
    final timeLabel = zonedEnd == null
        ? time(entry.at)
        : '${time(start)} – ${time(zonedEnd)}';
    final syncLabel = switch (entry.sheetState) {
      'synced' => strings.sheetSynced,
      'pending' => strings.sheetPending,
      'failed' => strings.sheetFailure,
      _ => strings.sheetNotLinked,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(timeLabel, style: theme.textTheme.labelLarge),
                      if (entry.device != null)
                        Text(
                          entry.device!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: colors.surfaceContainerHigh,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            syncLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.tertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDetails)
                  Semantics(
                    expanded: _expanded,
                    child: IconButton(
                      tooltip: _expanded
                          ? strings.hideEntryDetails
                          : strings.showEntryDetails,
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(_expanded ? Icons.remove : Icons.add),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.title, style: theme.textTheme.titleMedium),
            if (_expanded && hasDetails) ...[
              const SizedBox(height: 12),
              if (category.isNotEmpty) ...[
                Text(strings.categoryLabel, style: theme.textTheme.labelSmall),
                Text(category),
              ],
              if (note.isNotEmpty) ...[
                if (category.isNotEmpty) const SizedBox(height: 8),
                Text(strings.noteLabel, style: theme.textTheme.labelSmall),
                Text(note),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({
    required this.month,
    required this.today,
    required this.selected,
    required this.onMonthChanged,
    required this.onDayPressed,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onMonthChanged;
  final void Function(DateTime, List<WeeklyActivity>) onDayPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final calendarEntries = ref.watch(_monthEntries(month));
    final previousMonth = DateTime(month.year, month.month - 1);
    final nextMonth = DateTime(month.year, month.month + 1);
    final firstWeekday = dates.firstDayOfWeekIndex;
    final leading = (month.weekday % 7 - firstWeekday) % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final byDay = <int, List<WeeklyActivity>>{};
    for (final entry
        in (calendarEntries.value ?? const <WeeklyActivity>[]).reversed) {
      (byDay[entry.at.day] ??= []).add(entry);
    }

    return SectionCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WorklogIconButton(
                tooltip: dates.previousMonthTooltip,
                icon: Icons.chevron_left,
                onPressed: previousMonth.isBefore(DateSwipeContainer.firstDate)
                    ? null
                    : () => onMonthChanged(previousMonth),
              ),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    dates.formatMonthYear(month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              WorklogIconButton(
                tooltip: dates.nextMonthTooltip,
                icon: Icons.chevron_right,
                onPressed: nextMonth.isAfter(DateSwipeContainer.lastDate)
                    ? null
                    : () => onMonthChanged(nextMonth),
              ),
            ],
          ),
          if (calendarEntries.hasError) Text(strings.loadError),
          if (calendarEntries.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      dates.narrowWeekdays[(firstWeekday + i) % 7],
                      style: Theme.of(context).textTheme.labelMedium,
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
                      row * 7 + column - leading + 1,
                      days,
                      byDay,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _calendarCell(
    BuildContext context,
    int day,
    int days,
    Map<int, List<WeeklyActivity>> byDay,
  ) {
    if (day < 1 || day > days) return const SizedBox(height: 46);
    final date = DateTime(month.year, month.month, day);
    final logs = byDay[day] ?? const <WeeklyActivity>[];
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context)!;
    final active = date == selected;
    return Semantics(
      selected: active,
      button: true,
      child: Tooltip(
        message: strings.calendarDay(formatWorkDate(date), logs.length),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onDayPressed(date, logs),
          child: SizedBox(
            height: 46,
            child: Center(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: active ? colors.primaryContainer : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 25,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$day',
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: active
                                      ? colors.onPrimaryContainer
                                      : date == today
                                      ? colors.primary
                                      : null,
                                  fontWeight: active || date == today
                                      ? FontWeight.bold
                                      : null,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 7,
                        child: logs.isEmpty
                            ? null
                            : Icon(
                                Icons.circle,
                                size: 5,
                                color: colors.primary,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
