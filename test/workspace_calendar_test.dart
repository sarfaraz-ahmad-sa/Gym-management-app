import 'package:flutter_test/flutter_test.dart';
import 'package:fitguide/core/workspace_calendar.dart';

void main() {
  test('Pakistan dates are independent of the device timezone', () {
    final calendar = WorkspaceCalendar('Asia/Karachi');
    final date = calendar.fromTimestamp(
      DateTime.parse('2026-10-07T19:00:00Z').millisecondsSinceEpoch,
    )!;
    expect(date.day, 8);
    expect(date.hour, 0);
    expect(
      calendar.addDays(date, 30).toUtc(),
      DateTime.parse('2026-11-06T19:00:00Z'),
    );
  });
  test('calendar-day renewal respects daylight saving time', () {
    final calendar = WorkspaceCalendar('America/New_York');
    final spring = DateTime.parse('2026-03-07T05:00:00Z');
    expect(
      calendar.addDays(spring, 2).toUtc(),
      DateTime.parse('2026-03-09T04:00:00Z'),
    );
    final autumn = DateTime.parse('2026-10-31T04:00:00Z');
    expect(
      calendar.addDays(autumn, 2).toUtc(),
      DateTime.parse('2026-11-02T05:00:00Z'),
    );
  });
}
