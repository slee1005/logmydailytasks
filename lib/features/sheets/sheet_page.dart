import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/widgets/worklog_layout.dart';
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
  String? _failureDetail;
  Uri? _loginUrl;

  Future<void> _openSheet(Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the URL available for copying when the browser cannot be opened.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.sheetOpenError)),
    );
  }

  Future<void> _connect() async {
    final strings = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final sync = ref.read(sheetSyncProvider);
    setState(() {
      _busy = true;
      _failed = false;
      _failureDetail = null;
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
    } on SheetsFailure catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _failureDetail = [
            ?error.api,
            'HTTP ${error.status}',
            ?error.reason,
          ].join(' · ');
        });
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
    return AppContainer(
      title: strings.sheetTitle,
      body: AppContent(
        children: [
          SettingsCard(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_outlined),
                title: Text(strings.sheetDevice),
                subtitle: Text(setting?.deviceLabel ?? strings.deviceZone),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy ? null : () => _rename(setting?.deviceLabel),
              ),
            ],
          ),
          SettingsCard(
            children: [
              Text(strings.sheetPrivacy),
              if (setting?.account case final account?) ...[
                const SizedBox(height: 12),
                Text(account),
                TextButton(
                  onPressed: _busy ? null : () => _disconnect(account),
                  child: Text(strings.sheetDisconnect),
                ),
                if (setting?.spreadsheet case final spreadsheet?)
                  SelectionArea(
                    child: Semantics(
                      link: true,
                      child: TextButton.icon(
                        onPressed: () => _openSheet(
                          Uri.https(
                            'docs.google.com',
                            '/spreadsheets/d/$spreadsheet',
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          'https://docs.google.com/spreadsheets/d/$spreadsheet',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              if (!sheetsAvailable) Text(strings.sheetUnavailable),
              if (setting?.error == 'auth') Text(strings.sheetReauthenticate),
              if (setting?.error == 'retry') Text(strings.sheetRetry),
              if (setting?.error == 'sheet' || _failed)
                Text(strings.sheetFailure),
              if (_failureDetail case final detail?)
                SelectionArea(child: Text(detail)),
              if (_loginUrl case final url?)
                SelectionArea(child: Text(url.toString())),
              if (_busy) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              if (sheetsAvailable)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionButton(
                    onPressed: _busy ? null : _connect,
                    icon: Icons.cloud_outlined,
                    label: strings.sheetConnect,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
