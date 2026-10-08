import 'format.dart';
import 'gym_store.dart';

class AnalyticsBucket {
  AnalyticsBucket(this.start, this.end);
  final DateTime start, end;
  double revenue = 0;
  int visits = 0;
}

/// Read-only analytics. All periods use the same local calendar boundaries as
/// the existing Flutter attendance and member screens; end dates are exclusive.
class DashboardAnalytics {
  DashboardAnalytics(GymStore store, {DateTime? now, this.days = 30}) {
    if (days <= 0) throw ArgumentError.value(days, 'days', 'Must be positive');
    final calendar = store.calendar;
    final today = calendar.day(now ?? DateTime.now());
    start = calendar.addDays(today, -days + 1);
    end = calendar.addDays(today, 1);
    final previousStart = calendar.addDays(start, -days);
    final count = days < 7
        ? days
        : days == 7
        ? 7
        : 6;
    buckets = List.generate(
      count,
      (i) => AnalyticsBucket(
        calendar.addDays(start, (i * days / count).floor()),
        calendar.addDays(start, ((i + 1) * days / count).floor()),
      ),
    );
    bool inPeriod(DateTime date) => !date.isBefore(start) && date.isBefore(end);
    AnalyticsBucket bucketFor(DateTime date) => buckets.firstWhere(
      (b) => !date.isBefore(b.start) && date.isBefore(b.end),
    );

    for (final payment in store.rows('payments')) {
      if (payment['status'] != 'completed') continue;
      final date = asDate(payment['payment_date']);
      if (date == null) continue;
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
      if (inPeriod(date)) {
        revenue += amount;
        receipts++;
        bucketFor(date).revenue += amount;
        final method = payment['payment_method'] as String? ?? 'other';
        paymentMethods[method] = (paymentMethods[method] ?? 0) + amount;
      } else if (!date.isBefore(previousStart) && date.isBefore(start)) {
        previousRevenue += amount;
      }
    }
    final visitors = <Object?>{};
    for (final visit in store.rows('attendance')) {
      final date = asDate(visit['check_in']);
      if (date == null) continue;
      if (inPeriod(date)) {
        visits++;
        visitors.add(visit['member_id']);
        bucketFor(date).visits++;
      } else if (!date.isBefore(previousStart) && date.isBefore(start)) {
        previousVisits++;
      }
      if (calendar.day(date) == today) visitsToday++;
    }
    uniqueVisitors = visitors.length;
    for (final member in store.rows('members')) {
      totalMembers++;
      final status = store.memberStatus(member);
      memberStatuses[status] = (memberStatuses[status] ?? 0) + 1;
      final joined = asDate(member['join_date']);
      if (joined != null && inPeriod(joined)) newMembers++;
      final due = store.memberDue(member['id'] as int);
      outstanding += due;
      if (due > 0) membersWithDues++;
      if (status == 'active') {
        final plan = store.label('membership_plans', member['plan_id']);
        activePlans[plan] = (activePlans[plan] ?? 0) + 1;
      }
    }
  }

  final int days;
  late final DateTime start, end;
  late final List<AnalyticsBucket> buckets;
  double revenue = 0, previousRevenue = 0, outstanding = 0;
  int visits = 0, previousVisits = 0, visitsToday = 0, uniqueVisitors = 0;
  int receipts = 0, totalMembers = 0, newMembers = 0, membersWithDues = 0;
  final memberStatuses = <String, int>{};
  final activePlans = <String, int>{};
  final paymentMethods = <String, double>{};
  int get activeMembers => memberStatuses['active'] ?? 0;
  double get averageReceipt => receipts == 0 ? 0 : revenue / receipts;
}
