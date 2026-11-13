import 'dart:async';

import 'check_in_schedule.dart';

class CheckInTimer {
  CheckInTimer({required this.now, required this.onReminder});

  final DateTime Function() now;
  final void Function(DateTime scheduledAt) onReminder;
  Timer? _timer;
  DateTime? _lastReminder;

  void schedule(CheckInSchedule settings) {
    cancel();
    final current = now();
    final last = _lastReminder;
    final next = settings.nextReminderAfter(
      last != null && last.isAfter(current) ? last : current,
    );
    if (next == null) return;

    final delay = next.difference(current);
    const refresh = Duration(minutes: 1);
    _timer = Timer(delay < refresh ? delay : refresh, () {
      final lateBy = now().difference(next);
      if (!lateBy.isNegative && lateBy < refresh) {
        _lastReminder = next;
        onReminder(next);
      }
      schedule(settings);
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
