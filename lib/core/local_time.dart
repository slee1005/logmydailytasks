import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

final currentDateProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final timeZoneProvider = Provider<Future<String> Function()>((ref) {
  return () async => (await FlutterTimezone.getLocalTimezone()).identifier;
});

DateTime dayAtOffset(DateTime day, int offset) =>
    DateTime(day.year, day.month, day.day + offset);
