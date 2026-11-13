import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

final workTimeZones = _loadZones();

Map<String, tz.Location> _loadZones() {
  data.initializeTimeZones();
  return tz.timeZoneDatabase.locations;
}

String formatWorkDate(DateTime date) =>
    DateFormat('EEE, M/d/yyyy', 'en_US').format(date);

DateTime? resolveWorkTime(String zone, DateTime day, int hour, int minute) {
  final location = workTimeZones[zone];
  if (location == null) return null;
  final local = tz.TZDateTime(
    location,
    day.year,
    day.month,
    day.day,
    hour,
    minute,
  );
  // During a spring-forward gap, timezone normalizes to another wall time.
  if (local.day != day.day || local.hour != hour || local.minute != minute) {
    return null;
  }
  return local.toUtc();
}

DateTime inWorkZone(DateTime instant, String zone) {
  final location = workTimeZones[zone];
  return location == null
      ? instant.toLocal()
      : tz.TZDateTime.from(instant, location);
}
