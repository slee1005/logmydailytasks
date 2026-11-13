import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/local_time.dart';
import '../../data/db/database.dart';
import '../../domain/worklog_csv.dart';
import '../../l10n/generated/app_localizations.dart';

class CsvExportButton extends ConsumerWidget {
  const CsvExportButton({required this.monday, super.key});

  final DateTime monday;

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context)!;
    final today = ref.read(currentDateProvider)();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      currentDate: today,
      initialDateRange: DateTimeRange(
        start: monday,
        end: dayAtOffset(monday, 6),
      ),
    );
    if (range == null || !context.mounted) return;

    try {
      final rows = await ref
          .read(databaseProvider)
          .exportEntries(range.start, dayAtOffset(range.end, 1));
      if (!context.mounted) return;
      final date = DateFormat('yyyyMMdd');
      final name =
          'logmydailytask_${date.format(range.start)}-${date.format(range.end)}.csv';
      final box = context.findRenderObject()! as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(
                utf8.encode(worklogCsv(rows, strings.csvHeaders.split(','))),
              ),
              mimeType: 'text/csv',
            ),
          ],
          fileNameOverrides: [name],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.csvExportError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.file_download_outlined),
    tooltip: AppLocalizations.of(context)!.csvExport,
    onPressed: () => _export(context, ref),
  );
}
