import 'package:flutter_test/flutter_test.dart';
import 'package:fitguide/core/dashboard_analytics.dart';
import 'package:fitguide/core/format.dart';
import 'package:fitguide/core/gym_store.dart';
import 'package:fitguide/services/db_service.dart';
import 'package:fitguide/core/workspace_calendar.dart';

class AnalyticsStore extends GymStore {
  AnalyticsStore(this.data) : super(DatabaseService(name: 'unused'));
  final Map<String, List<RecordData>> data;
  @override
  List<RecordData> rows(String table) => data[table] ?? [];
  @override
  double memberDue(int id) => id == 1 ? 350 : 0;
  @override
  String memberStatus(RecordData row) => row['status'] as String;
}

void main() {
  int stamp(int day, [int hour = 0]) =>
      WorkspaceCalendar()
          .atDate(DateTime(2026, 10, day))
          .millisecondsSinceEpoch +
      hour * 3600000;
  test('analytics respects calendar boundaries, completion and equal previous period', () {
    final store = AnalyticsStore({
      'members': [
        {'id': 1, 'status': 'active', 'join_date': stamp(8)},
        {'id': 2, 'status': 'inactive', 'join_date': stamp(-20)},
      ],
      'payments': [
        {
          'status': 'completed',
          'payment_date': stamp(2),
          'amount': 100,
          'payment_method': 'cash',
        },
        {
          'status': 'completed',
          'payment_date': stamp(8, 23),
          'amount': 200,
          'payment_method': 'card',
        },
        {'status': 'completed', 'payment_date': stamp(1, 23), 'amount': 75},
        {'status': 'completed', 'payment_date': stamp(9), 'amount': 999},
        {'status': 'pending', 'payment_date': stamp(8), 'amount': 999},
        {'status': 'failed', 'payment_date': stamp(8), 'amount': 999},
      ],
      'attendance': [
        {'member_id': 1, 'check_in': stamp(2)},
        {'member_id': 1, 'check_in': stamp(8, 20)},
        {'member_id': 2, 'check_in': stamp(1, 23)},
        {'member_id': 2, 'check_in': stamp(9)},
      ],
    });
    final stats = DashboardAnalytics(
      store,
      now: DateTime(2026, 10, 8),
      days: 7,
    );
    expect(stats.revenue, 300);
    expect(stats.previousRevenue, 75);
    expect(stats.receipts, 2);
    expect(stats.averageReceipt, 150);
    expect(stats.paymentMethods, {'cash': 100.0, 'card': 200.0});
    expect(stats.visits, 2);
    expect(stats.previousVisits, 1);
    expect(stats.visitsToday, 1);
    expect(stats.uniqueVisitors, 1);
    expect(stats.newMembers, 1);
    expect(stats.activeMembers, 1);
    expect(stats.outstanding, 350);
    expect(stats.membersWithDues, 1);
    expect(
      stats.buckets.fold<double>(0, (sum, b) => sum + b.revenue),
      stats.revenue,
    );
    expect(
      stats.buckets.fold<int>(0, (sum, b) => sum + b.visits),
      stats.visits,
    );
    store.dispose();
  });

  for (final days in [7, 30, 90]) {
    test(
      '$days-day buckets cover each calendar day exactly once across year boundaries',
      () {
        final store = AnalyticsStore({});
        final stats = DashboardAnalytics(
          store,
          now: DateTime(2026, 1, 2),
          days: days,
        );
        var date = stats.start;
        var covered = 0;
        while (date.isBefore(stats.end)) {
          expect(
            stats.buckets
                .where((b) => !date.isBefore(b.start) && date.isBefore(b.end))
                .length,
            1,
          );
          covered++;
          date = store.calendar.addDays(date, 1);
        }
        expect(covered, days);
        expect(stats.averageReceipt, 0);
        expect(stats.outstanding, 0);
        expect(stats.visits, 0);
        store.dispose();
      },
    );
  }
}
