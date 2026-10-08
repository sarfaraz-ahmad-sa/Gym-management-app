import 'package:flutter/material.dart';

import '../widgets/workspace_logo.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/entities.dart';
import '../core/dashboard_analytics.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';
import 'member_detail_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.navigate});
  final void Function(String) navigate;
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _days = 30;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final scheme = Theme.of(context).colorScheme;
    final now = store.calendar.instant(DateTime.now());
    final today = store.calendar.today;
    final analytics = DashboardAnalytics(store, now: now, days: _days);
    final active = analytics.activeMembers;
    final currentRevenue = analytics.revenue;
    final previousRevenue = analytics.previousRevenue;
    final pending = analytics.outstanding;
    final visits = analytics.visits;
    final labels = analytics.buckets
        .map((b) => DateFormat('d MMM').format(b.start))
        .toList();
    final revenue = analytics.buckets.map((b) => b.revenue).toList();
    final attendance = analytics.buckets
        .map((b) => b.visits.toDouble())
        .toList();
    final recent = store.rows('members').toList()
      ..sort(
        (a, b) => ((b['join_date'] as int?) ?? 0).compareTo(
          (a['join_date'] as int?) ?? 0,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: 'Welcome to ${store.gymName}',
          subtitle:
              '${DateFormat('EEEE, d MMMM').format(now)}  •  Let’s make it a strong day.',
          action: FilledButton.icon(
            onPressed: () => editRecord(context, store, entities['members']!),
            icon: const Icon(Icons.add),
            label: const Text('Add member'),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            WorkspaceLogo(data: store.setting('gym_logo'), size: 42),
            Text(
              store.setting('gym_hours').isEmpty
                  ? 'Your club. Your community.'
                  : store.setting('gym_hours'),
            ),
            if (store.setting('gym_phone').isNotEmpty)
              Text('Reception: ${store.setting('gym_phone')}'),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.surface, scheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR CLUB TODAY',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${analytics.visitsToday} visits today · ${store.openVisits.length} on the floor',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Member care, payments and daily operations in one place.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    onPressed: () => widget.navigate('attendance'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Check in'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surface,
                      foregroundColor: scheme.primary,
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    onPressed: () =>
                        editRecord(context, store, entities['payments']!),
                    icon: const Icon(Icons.add_card_rounded, size: 18),
                    label: const Text('Record payment'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surface,
                      foregroundColor: scheme.primary,
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    onPressed: () => widget.navigate('fees'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Review dues'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Performance', style: Theme.of(context).textTheme.titleLarge),
            for (final days in [7, 30, 90])
              ChoiceChip(
                label: Text('$days days'),
                selected: _days == days,
                onSelected: (_) => setState(() => _days = days),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${DateFormat('d MMM yyyy').format(analytics.start)} – ${DateFormat('d MMM yyyy').format(today)} · ${store.calendar.timeZone}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (ctx, c) {
            final count = c.maxWidth > 960
                ? 4
                : c.maxWidth >= 320 &&
                      MediaQuery.textScalerOf(context).scale(14) < 20
                ? 2
                : 1;
            final width = (c.maxWidth - (count - 1) * 16) / count;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metric(
                  width,
                  'Active members',
                  '$active',
                  '${store.rows('members').length} total · current status',
                  Icons.people_outline_rounded,
                  AppTheme.blue,
                  () => widget.navigate('members'),
                ),
                _metric(
                  width,
                  'Collected · $_days days',
                  money(currentRevenue, store.currency),
                  previousRevenue == 0
                      ? 'No previous activity to compare'
                      : '${currentRevenue >= previousRevenue ? '+' : ''}${((currentRevenue - previousRevenue) / previousRevenue * 100).toStringAsFixed(1)}% vs previous $_days days',
                  Icons.account_balance_wallet_outlined,
                  AppTheme.green,
                  () => widget.navigate('payments'),
                ),
                _metric(
                  width,
                  'Visits · $_days days',
                  '$visits',
                  '${analytics.uniqueVisitors} unique members in this period',
                  Icons.event_available_outlined,
                  const Color(0xFF9334E6),
                  () => widget.navigate('attendance'),
                ),
                _metric(
                  width,
                  'Outstanding · all dates',
                  money(pending, store.currency),
                  '${store.rows('members').where((m) => store.memberDue(m['id'] as int) > 0).length} members to follow up',
                  Icons.schedule_outlined,
                  AppTheme.amber,
                  () => widget.navigate('fees'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (ctx, c) {
            final left = SectionCard(
              title: 'Revenue trend',
              subtitle: 'Completed payments • ${store.currency}',
              action: TextButton(
                onPressed: () => widget.navigate('payments'),
                child: const Text('Payments'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money(
                      revenue.fold<double>(0.0, (a, b) => a + b),
                      store.currency,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'over the selected period',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  _barChart(
                    revenue,
                    labels,
                    AppTheme.blue,
                    buckets: analytics.buckets,
                    monetary: true,
                  ),
                ],
              ),
            );
            final right = SectionCard(
              title: 'Attendance trend',
              subtitle: 'Visits over the selected $_days days',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${attendance.fold<double>(0.0, (a, b) => a + b).toInt()}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 8),
                      const Text('visits'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${analytics.uniqueVisitors} unique members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  _barChart(
                    attendance,
                    labels,
                    AppTheme.green,
                    buckets: analytics.buckets,
                  ),
                ],
              ),
            );
            if (c.maxWidth < 820 ||
                MediaQuery.textScalerOf(context).scale(14) >= 22) {
              return Column(
                children: [left, const SizedBox(height: 20), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 22),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _analyticsDetails(store, analytics),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (ctx, c) {
            final left = SectionCard(
              title: 'Member spotlight',
              subtitle: 'The latest members in your community',
              action: TextButton(
                onPressed: () => widget.navigate('members'),
                child: const Text('View all'),
              ),
              child: recent.isEmpty
                  ? EmptyState(
                      title: 'Welcome your first member',
                      message:
                          'Register a member to start building your community.',
                      icon: Icons.people_outline,
                      action: FilledButton(
                        onPressed: () =>
                            editRecord(context, store, entities['members']!),
                        child: const Text('Add member'),
                      ),
                    )
                  : Column(
                      children: recent
                          .take(5)
                          .map(
                            (m) => Column(
                              children: [
                                InkWell(
                                  onTap: () => _profile(store, m),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      children: [
                                        PersonAvatar(m['name'] as String),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m['name'] as String,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                store.label(
                                                  'membership_plans',
                                                  m['plan_id'],
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusPill(store.memberStatus(m)),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                          )
                          .toList(),
                    ),
            );
            final right = Column(
              children: [
                SectionCard(
                  title: 'Membership follow-ups',
                  subtitle: 'Expiring in 7 days or already expired',
                  child: [...store.overdue, ...store.expiring].isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.green,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You’re all caught up. No renewals due.',
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [...store.overdue, ...store.expiring]
                              .take(4)
                              .map(
                                (m) => InkWell(
                                  onTap: () => _profile(store, m),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 17),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: AppTheme.amber.withValues(
                                              alpha: .09,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.schedule,
                                            size: 18,
                                            color: AppTheme.amber,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m['name'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${store.memberStatus(m) == 'expired' ? 'Expired' : 'Expires'} ${store.dateLabel(m['expiry_date'], 'd MMM')}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: AppTheme.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 18),
                Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF163355)
                      : const Color(0xFFEAF2FF),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppTheme.blue,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Less admin. More energy.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep your floor moving with a quick member check-in.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () => widget.navigate('attendance'),
                          icon: const Icon(Icons.arrow_forward, size: 17),
                          label: const Text('Open attendance'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            if (c.maxWidth < 820 ||
                MediaQuery.textScalerOf(context).scale(14) >= 22) {
              return Column(
                children: [left, const SizedBox(height: 20), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 22),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _analyticsDetails(GymStore store, DashboardAnalytics stats) {
    final methods = stats.paymentMethods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final plans = stats.activePlans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        SectionCard(
          title: 'Period at a glance',
          subtitle: 'All figures follow the selected $_days-day period',
          child: LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 16,
              runSpacing: 20,
              children: [
                for (final item in [
                  ('New members', '${stats.newMembers}'),
                  ('Unique visitors', '${stats.uniqueVisitors}'),
                  ('Completed receipts', '${stats.receipts}'),
                  (
                    'Average receipt',
                    money(stats.averageReceipt, store.currency),
                  ),
                ])
                  SizedBox(
                    width: c.maxWidth >= 760
                        ? (c.maxWidth - 48) / 4
                        : c.maxWidth >= 320
                        ? (c.maxWidth - 16) / 2
                        : c.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _pair(
          SectionCard(
            title: 'Membership health',
            subtitle: 'Current status · all members',
            action: TextButton(
              onPressed: () => widget.navigate('members'),
              child: const Text('Members'),
            ),
            child: stats.totalMembers == 0
                ? const EmptyState(
                    title: 'No members yet',
                    message: 'Add members to see your membership breakdown.',
                  )
                : Column(
                    children: [
                      for (final entry in stats.memberStatuses.entries)
                        _breakdown(
                          titleCase(entry.key),
                          '${entry.value}',
                          entry.value.toDouble(),
                          stats.totalMembers.toDouble(),
                          entry.key == 'active'
                              ? AppTheme.green
                              : entry.key == 'expired'
                              ? AppTheme.red
                              : AppTheme.amber,
                        ),
                    ],
                  ),
          ),
          SectionCard(
            title: 'Payment methods',
            subtitle: 'Completed receipts · selected $_days days',
            child: methods.isEmpty
                ? const EmptyState(
                    title: 'No completed payments',
                    message:
                        'Completed receipts in this period will appear here.',
                  )
                : Column(
                    children: [
                      for (final entry in methods)
                        _breakdown(
                          titleCase(entry.key),
                          money(entry.value, store.currency),
                          entry.value,
                          stats.revenue,
                          AppTheme.blue,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        _pair(
          SectionCard(
            title: 'Popular memberships',
            subtitle: 'Assigned plans · currently active members',
            action: TextButton(
              onPressed: () => widget.navigate('membership_plans'),
              child: const Text('Plans'),
            ),
            child: plans.isEmpty
                ? const EmptyState(
                    title: 'No active memberships',
                    message: 'Assign membership plans to active members.',
                  )
                : Column(
                    children: [
                      for (final entry in plans.take(5))
                        _breakdown(
                          entry.key,
                          '${entry.value}',
                          entry.value.toDouble(),
                          stats.activeMembers.toDouble(),
                          AppTheme.blue,
                        ),
                      if (plans.length > 5)
                        Text(
                          '${plans.length - 5} more plans · open Plans to review all',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
          ),
          SectionCard(
            title: 'Gym operations',
            subtitle: 'Current workspace records',
            child: Column(
              children: [
                _operation(
                  'Trainers',
                  '${store.rows('trainers').where((r) => r['status'] == 'active').length} active trainers',
                  Icons.sports_gymnastics_rounded,
                  'trainers',
                ),
                _operation(
                  'Workouts',
                  '${store.rows('workout_plans').length} workout plans',
                  Icons.auto_awesome_outlined,
                  'workout_plans',
                ),
                _operation(
                  'Equipment',
                  '${store.rows('inventory_items').where((r) => r['condition'] == 'maintenance' || r['condition'] == 'poor').length} records need attention',
                  Icons.fitness_center_rounded,
                  'inventory_items',
                ),
                _operation(
                  'Messages',
                  'Welcome and renewal follow-ups',
                  Icons.chat_bubble_outline_rounded,
                  'messages',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth < 820 ||
          MediaQuery.textScalerOf(context).scale(14) >= 22) {
        return Column(children: [first, const SizedBox(height: 20), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 20),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _breakdown(
    String label,
    String value,
    double amount,
    double total,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 9),
        Semantics(
          label: '$label: $value',
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (amount / total).clamp(0.0, 1.0),
            color: color,
            backgroundColor: color.withValues(alpha: .09),
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  );

  Widget _operation(
    String title,
    String subtitle,
    IconData icon,
    String destination,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppTheme.blue),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => widget.navigate(destination),
  );

  void _profile(GymStore store, RecordData member) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: MemberDetailScreen(memberId: member['id'] as int),
      ),
    ),
  );
  Widget _metric(
    double width,
    String title,
    String value,
    String detail,
    IconData icon,
    Color color,
    VoidCallback tap,
  ) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(width < 200 ? 16 : 21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _barChart(
    List<double> values,
    List<String> labels,
    Color color, {
    required List<AnalyticsBucket> buckets,
    bool monetary = false,
  }) {
    final maximum = values.fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message:
                        '${labels[i]} – ${DateFormat('d MMM').format(DateTime(buckets[i].end.year, buckets[i].end.month, buckets[i].end.day - 1))} · ${monetary ? money(values[i], context.read<GymStore>().currency) : '${values[i].toInt()} visits'}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 22,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                NumberFormat.compact().format(values[i]),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: maximum == 0
                                ? 0
                                : values[i] / maximum * 118,
                            constraints: const BoxConstraints(maxWidth: 42),
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: i == values.length - 1 ? 1 : .28,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 22,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                labels[i],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          maximum == 0
              ? 'No ${monetary ? 'completed receipts' : 'visits'} in this period.'
              : 'Tap a bar for its exact total. Labels show the first day of each interval.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
