import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../app/widgets/worklog_layout.dart';
import '../../core/local_time.dart';
import '../../core/work_time.dart';
import '../../data/db/database.dart';
import '../../domain/activity_suggestions.dart';
import '../../integrations/sheets/sheet_sync.dart';
import 'dart:async';
import '../../l10n/generated/app_localizations.dart';

final _categories = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(databaseProvider).watchCategories(),
);

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _activity = TextEditingController();
  final _note = TextEditingController();
  String? _category;

  Future<void> _editCategory({String? current}) async {
    final database = ref.read(databaseProvider);
    final strings = AppLocalizations.of(context)!;
    final editing = current != null;
    var name = current ?? '';
    var saving = false;
    String? error;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (saving || name.isEmpty) return;
            setDialogState(() => saving = true);
            try {
              final category = editing
                  ? await database.renameCategory(current, name)
                  : await database.addCategory(name);
              if (!context.mounted) return;
              if (category != null) {
                Navigator.pop(context, category);
                return;
              }
              error = strings.categoryAlreadyExists;
            } catch (_) {
              if (!context.mounted) return;
              error = strings.categoryUpdateError;
            }
            setDialogState(() => saving = false);
          }

          return AlertDialog(
            title: Text(editing ? strings.editCategory : strings.addCategory),
            content: TextFormField(
              initialValue: current,
              autofocus: true,
              readOnly: saving,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: strings.categoryLabel,
                errorText: error,
              ),
              onChanged: (value) => setDialogState(() {
                name = value.trim();
                error = null;
              }),
              onFieldSubmitted: (_) => save(),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: saving || name.isEmpty ? null : save,
                child: Text(
                  editing ? strings.saveCategory : strings.addCategory,
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || selected == null) return;
    if (!editing || _category == current) {
      setState(() => _category = selected);
    }
  }

  Future<void> _deleteCategory(String category) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteCategory),
        content: Text(strings.deleteCategoryMessage(category)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deleteCategory),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await ref.read(databaseProvider).deleteCategory(category);
      if (mounted && _category == category) setState(() => _category = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.categoryUpdateError)));
      }
    }
  }

  Future<void> _manageCategories() => showDialog<void>(
    context: context,
    builder: (context) {
      final strings = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(strings.manageCategories),
        scrollable: true,
        content: SizedBox(
          width: 360,
          child: Consumer(
            builder: (context, ref, _) => ref
                .watch(_categories)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(strings.categoryUpdateError),
                  data: (categories) => categories.isEmpty
                      ? Text(strings.noCategoriesToManage)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final category in categories)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: strings.editCategory,
                                      onPressed: () =>
                                          _editCategory(current: category),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: strings.deleteCategory,
                                      onPressed: () =>
                                          _deleteCategory(category),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    },
  );

  List<ActivitySuggestion> _activities = [];
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

  Future<void> _loadActivities() async {
    try {
      final rows = await ref
          .read(databaseProvider)
          .activitySuggestions(through: ref.read(currentDateProvider)());
      if (mounted) setState(() => _activities = rows);
    } catch (_) {
      // Typing and saving remain available if history cannot be loaded.
    }
  }

  List<ActivitySuggestion> get _matches {
    if (_dismissed) return const [];
    if (_activity.text.trim().isEmpty) return _activities.take(6).toList();
    return rankActivities(_activities, _activity.text);
  }

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
    final matches = _matches;
    if (matches.isEmpty || !_activity.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _dismissed = true);
      return KeyEventResult.handled;
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
      if (_highlighted < 0 && _activity.text.trim().isEmpty) {
        return KeyEventResult.ignored;
      }
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
    _note.dispose();
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
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        category: _category,
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
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final categories = {...?ref.watch(_categories).value, ?_category}.toList();
    String label(DateTime? date) => date == null
        ? strings.chooseWorkTime
        : '${formatWorkDate(date)} ${TimeOfDay.fromDateTime(date).format(context)}';
    return AppContainer(
      title: strings.checkInTitle,
      body: AppContent(
        children: [
          SectionCard(
            title: strings.checkInPrompt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      border: fieldBorder,
                      filled: true,
                      labelText: strings.activityLabel,
                      errorText: _error,
                    ),
                  ),
                ),
                if (!_saving && matches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final (index, match) in matches.indexed)
                          ActionChip(
                            backgroundColor: index == _highlighted
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            tooltip: match.title,
                            label: Text(
                              match.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _choose(match),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  readOnly: _saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    border: fieldBorder,
                    filled: true,
                    labelText: strings.noteLabel,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _category ?? '',
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _category = value == '' ? null : value,
                              ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(strings.noCategory),
                          ),
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    WorklogIconButton(
                      onPressed: _saving ? null : () => _editCategory(),
                      tooltip: strings.addCategory,
                      icon: Icons.add,
                    ),
                    WorklogIconButton(
                      onPressed: _saving ? null : _manageCategories,
                      tooltip: strings.manageCategories,
                      icon: Icons.edit_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
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
                  onTap: _saving ? null : () => _pickWorkTime(start: true),
                ),
                ListTile(
                  title: Text(strings.workEnd),
                  subtitle: Text(label(_end)),
                  onTap: _saving ? null : () => _pickWorkTime(start: false),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionButton(
                  label: strings.saveCheckIn,
                  icon: Icons.check,
                  onPressed: _saving ? null : _save,
                ),
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
