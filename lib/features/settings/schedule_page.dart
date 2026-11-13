import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/database.dart';
import '../../domain/scheduler/check_in_schedule.dart';
import '../../integrations/notifications/os_check_in_notifications.dart';
import '../../l10n/generated/app_localizations.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.scheduleTitle)),
      body: ref
          .watch(workScheduleProvider)
          .when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Center(child: Text(strings.loadError)),
            data: (schedule) => _ScheduleForm(initial: schedule),
          ),
    );
  }
}

class _ScheduleForm extends ConsumerStatefulWidget {
  const _ScheduleForm({required this.initial});

  final CheckInSchedule initial;

  @override
  ConsumerState<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<_ScheduleForm> {
  late final _workDays = {...widget.initial.workDays};
  late int _start = widget.initial.startMinute;
  late int _end = widget.initial.endMinute;
  late int _interval = widget.initial.intervalMinutes;
  late bool _alignToWorkStart = widget.initial.alignToWorkStart;
  late bool _enabled = widget.initial.enabled;
  bool _saving = false;
  String? _error;

  TimeOfDay _time(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time(start ? _start : _end),
    );
    if (!mounted || picked == null) return;
    final minute = picked.hour * 60 + picked.minute;
    setState(() {
      if (start) {
        _start = minute;
      } else {
        _end = minute;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final strings = AppLocalizations.of(context)!;
    final schedule = CheckInSchedule(
      workDays: Set.unmodifiable(_workDays),
      startMinute: _start,
      endMinute: _end,
      intervalMinutes: _interval,
      alignToWorkStart: _alignToWorkStart,
      enabled: _enabled,
    );
    if (!schedule.isValid) {
      setState(
        () => _error = _workDays.isEmpty
            ? strings.chooseWorkDay
            : strings.invalidWorkHours,
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final database = ref.read(databaseProvider);
      final os = ref.read(osCheckInNotificationsProvider);
      if (schedule.enabled && os != null) {
        try {
          await os.requestPermission();
        } catch (_) {
          // Save the schedule so foreground reminders remain available.
        }
      }
      if (!mounted) return;
      await database.saveSchedule(schedule);
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _error = strings.scheduleSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final weekdayLabel = DateFormat.E(
      Localizations.localeOf(context).toString(),
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.enableReminders),
          subtitle: Text(
            ref.watch(osCheckInNotificationsProvider) == null
                ? strings.reminderAvailability
                : ref.watch(osReminderStatusProvider)
                ? strings.osReminderAvailability
                : strings.osReminderPermission,
          ),
          value: _enabled,
          onChanged: _saving
              ? null
              : (value) => setState(() => _enabled = value),
        ),
        const SizedBox(height: 16),
        Text(strings.workDays, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(weekdayLabel.format(DateTime(2026, 1, 4 + day))),
                selected: _workDays.contains(day),
                onSelected: _saving
                    ? null
                    : (selected) => setState(() {
                        if (selected) {
                          _workDays.add(day);
                        } else {
                          _workDays.remove(day);
                        }
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.workStart),
          trailing: TextButton(
            onPressed: _saving ? null : () => _pickTime(start: true),
            child: Text(_time(_start).format(context)),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.workEnd),
          trailing: TextButton(
            onPressed: _saving ? null : () => _pickTime(start: false),
            child: Text(_time(_end).format(context)),
          ),
        ),
        const SizedBox(height: 12),
        DropdownMenu<int>(
          label: Text(strings.checkInInterval),
          enabled: !_saving,
          initialSelection: _interval,
          dropdownMenuEntries: [
            for (var minutes = 5; minutes <= 120; minutes += 5)
              DropdownMenuEntry(
                value: minutes,
                label: strings.intervalMinutes(minutes),
              ),
          ],
          onSelected: (value) {
            if (value != null) setState(() => _interval = value);
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.alignToWorkStart),
          value: _alignToWorkStart,
          onChanged: _saving
              ? null
              : (value) => setState(() => _alignToWorkStart = value),
        ),
        if (_error case final message?)
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(strings.saveSchedule),
          ),
        ),
      ],
    );
  }
}
