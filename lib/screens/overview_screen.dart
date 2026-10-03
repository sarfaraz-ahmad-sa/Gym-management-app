import 'package:flutter/material.dart';
import '../widgets/workspace_logo.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/entities.dart';
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
  int _months = 6;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final now = DateTime.now();
    final today = dateOnly(now);
    final active = store.rows('members').where(store.eligible).length;
    final currentRevenue = store.revenue(
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    );
    final previousRevenue = store.revenue(
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
    );
    final pending = store
        .rows('members')
        .fold<double>(0, (sum, m) => sum + store.memberDue(m['id'] as int));
    final visits = store
        .rows('attendance')
        .where((v) => dateOnly(asDate(v['check_in'])!) == today)
        .length;
    final labels = List.generate(
      _months,
      (i) => DateFormat(
        'MMM',
      ).format(DateTime(now.year, now.month - _months + 1 + i)),
    );
    final revenue = List.generate(_months, (i) {
      final month = now.month - _months + 1 + i;
      return store.revenue(
        DateTime(now.year, month),
        DateTime(now.year, month + 1),
      );
    });
    final attendance = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return store
          .rows('attendance')
          .where((v) => dateOnly(asDate(v['check_in'])!) == date)
          .length
          .toDouble();
    });
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
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (ctx, c) {
            final count = c.maxWidth > 1050
                ? 4
                : c.maxWidth > 480
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
                  '${store.rows('members').length} total members',
                  Icons.people_outline_rounded,
                  AppTheme.blue,
                  () => widget.navigate('members'),
                ),
                _metric(
                  width,
                  'Revenue this month',
                  money(currentRevenue, store.currency),
                  previousRevenue == 0
                      ? 'Completed payments only'
                      : '${currentRevenue >= previousRevenue ? '+' : ''}${((currentRevenue - previousRevenue) / previousRevenue * 100).toStringAsFixed(1)}% vs last full month',
                  Icons.account_balance_wallet_outlined,
                  AppTheme.green,
                  () => widget.navigate('payments'),
                ),
                _metric(
                  width,
                  'Visits today',
                  '$visits',
                  '${store.openVisits.length} currently on the floor',
                  Icons.event_available_outlined,
                  const Color(0xFF9334E6),
                  () => widget.navigate('attendance'),
                ),
                _metric(
                  width,
                  'Pending fees',
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
              title: 'Revenue overview',
              subtitle: 'Completed payments • ${store.currency}',
              action: DropdownButton<int>(
                value: _months,
                underline: const SizedBox.shrink(),
                style: Theme.of(context).textTheme.bodySmall,
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 months')),
                  DropdownMenuItem(value: 3, child: Text('3 months')),
                ],
                onChanged: (v) => setState(() => _months = v!),
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
                  _barChart(revenue, labels, AppTheme.blue, monetary: true),
                ],
              ),
            );
            final right = SectionCard(
              title: 'Attendance this week',
              subtitle: 'Visits over the last 7 days',
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
                    'Every visit is a step forward.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  _barChart(
                    attendance,
                    List.generate(
                      7,
                      (i) => DateFormat(
                        'E',
                      ).format(today.subtract(Duration(days: 6 - i))),
                    ),
                    AppTheme.green,
                  ),
                ],
              ),
            );
            if (c.maxWidth < 820) {
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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                store.label(
                                                  'membership_plans',
                                                  m['plan_id'],
                                                ),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
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
                                                '${store.memberStatus(m) == 'expired' ? 'Expired' : 'Expires'} ${dateLabel(m['expiry_date'], 'd MMM')}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
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
                      ? const Color(0xFF182844)
                      : const Color(0xFFE8F0FE),
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
            if (c.maxWidth < 820) {
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
          padding: const EdgeInsets.all(21),
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
                maxLines: 2,
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
    bool monetary = false,
  }) {
    final max = values.fold<double>(0.0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 183,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          values.length,
          (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        monetary && values[i] >= 1000
                            ? '${(values[i] / 1000).toStringAsFixed(1)}k'
                            : '${values[i].toInt()}',
                        maxLines: 1,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    height: max == 0
                        ? 3
                        : (values[i] / max * 126).clamp(3, 126),
                    constraints: const BoxConstraints(maxWidth: 42),
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: i == values.length - 1 ? 1 : .2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
