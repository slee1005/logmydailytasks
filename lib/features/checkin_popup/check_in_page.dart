import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_time.dart';
import '../../data/db/database.dart';
import '../../l10n/generated/app_localizations.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _activity = TextEditingController();
  bool _saving = false;
  String? _error;

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
    try {
      final at = ref.read(currentDateProvider)();
      final database = ref.read(databaseProvider);
      final tzName = await ref.read(timeZoneProvider)();
      await database.saveCheckIn(title: title, at: at, tzName: tzName);
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
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
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
                  TextField(
                    controller: _activity,
                    readOnly: _saving,
                    maxLength: 200,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: strings.activityLabel,
                      errorText: _error,
                    ),
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
