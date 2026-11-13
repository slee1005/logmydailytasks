import 'dart:async';

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
import '../features/sheets/sheet_page.dart';
import '../integrations/sheets/sheet_sync.dart';
import '../features/settings/schedule_page.dart';
import '../features/checkin_popup/check_in_page.dart';
import '../features/weekly/weekly_page.dart';
import '../integrations/notifications/os_check_in_notifications.dart';
import '../l10n/generated/app_localizations.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WeeklyPage()),
      GoRoute(path: '/settings/sheets', builder: (_, _) => const SheetPage()),
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
  late final _os = ref.read(osCheckInNotificationsProvider);
  Future<void> _syncQueue = Future.value();
  Timer? _refill;
  bool _osReady = false;
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
        if (_active) _queueOsSync();
      },
    );
    ref.listenManual(workScheduleProvider, (_, _) {
      _refreshReminder();
      _queueOsSync();
    }, fireImmediately: true);
    if (_os != null) {
      _refill = Timer.periodic(const Duration(minutes: 15), (_) {
        if (_active) _queueOsSync();
      });
    }
  }

  void _refreshReminder() {
    _timer.cancel();
    final schedule = ref.read(workScheduleProvider).value;
    if (_active && !_osReady && schedule != null) _timer.schedule(schedule);
  }

  void _queueOsSync() {
    final os = _os;
    if (os == null) return;
    _syncQueue = _syncQueue.then((_) async {
      if (!mounted) return;
      try {
        await os.initialize(_openCheckInAfterNotification);
        if (!mounted) return;
        final messenger = _messenger.currentState;
        final schedule = ref.read(workScheduleProvider).value;
        if (messenger == null || schedule == null) return;
        final strings = AppLocalizations.of(messenger.context)!;
        final zone = await ref.read(timeZoneProvider)();
        if (!mounted) return;
        _osReady = await os.sync(
          schedule: schedule,
          now: ref.read(currentDateProvider)(),
          zone: zone,
          title: strings.checkInTitle,
          body: strings.reminderMessage,
          channelName: strings.enableReminders,
        );
      } catch (_) {
        _osReady = false;
      }
      if (mounted) {
        ref.read(osReminderStatusProvider.notifier).setReady(_osReady);
        _refreshReminder();
      }
    });
  }

  void _openCheckInAfterNotification() {
    // A cold-start response can arrive before the router is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(_routerProvider);
      if (router.state.uri.path != '/check-in') router.push('/check-in');
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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
    _refill?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sheetSyncProvider);
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
