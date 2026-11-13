class CheckInSchedule {
  const CheckInSchedule({
    this.workDays = const {1, 2, 3, 4, 5},
    this.startMinute = 9 * 60,
    this.endMinute = 18 * 60,
    this.intervalMinutes = 30,
    this.alignToWorkStart = false,
    this.enabled = true,
  });

  final Set<int> workDays;
  final int startMinute;
  final int endMinute;
  final int intervalMinutes;
  final bool alignToWorkStart;
  final bool enabled;

  bool get isValid =>
      workDays.isNotEmpty &&
      workDays.every(
        (day) => day >= DateTime.monday && day <= DateTime.sunday,
      ) &&
      startMinute >= 0 &&
      endMinute < 24 * 60 &&
      endMinute - startMinute >= intervalMinutes &&
      intervalMinutes >= 5 &&
      intervalMinutes <= 120 &&
      intervalMinutes % 5 == 0 &&
      firstBoundary + intervalMinutes <= endMinute;

  int get firstBoundary => alignToWorkStart
      ? startMinute
      : ((startMinute + intervalMinutes - 1) ~/ intervalMinutes) *
            intervalMinutes;

  DateTime? nextReminderAfter(DateTime now) {
    if (!enabled || !isValid) return null;

    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (!workDays.contains(day.weekday)) continue;

      for (
        var minute = firstBoundary + intervalMinutes;
        minute <= endMinute;
        minute += intervalMinutes
      ) {
        final candidate = DateTime(
          day.year,
          day.month,
          day.day,
          minute ~/ 60,
          minute % 60,
        );
        // A nonexistent local time can normalize to a different wall time.
        if (candidate.day != day.day ||
            candidate.hour * 60 + candidate.minute != minute) {
          continue;
        }
        if (candidate.isAfter(now)) return candidate;
      }
    }
    return null;
  }
}
