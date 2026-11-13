import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../core/local_time.dart';
import '../../core/work_time.dart';
import '../../data/db/database.dart';
import '../../domain/activity_suggestions.dart';
import '../../integrations/sheets/sheet_sync.dart';
import 'dart:async';
import '../../l10n/generated/app_localizations.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _activity = TextEditingController();
  List<ActivitySuggestion> _activities = [];
  bool _older = false;
  bool _dismissed = false;
  int _highlighted = -1;
  String? _zone;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities({bool older = false}) async {
    try {
      final rows = await ref
          .read(databaseProvider)
          .activitySuggestions(
            through: ref.read(currentDateProvider)(),
            recentOnly: !older,
          );
      if (mounted && (!_older || older)) {
        setState(() {
          _activities = rows;
          _older = older;
          _highlighted = -1;
        });
      }
    } catch (_) {
      // Typing and saving remain available if history cannot be loaded.
    }
  }

  List<ActivitySuggestion> get _matches =>
      _dismissed ? [] : rankActivities(_activities, _activity.text);

  void _choose(ActivitySuggestion suggestion) {
    setState(() {
      _activity.value = TextEditingValue(
        text: suggestion.title,
        selection: TextSelection.collapsed(offset: suggestion.title.length),
      );
      _dismissed = true;
      _error = null;
    });
  }

  KeyEventResult _handleSuggestionKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _saving) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _dismissed = true);
      return KeyEventResult.handled;
    }
    final matches = _matches;
    if (matches.isEmpty || !_activity.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlighted = _highlighted < 0
            ? (key == LogicalKeyboardKey.arrowDown ? 0 : matches.length - 1)
            : (_highlighted + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) %
                  matches.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _choose(matches[_highlighted < 0 ? 0 : _highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _pickZone() async {
    final strings = AppLocalizations.of(context)!;
    final zones = workTimeZones.keys.toList()..sort();
    final zone = await showDialog<String>(
      context: context,
      builder: (context) =>
          _WorkZoneDialog(zones: zones, title: strings.workZone),
    );
    if (mounted && zone != null) setState(() => _zone = zone);
  }

  Future<void> _pickWorkTime({required bool start}) async {
    final zone = _zone ?? await ref.read(timeZoneProvider)();
    if (!mounted) return;
    final strings = AppLocalizations.of(context)!;
    final existing =
        (start ? _start : _end) ??
        inWorkZone(ref.read(currentDateProvider)(), zone);
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime(existing.year, existing.month, existing.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (!mounted || day == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(existing),
    );
    if (!mounted || time == null) return;
    setState(() {
      _zone = zone;
      final wall = DateTime.utc(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = wall;
      } else {
        _end = wall;
      }
      _error = resolveWorkTime(zone, wall, wall.hour, wall.minute) == null
          ? strings.invalidWorkTime
          : null;
    });
  }

  @override
  void dispose() {
    _activity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _activity.text.trim();
    final strings = AppLocalizations.of(context)!;
    if (title.isEmpty) {
      setState(() => _error = strings.emptyActivity);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    DateTime? savedAt;
    try {
      final at = ref.read(currentDateProvider)();
      final database = ref.read(databaseProvider);
      final tzName = _zone ?? await ref.read(timeZoneProvider)();
      final start = _start;
      final end = _end;
      final startInstant = start == null
          ? at
          : resolveWorkTime(tzName, start, start.hour, start.minute);
      final endInstant = end == null
          ? null
          : resolveWorkTime(tzName, end, end.hour, end.minute);
      if (startInstant == null ||
          (end != null &&
              (start == null ||
                  endInstant == null ||
                  !endInstant.isAfter(startInstant)))) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error = strings.invalidWorkTime;
          });
        }
        return;
      }
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      await database.saveCheckIn(
        title: title,
        at: startInstant,
        end: endInstant,
        tzName: tzName,
        deviceName: kIsWeb
            ? 'Web'
            : switch (defaultTargetPlatform) {
                TargetPlatform.iOS => 'iOS',
                TargetPlatform.macOS => 'macOS',
                TargetPlatform.android => 'Android',
                TargetPlatform.windows => 'Windows',
                TargetPlatform.linux => 'Linux',
                TargetPlatform.fuchsia => 'Fuchsia',
              },
        devicePlatform: platform,
      );
      savedAt = startInstant;
      if (mounted) unawaited(ref.read(sheetSyncProvider).run());
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = strings.saveError;
        });
      }
      return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop(savedAt);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final matches = _matches;
    String label(DateTime? date) => date == null
        ? strings.chooseWorkTime
        : '${formatWorkDate(date)} ${TimeOfDay.fromDateTime(date).format(context)}';
    return Scaffold(
      appBar: AppBar(title: Text(strings.checkInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.checkInPrompt,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    onKeyEvent: _handleSuggestionKey,
                    child: TextField(
                      controller: _activity,
                      readOnly: _saving,
                      maxLength: 200,
                      onChanged: (_) {
                        setState(() {
                          _error = null;
                          _dismissed = false;
                          _highlighted = -1;
                        });
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: strings.activityLabel,
                        errorText: _error,
                      ),
                    ),
                  ),
                  if (!_saving && !_dismissed) ...[
                    for (final (index, match) in matches.indexed)
                      ListTile(
                        dense: true,
                        selected: index == _highlighted,
                        title: Text(match.title),
                        onTap: () => _choose(match),
                      ),
                    if (_activity.text.trim().isNotEmpty &&
                        matches.isEmpty &&
                        !_older)
                      TextButton(
                        onPressed: () => _loadActivities(older: true),
                        child: Text(strings.searchOlderActivities),
                      ),
                  ],
                  ExpansionTile(
                    title: Text(strings.workTimeRange),
                    children: [
                      ListTile(
                        title: Text(strings.workZone),
                        subtitle: Text(_zone ?? strings.deviceZone),
                        onTap: _saving ? null : _pickZone,
                      ),
                      ListTile(
                        title: Text(strings.workStart),
                        subtitle: Text(label(_start)),
                        onTap: _saving
                            ? null
                            : () => _pickWorkTime(start: true),
                      ),
                      ListTile(
                        title: Text(strings.workEnd),
                        subtitle: Text(label(_end)),
                        onTap: _saving
                            ? null
                            : () => _pickWorkTime(start: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(strings.saveCheckIn),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                    child: Text(strings.backToWorklog),
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

class _WorkZoneDialog extends StatefulWidget {
  const _WorkZoneDialog({required this.zones, required this.title});

  final List<String> zones;
  final String title;

  @override
  State<_WorkZoneDialog> createState() => _WorkZoneDialogState();
}

class _WorkZoneDialogState extends State<_WorkZoneDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final zones = widget.zones
        .where((zone) => zone.toLowerCase().contains(_query))
        .toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 300,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(labelText: widget.title),
              onChanged: (query) => setState(
                () => _query = query.trim().toLowerCase().replaceAll(' ', '_'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: zones.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(zones[index]),
                  onTap: () => Navigator.of(context).pop(zones[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
