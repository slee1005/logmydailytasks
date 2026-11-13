import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/database.dart';
import '../../integrations/sheets/google_session.dart';
import '../../integrations/sheets/mobile_session.dart';
import '../../integrations/sheets/sheet_sync.dart';
import '../../integrations/sheets/sheets_api.dart';
import '../../l10n/generated/app_localizations.dart';

class SheetPage extends ConsumerStatefulWidget {
  const SheetPage({super.key});

  @override
  ConsumerState<SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends ConsumerState<SheetPage> {
  bool _busy = false;
  bool _failed = false;
  Uri? _loginUrl;

  Future<void> _connect() async {
    final strings = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final sync = ref.read(sheetSyncProvider);
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final client = await (sheetsMobile
          ? mobileSignIn()
          : signInToSheets((uri) {
              if (mounted) setState(() => _loginUrl = uri);
            }));
      try {
        final api = SheetsApi(client);
        final account = mobileEmail(client) ?? await api.account();
        final choices = await api.spreadsheets();
        if (!mounted) return;
        final selected = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(strings.sheetConfirmAccount(account)),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ''),
                child: Text(strings.sheetCreate),
              ),
              for (final choice in choices.entries)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, choice.key),
                  child: Text(choice.value),
                ),
            ],
          ),
        );
        if (selected == null) return;
        final id = selected.isEmpty ? await api.create() : selected;
        await api.verify(id);
        if (!sheetsMobile) await rememberSheetsSession(account, client);
        await sync.settle();
        await db.linkSheet(account, id);
        await sync.run();
      } finally {
        client.close();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _loginUrl = null;
        });
      }
    }
  }

  Future<void> _disconnect(String account) async {
    final db = ref.read(databaseProvider);
    final sync = ref.read(sheetSyncProvider);
    setState(() => _busy = true);
    try {
      await sync.settle();
      await db.unlinkSheet();
      if (sheetsMobile) {
        await mobileSignOut();
      } else {
        await forgetSheetsSession(account);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(String? current) async {
    final strings = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final sync = ref.read(sheetSyncProvider);
    var name = current ?? '';
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.sheetDevice),
        content: TextFormField(
          initialValue: name,
          autofocus: true,
          maxLength: 80,
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, name.trim()),
            child: Text(strings.sheetSaveDevice),
          ),
        ],
      ),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    try {
      await db.renameSheetDevice(chosen);
      await sync.run();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final setting = ref.watch(sheetSettingsProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(strings.sheetTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            title: Text(strings.sheetDevice),
            subtitle: Text(setting?.deviceLabel ?? strings.deviceZone),
            onTap: _busy ? null : () => _rename(setting?.deviceLabel),
          ),
          Text(strings.sheetPrivacy),
          if (setting?.account case final account?) ...[
            const SizedBox(height: 12),
            Text(account),
            TextButton(
              onPressed: _busy ? null : () => _disconnect(account),
              child: Text(strings.sheetDisconnect),
            ),
            SelectableText(
              'https://docs.google.com/spreadsheets/d/${setting!.spreadsheet}',
            ),
          ],
          if (!sheetsAvailable) Text(strings.sheetUnavailable),
          if (setting?.error == 'auth') Text(strings.sheetReauthenticate),
          if (setting?.error == 'retry') Text(strings.sheetRetry),
          if (setting?.error == 'sheet' || _failed) Text(strings.sheetFailure),
          if (_loginUrl case final url?) SelectableText(url.toString()),
          if (_busy) const LinearProgressIndicator(),
          if (sheetsAvailable)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _busy ? null : _connect,
                child: Text(strings.sheetConnect),
              ),
            ),
        ],
      ),
    );
  }
}
