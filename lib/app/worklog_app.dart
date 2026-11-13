import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/checkin_popup/check_in_page.dart';
import '../features/weekly/weekly_page.dart';
import '../l10n/generated/app_localizations.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WeeklyPage()),
      GoRoute(path: '/check-in', builder: (_, _) => const CheckInPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class WorklogApp extends ConsumerWidget {
  const WorklogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const seed = Color(0xff24625d);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      routerConfig: ref.watch(_routerProvider),
    );
  }
}
