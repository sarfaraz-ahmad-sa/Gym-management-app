import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.navigate});
  final void Function(String) navigate;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _reportType = 'summary';
  DateTimeRange? _dateRange;
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final now = store.calendar.instant(DateTime.now());
    _dateRange ??= DateTimeRange(start: now.subtract(Duration(days: _days)), end: now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: 'Reports',
          subtitle: 'Analytics and insights for your gym',
        ),
        const SizedBox(height: 20),
        // Report type selector
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            ChoiceChip(avatar: const Icon(Icons.dashboard_outlined, size: 18), label: const Text('Summary'), selected: _reportType == 'summary', onSelected: (_) => setState(() => _reportType = 'summary')),
            ChoiceChip(avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18), label: const Text('Revenue'), selected: _reportType == 'revenue', onSelected: (_) => setState(() => _reportType = 'revenue')),
            ChoiceChip(avatar: const Icon(Icons.people_outline, size: 18), label: const Text('Members'), selected: _reportType == 'members', onSelected: (_) => setState(() => _reportType = 'members')),
            ChoiceChip(avatar: const Icon(Icons.event_available_outlined, size: 18), label: const Text('Attendance'), selected: _reportType == 'attendance', onSelected: (_) => setState(() => _reportType = 'attendance')),
            ChoiceChip(avatar: const Icon(Icons.schedule_outlined, size: 18), label: const Text('Expiry'), selected: _reportType == 'expiry', onSelected: (_) => setState(() => _reportType = 'expiry')),
          ],
        ),
        const SizedBox(height: 16),
        // Date range picker
        Row(
          children: [
            for (final d in [7, 30, 90, 365])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$d days'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                ),
              ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  initialDateRange: _dateRange,
                );
                if (picked != null) setState(() => _dateRange = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Report content
        Expanded(
          child: SingleChildScrollView(
            child: _buildReport(store),
          ),
        ),
      ],
    );
  }

  Widget _chip(String type, String label, IconData icon) => ChoiceChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: _reportType == type,
        onSelected: (_) => setState(() => _reportType = type),
      );

  Widget _buildReport(GymStore store) {
    switch (_reportType) {
      case 'revenue':
        return _revenueReport(store);
      case 'members':
        return _membersReport(store);
      case 'attendance':
        return _attendanceReport(store);
      case 'expiry':
        return _expiryReport(store);
      default:
        return _summaryReport(store);
    }
  }

  Widget _summaryReport(GymStore store) {
    final analytics = store.analytics(days: _days);
    return Column(
      children: [
        LayoutBuilder(
          builder: (ctx, c) {
            final count = c.maxWidth > 900 ? 4 : c.maxWidth > 450 ? 2 : 1;
            final width = (c.maxWidth - (count - 1) * 16) / count;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _summaryCard(width, 'Total Revenue', money(analytics.revenue, store.currency), Icons.account_balance_wallet, AppTheme.green),
                _summaryCard(width, 'New Members', '${analytics.newMembers}', Icons.person_add, AppTheme.blue),
                _summaryCard(width, 'Total Visits', '${analytics.visits}', Icons.event_available, const Color(0xFF9334E6)),
                _summaryCard(width, 'Outstanding', money(analytics.outstanding, store.currency), Icons.schedule, AppTheme.amber),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _section('Top Membership Plans', _topPlans(store, analytics)),
        const SizedBox(height: 20),
        _section('Payment Methods', _paymentMethods(store, analytics)),
      ],
    );
  }

  Widget _revenueReport(GymStore store) {
    final analytics = store.analytics(days: _days);
    final payments = store.rows('payments').where((p) {
      final date = store.calendar.fromTimestamp(p['payment_date'] as int);
      return date != null && date.isAfter(_dateRange!.start) && date.isBefore(_dateRange!.end) && p['status'] == 'completed';
    }).toList();

    final dailyRevenue = <String, double>{};
    for (final p in payments) {
      final date = store.calendar.fromTimestamp(p['payment_date'] as int)!;
      final key = DateFormat('d MMM').format(date);
      dailyRevenue[key] = (dailyRevenue[key] ?? 0) + (p['amount'] as num).toDouble();
    }

    final sortedDays = dailyRevenue.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox('Total Revenue', money(analytics.revenue, store.currency), Icons.account_balance_wallet, AppTheme.green)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Receipts', '${payments.length}', Icons.receipt, AppTheme.blue)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Average', money(payments.isEmpty ? 0 : analytics.revenue / payments.length, store.currency), Icons.trending_up, const Color(0xFF9334E6))),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Daily Revenue',
          subtitle: 'Last $_days days',
          child: sortedDays.isEmpty
              ? const EmptyState(title: 'No revenue data', message: 'No payments in this period')
              : Column(children: sortedDays.take(15).map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)), const Spacer(), Text(money(e.value, store.currency), style: const TextStyle(fontWeight: FontWeight.w600))]),
                )).toList()),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Recent Payments',
          subtitle: 'Last 10 completed payments',
          child: Column(
            children: (store.rows('payments').where((p) => p['status'] == 'completed').toList()
              ..sort((a, b) => (b['payment_date'] as int).compareTo(a['payment_date'] as int))
              ..take(10))
              .map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt, color: AppTheme.green),
                  title: Text(store.label('members', p['member_id'])),
                  subtitle: Text(store.dateLabel(p['payment_date'])),
                  trailing: Text(money(p['amount'], store.currency), style: const TextStyle(fontWeight: FontWeight.w600)),
                )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _membersReport(GymStore store) {
    final members = store.rows('members');
    final active = members.where((m) => store.memberStatus(m) == 'active').length;
    final expired = members.where((m) => store.memberStatus(m) == 'expired').length;
    final expiringSoon = members.where((m) => store.memberStatus(m) == 'expiring').length;

    final byMonth = <String, int>{};
    for (final m in members) {
      final join = store.calendar.fromTimestamp(m['join_date'] as int?);
      if (join != null && join.isAfter(_dateRange!.start) && join.isBefore(_dateRange!.end)) {
        final key = DateFormat('MMMM yyyy').format(join);
        byMonth[key] = (byMonth[key] ?? 0) + 1;
      }
    }
    final sortedMonths = byMonth.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox('Total', '${members.length}', Icons.people, AppTheme.blue)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Active', '$active', Icons.check_circle, AppTheme.green)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Expired', '$expired', Icons.cancel, AppTheme.red)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Expiring Soon', '$expiringSoon', Icons.warning, AppTheme.amber)),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'New Members by Month',
          subtitle: 'In selected period',
          child: sortedMonths.isEmpty
              ? const EmptyState(title: 'No new members', message: 'No members joined in this period')
              : Column(children: sortedMonths.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)), const Spacer(), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w600))]),
                )).toList()),
        ),
      ],
    );
  }

  Widget _attendanceReport(GymStore store) {
    final visits = store.rows('attendance');
    final today = store.calendar.today;

    final todayVisits = visits.where((v) {
      final date = store.calendar.fromTimestamp(v['check_in'] as int);
      return date != null && store.calendar.day(date) == today;
    }).toList();

    final uniqueToday = todayVisits.map((v) => v['member_id']).toSet().length;
    final checkedIn = todayVisits.where((v) => v['check_out'] == null).length;

    // This week
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekVisits = visits.where((v) {
      final date = store.calendar.fromTimestamp(v['check_in'] as int);
      return date != null && store.calendar.day(date).isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox("Today's Visits", '${todayVisits.length}', Icons.today, AppTheme.blue)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Checked In Now', '$checkedIn', Icons.login, AppTheme.green)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Unique Today', '$uniqueToday', Icons.person, const Color(0xFF9334E6))),
            const SizedBox(width: 16),
            Expanded(child: _statBox('This Week', '${weekVisits.length}', Icons.date_range, AppTheme.amber)),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Recent Check-ins',
          subtitle: 'Last 10 visits',
          child: Column(
            children: (visits.toList()
              ..sort((a, b) => (b['check_in'] as int).compareTo(a['check_in'] as int))
              ..take(10))
              .map((v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(v['check_out'] == null ? Icons.login : Icons.logout, color: v['check_out'] == null ? AppTheme.green : AppTheme.blue),
                  title: Text(store.label('members', v['member_id'])),
                  subtitle: Text(store.dateLabel(v['check_in'], 'd MMM • h:mm a')),
                  trailing: v['check_out'] == null ? const Text('Inside', style: TextStyle(color: AppTheme.green)) : Text(store.dateLabel(v['check_out'], 'h:mm a')),
                )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _expiryReport(GymStore store) {
    final members = store.rows('members');
    final today = store.calendar.today;

    final expired = members.where((m) {
      final expiry = store.calendar.fromTimestamp(m['expiry_date'] as int?);
      return expiry != null && expiry.isBefore(today);
    }).toList();

    final expiring7 = members.where((m) {
      final expiry = store.calendar.fromTimestamp(m['expiry_date'] as int?);
      return expiry != null && expiry.difference(today).inDays <= 7 && expiry.difference(today).inDays > 0;
    }).toList();

    final expiring30 = members.where((m) {
      final expiry = store.calendar.fromTimestamp(m['expiry_date'] as int?);
      return expiry != null && expiry.difference(today).inDays <= 30 && expiry.difference(today).inDays > 7;
    }).toList();

    final active = members.where((m) {
      final expiry = store.calendar.fromTimestamp(m['expiry_date'] as int?);
      return expiry == null || expiry.isAfter(today);
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statBox('Expired', '${expired.length}', Icons.cancel, AppTheme.red)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Expiring 7 days', '${expiring7.length}', Icons.warning, AppTheme.amber)),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Expiring 30 days', '${expiring30.length}', Icons.schedule, const Color(0xFF9334E6))),
            const SizedBox(width: 16),
            Expanded(child: _statBox('Active', '${active.length}', Icons.check_circle, AppTheme.green)),
          ],
        ),
        const SizedBox(height: 24),
        if (expired.isNotEmpty) ...[
          SectionCard(
            title: 'Expired Members',
            subtitle: '${expired.length} members',
            child: Column(children: expired.take(10).map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cancel, color: AppTheme.red),
                title: Text(m['name'] as String),
                subtitle: Text('Expired ${store.dateLabel(m['expiry_date'], 'd MMM yyyy')}'),
                trailing: Text(money(store.memberDue(m['id'] as int), store.currency)),
                onTap: () => widget.navigate('members'),
              )).toList()),
          ),
          const SizedBox(height: 20),
        ],
        if (expiring7.isNotEmpty)
          SectionCard(
            title: 'Expiring This Week',
            subtitle: '${expiring7.length} members need attention',
            child: Column(children: expiring7.map((m) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning, color: AppTheme.amber),
                title: Text(m['name'] as String),
                subtitle: Text('Expires ${store.dateLabel(m['expiry_date'], 'd MMM')}'),
                trailing: Text(money(store.memberDue(m['id'] as int), store.currency)),
                onTap: () => widget.navigate('members'),
              )).toList()),
          ),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );

  Widget _summaryCard(double width, String label, String value, IconData icon, Color color) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 14),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );

  Widget _section(String title, Widget child) => SectionCard(title: title, child: child);

  Widget _topPlans(GymStore store, dynamic analytics) {
    final raw = analytics.activePlans as Map;
    final plans = raw.entries
        .map((e) => MapEntry<String, num>(e.key as String, (e.value as num)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (plans.isEmpty) return const Text('No data');
    return Column(
      children: plans.take(5).map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)), const Spacer(), Text('${e.value.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600))]),
      )).toList(),
    );
  }

  Widget _paymentMethods(GymStore store, dynamic analytics) {
    final raw = analytics.paymentMethods as Map;
    final methods = raw.entries
        .map((e) => MapEntry<String, num>(e.key as String, (e.value as num)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (methods.isEmpty) return const Text('No data');
    return Column(
      children: methods.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [Text(titleCase(e.key), style: const TextStyle(fontWeight: FontWeight.w500)), const Spacer(), Text(money(e.value, store.currency), style: const TextStyle(fontWeight: FontWeight.w600))]),
      )).toList(),
    );
  }
}
