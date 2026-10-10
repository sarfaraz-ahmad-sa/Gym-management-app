import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/entities.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../services/export_service.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key, required this.memberId});
  final int memberId;
  Future<void> _action(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) toast(context, 'Saved successfully');
    } catch (e) {
      if (context.mounted) toast(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final member = store.find('members', memberId);
    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Member not found',
          message: 'This record may have been removed.',
        ),
      );
    }
    final payments = store.byMember('payments', memberId);
    final visits = store.byMember('attendance', memberId);
    final assignments = store.byMember('member_workout_assignments', memberId);
    final open = visits.where((v) => v['check_out'] == null).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Member profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PersonAvatar(member['name'] as String, size: 64),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['name'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Member #${member['id']}  •  ${member['phone']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit member',
                            onPressed: () => editRecord(
                              context,
                              store,
                              entities['members']!,
                              record: member,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 20,
                        runSpacing: 14,
                        children: [
                          StatusPill(store.memberStatus(member)),
                          Text(
                            store.label('membership_plans', member['plan_id']),
                          ),
                          Text(
                            'Expires ${store.dateLabel(member['expiry_date'])}',
                          ),
                          Text(
                            'Pending fees: ${money(store.memberDue(memberId), store.currency)}',
                          ),
                          Text(
                            'Trainer: ${store.label('trainers', member['trainer_id'])}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => editRecord(
                              context,
                              store,
                              entities['payments']!,
                              defaults: {'member_id': memberId},
                            ),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Record payment / renew'),
                          ),
                          OutlinedButton.icon(
                            onPressed: open != null
                                ? () => _action(
                                    context,
                                    () => store.checkOut(open['id'] as int),
                                  )
                                : store.eligible(member)
                                ? () => _action(
                                    context,
                                    () => store.checkIn(memberId),
                                  )
                                : null,
                            icon: Icon(
                              open != null ? Icons.logout : Icons.login,
                            ),
                            label: Text(
                              open != null ? 'Check out' : 'Check in',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _stat(
                      context,
                      'Total paid',
                      money(
                        payments
                            .where((p) => p['status'] == 'completed')
                            .fold<double>(
                              0.0,
                              (v, p) => v + (p['amount'] as num).toDouble(),
                            ),
                        store.currency,
                      ),
                    ),
                    _stat(context, 'Total visits', '${visits.length}'),
                    _stat(
                      context,
                      'Member since',
                      store.dateLabel(member['join_date']),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Member details',
                  child: Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    children: [
                      _detail(context, 'Email', member['email']),
                      _detail(context, 'Address', member['address']),
                      _detail(context, 'Fitness goal', member['goal']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Workout program',
                  subtitle: 'Assign a program to guide their next phase.',
                  action: TextButton(
                    onPressed: () async {
                      final workoutId = await chooseReference(
                        context,
                        'workout program',
                        store.rows('workout_plans'),
                      );
                      if (workoutId != null && context.mounted) {
                        _action(
                          context,
                          () => store.assignWorkout(memberId, workoutId),
                        );
                      }
                    },
                    child: const Text('Assign program'),
                  ),
                  child: assignments.isEmpty
                      ? const Text('No workout assigned yet.')
                      : Column(
                          children: assignments.map((a) {
                            final workout = store.find(
                              'workout_plans',
                              a['workout_plan_id'],
                            );
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.auto_awesome_outlined,
                                color: AppTheme.blue,
                              ),
                              title: Text(
                                workout?['name'] as String? ??
                                    'Removed program',
                              ),
                              subtitle: Text(
                                'Assigned ${store.dateLabel(a['assigned_date'])}',
                              ),
                              trailing: StatusPill(a['status'] as String),
                              onTap: workout == null
                                  ? null
                                  : () => showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(workout['name'] as String),
                                        content: SingleChildScrollView(
                                          child: Text(
                                            workout['description'] as String? ??
                                                '',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Payment history',
                  subtitle: '${payments.length} receipts',
                  child: payments.isEmpty
                      ? const Text('No payments recorded.')
                      : Column(
                          children: payments
                              .map(
                                (p) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppTheme.blue,
                                  ),
                                  title: Text(
                                    money(p['amount'], store.currency),
                                  ),
                                  subtitle: Text(
                                    '${store.dateLabel(p['payment_date'])} • ${titleCase(p['payment_method'] as String? ?? 'cash')}',
                                  ),
                                  trailing: StatusPill(p['status'] as String),
                                  onTap: () =>
                                      _receipt(context, store, member, p),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Attendance history',
                  subtitle: '${visits.length} sessions',
                  child: visits.isEmpty
                      ? const Text('No visits recorded.')
                      : Column(
                          children: visits
                              .take(30)
                              .map(
                                (v) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.event_available_outlined,
                                    color: AppTheme.green,
                                  ),
                                  title: Text(
                                    store.dateLabel(
                                      v['check_in'],
                                      'd MMM yyyy • h:mm a',
                                    ),
                                  ),
                                  subtitle: Text(
                                    v['check_out'] == null
                                        ? 'Currently checked in'
                                        : 'Checked out ${store.dateLabel(v['check_out'], 'h:mm a')}',
                                  ),
                                  trailing: v['check_out'] == null
                                      ? TextButton(
                                          onPressed: () => _action(
                                            context,
                                            () =>
                                                store.checkOut(v['id'] as int),
                                          ),
                                          child: const Text('Check out'),
                                        )
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 360 ? 220 : 245,
    child: SectionCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
  Widget _detail(BuildContext context, String label, Object? value) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 360 ? 220 : 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value == null || value == '' ? 'Not provided' : value.toString()),
      ],
    ),
  );
  void _receipt(
    BuildContext context,
    GymStore store,
    RecordData member,
    RecordData payment,
  ) {
    final text =
        '${store.gymName}\nPAYMENT RECEIPT #${payment['id']}\n\nMember: ${member['name']}\nPlan: ${store.label('membership_plans', payment['plan_id'])}\nAmount: ${money(payment['amount'], store.currency)}\nDate: ${store.dateLabel(payment['payment_date'])}\nStatus: ${titleCase(payment['status'] as String)}\nMethod: ${titleCase(payment['payment_method'] as String? ?? 'cash')}\nReference: ${payment['transaction_id'] ?? '—'}\n';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment receipt'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await downloadText(
                  'receipt-${payment['id']}.txt',
                  text,
                  'text/plain',
                );
              } catch (_) {
                if (ctx.mounted) toast(ctx, 'Could not export receipt.');
              }
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export receipt'),
          ),
        ],
      ),
    );
  }
}
