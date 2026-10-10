import 'models.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

DateTime propNow(int offsetMinutes) =>
    DateTime.now().add(Duration(minutes: offsetMinutes));

String formatClock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDay(DateTime time) =>
    '${_weekdays[time.weekday - 1]}, ${_months[time.month - 1]} ${time.day}';

/// Fixed offsets. No daylight-saving shift, so a zone stays where it was set.
class ClockZone {
  const ClockZone(this.id, this.label, this.hours);

  final String id;
  final String label;
  final int hours;
}

const kClockZones = <ClockZone>[
  ClockZone('utc', 'UTC (UTC+0)', 0),
  ClockZone('london', 'London (UTC+0)', 0),
  ClockZone('paris', 'Paris (UTC+1)', 1),
  ClockZone('athens', 'Athens (UTC+2)', 2),
  ClockZone('dubai', 'Dubai (UTC+4)', 4),
  ClockZone('karachi', 'Karachi (UTC+5)', 5),
  ClockZone('bangkok', 'Bangkok (UTC+7)', 7),
  ClockZone('seoul', 'Seoul (UTC+9)', 9),
  ClockZone('tokyo', 'Tokyo (UTC+9)', 9),
  ClockZone('sydney', 'Sydney (UTC+10)', 10),
  ClockZone('auckland', 'Auckland (UTC+12)', 12),
  ClockZone('newyork', 'New York (UTC-5)', -5),
  ClockZone('chicago', 'Chicago (UTC-6)', -6),
  ClockZone('denver', 'Denver (UTC-7)', -7),
  ClockZone('losangeles', 'Los Angeles (UTC-8)', -8),
  ClockZone('honolulu', 'Honolulu (UTC-10)', -10),
];

int clockZoneHours(String id) {
  for (final zone in kClockZones) {
    if (zone.id == id) return zone.hours;
  }
  return 0;
}

DateTime _zoneWall(String id, [DateTime? from]) {
  final utc = (from ?? DateTime.now()).toUtc();
  final shifted = utc.add(Duration(hours: clockZoneHours(id)));
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
  );
}

/// The time this device shows. A stopped clock stays on the stored hour and
/// minute and does not advance, even when the source is local or a zone.
DateTime osNow(OsSettings os) {
  final real = DateTime.now();
  if (!os.clockRunning) {
    return DateTime(real.year, real.month, real.day, os.clockHour, os.clockMinute);
  }
  if (os.clockSource == 'local') return real;
  if (os.clockSource == 'zone') return _zoneWall(os.clockZone, real);
  final anchor = os.clockAnchorMillis <= 0
      ? real.millisecondsSinceEpoch
      : os.clockAnchorMillis;
  final start = DateTime.fromMillisecondsSinceEpoch(anchor);
  final origin = DateTime(start.year, start.month, start.day, os.clockHour, os.clockMinute);
  final elapsed = real.difference(DateTime.fromMillisecondsSinceEpoch(anchor));
  if (elapsed.isNegative) return origin;
  return origin.add(elapsed);
}

OsSettings stopClock(OsSettings os) {
  final shown = osNow(os);
  return os.copyWith(
    clockRunning: false,
    clockHour: shown.hour,
    clockMinute: shown.minute,
    clockAnchorMillis: 0,
  );
}

OsSettings startClock(OsSettings os) {
  if (os.clockSource == 'set') {
    return os.copyWith(
      clockRunning: true,
      clockAnchorMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }
  return os.copyWith(clockRunning: true);
}

OsSettings chooseClockSource(OsSettings os, String source, {String? zone}) {
  final zoneId = zone ?? os.clockZone;
  if (os.clockRunning) {
    if (source == 'set') {
      final shown = osNow(os);
      return os.copyWith(
        clockSource: 'set',
        clockZone: zoneId,
        clockHour: shown.hour,
        clockMinute: shown.minute,
        clockAnchorMillis: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return os.copyWith(clockSource: source, clockZone: zoneId);
  }
  if (source == 'set') {
    return os.copyWith(clockSource: 'set', clockZone: zoneId);
  }
  final instant = source == 'zone' ? _zoneWall(zoneId) : DateTime.now();
  return os.copyWith(
    clockSource: source,
    clockZone: zoneId,
    clockHour: instant.hour,
    clockMinute: instant.minute,
  );
}

/// Puts the device on a set time. A running clock continues from that minute.
OsSettings pinClock(OsSettings os, int hour, int minute) {
  final shifted = DateTime(2000, 1, 1, 0, 0).add(Duration(hours: hour, minutes: minute));
  return os.copyWith(
    clockSource: 'set',
    clockHour: shifted.hour,
    clockMinute: shifted.minute,
    clockAnchorMillis: os.clockRunning ? DateTime.now().millisecondsSinceEpoch : 0,
  );
}

OsSettings shiftClock(OsSettings os, int deltaMinutes) {
  final shown = osNow(os).add(Duration(minutes: deltaMinutes));
  return pinClock(os, shown.hour, shown.minute);
}

OsSettings followLocalClock(OsSettings os) {
  final now = DateTime.now();
  return os.copyWith(
    clockSource: 'local',
    clockRunning: true,
    clockHour: now.hour,
    clockMinute: now.minute,
    clockAnchorMillis: 0,
  );
}

String formatStamp(int millis) {
  if (millis <= 0) return '';
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
