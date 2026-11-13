import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
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
      final bytes = Uint8List.fromList(
        utf8.encode(worklogCsv(rows, strings.csvHeaders.split(','))),
      );
      if (!kIsWeb && Platform.isMacOS) {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw const FileSystemException('Downloads unavailable');
        }
        final saved = await saveCsvFile(directory, name, bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.csvSavedToDownloads(saved))),
          );
        }
        return;
      }
      final box = context.findRenderObject()! as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'text/csv')],
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

// Reserve the name before writing so repeated exports do not overwrite a report.
Future<String> saveCsvFile(
  Directory directory,
  String name,
  Uint8List bytes,
) async {
  final stem = name.substring(0, name.length - '.csv'.length);
  for (var index = 1; ; index++) {
    final candidate = index == 1 ? name : '$stem ($index).csv';
    final file = File.fromUri(
      directory.uri.resolve(Uri.encodeComponent(candidate)),
    );
    try {
      await file.create(exclusive: true);
    } on PathExistsException {
      continue;
    }
    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      try {
        await file.delete();
      } on FileSystemException {
        // Preserve the original write error.
      }
      rethrow;
    }
    return candidate;
  }
}
