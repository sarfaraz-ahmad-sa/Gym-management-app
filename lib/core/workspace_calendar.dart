import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

const defaultWorkspaceTimeZone = 'Asia/Karachi';

class WorkspaceCalendar {
  WorkspaceCalendar([this.timeZone = defaultWorkspaceTimeZone]) {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
    location = tz.getLocation(timeZone);
  }
  static bool _initialized = false;
  final String timeZone;
  late final tz.Location location;

  DateTime instant(DateTime date) => tz.TZDateTime.from(date, location);
  DateTime? fromTimestamp(Object? value) => value is num
      ? tz.TZDateTime.fromMillisecondsSinceEpoch(location, value.toInt())
      : null;
  DateTime atDate(DateTime date) =>
      tz.TZDateTime(location, date.year, date.month, date.day);
  DateTime day(DateTime date) => atDate(instant(date));
  DateTime get today => day(DateTime.now());
  DateTime addDays(DateTime date, int days) {
    final local = instant(date);
    return tz.TZDateTime(location, local.year, local.month, local.day + days);
  }
}
