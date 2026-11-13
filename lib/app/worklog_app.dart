import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/local_time.dart';
import '../data/db/database.dart';
import '../domain/scheduler/check_in_timer.dart';
import '../features/settings/schedule_page.dart';
import '../features/checkin_popup/check_in_page.dart';
import '../features/weekly/weekly_page.dart';
import '../l10n/generated/app_localizations.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WeeklyPage()),
      GoRoute(path: '/schedule', builder: (_, _) => const SchedulePage()),
      GoRoute(path: '/check-in', builder: (_, _) => const CheckInPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class WorklogApp extends ConsumerStatefulWidget {
  const WorklogApp({super.key});

  @override
  ConsumerState<WorklogApp> createState() => _WorklogAppState();
}

class _WorklogAppState extends ConsumerState<WorklogApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final _timer = CheckInTimer(
    now: () => ref.read(currentDateProvider)(),
    onReminder: _showReminder,
  );
  late final AppLifecycleListener _lifecycle;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null || state == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _active = state == AppLifecycleState.resumed;
        _refreshReminder();
      },
    );
    ref.listenManual(
      workScheduleProvider,
      (_, _) => _refreshReminder(),
      fireImmediately: true,
    );
  }

  void _refreshReminder() {
    _timer.cancel();
    final schedule = ref.read(workScheduleProvider).value;
    if (_active && schedule != null) _timer.schedule(schedule);
  }

  void _showReminder(DateTime scheduledAt) {
    final messenger = _messenger.currentState;
    final router = ref.read(_routerProvider);
    if (messenger == null || router.state.uri.path == '/check-in') return;
    final strings = AppLocalizations.of(messenger.context)!;
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.reminderMessage),
          duration: const Duration(seconds: 30),
          showCloseIcon: true,
          action: SnackBarAction(
            label: strings.openCheckIn,
            onPressed: () => router.push('/check-in'),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff24625d);
    return MaterialApp.router(
      scaffoldMessengerKey: _messenger,
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
