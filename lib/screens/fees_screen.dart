import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/entities.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';
import '../services/export_service.dart';
import '../services/workspace_export.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});
  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  bool _busy = false;
  int _page = 0;
  Future<void> _generate(GymStore store) async {
    final now = store.calendar.instant(DateTime.now());
    DateTime due = store.calendar.today;
    final month = TextEditingController(
      text: DateFormat('yyyy-MM').format(now),
    );
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Generate monthly fees'),
          content: Form(
            key: form,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create one invoice per active member with an assigned plan. The amount uses their current plan price. Existing invoices for this month are skipped.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: month,
                    decoration: const InputDecoration(
                      labelText: 'Fee month (YYYY-MM)',
                    ),
                    validator: (v) =>
                        RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(v ?? '')
                        ? null
                        : 'Enter a valid month',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      'Due ${store.dateLabel(due.millisecondsSinceEpoch)}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: due,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        update(() => due = store.calendar.atDate(picked));
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      setState(() => _busy = true);
      try {
        final count = await store.generateFees(month.text, due);
        if (mounted) toast(context, '$count invoices created');
      } catch (e) {
        if (mounted) toast(context, friendlyError(e));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    month.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final invoices = store.rows('fee_invoices');
    final pages = (invoices.length / 50).ceil().clamp(1, 1000000);
    if (_page >= pages) _page = pages - 1;
    final dueMembers = store
        .rows('members')
        .where((m) => store.memberDue(m['id'] as int) > 0)
        .toList();
    final total = dueMembers.fold<double>(
      0,
      (v, m) => v + store.memberDue(m['id'] as int),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: 'Fees & outstanding balances',
          subtitle:
              'Monthly invoices, partial payments and a clear member ledger.',
          action: FilledButton.icon(
            onPressed: _busy ? null : () => _generate(store),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(_busy ? 'Generating…' : 'Generate fees'),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Outstanding ${money(total, store.currency)}',
          subtitle: '${dueMembers.length} members with pending fees',
          action: OutlinedButton.icon(
            onPressed: () async {
              final lines = <List<Object?>>[
                [
                  'Member',
                  'Phone',
                  'Pending',
                  'Due since',
                  'Last paid',
                  'Last payment date',
                ],
              ];
              for (final m in dueMembers) {
                final id = m['id'] as int, last = store.lastPayment(id);
                lines.add([
                  m['name'],
                  m['phone'],
                  store.memberDue(id),
                  store.dueSince(id)?.toIso8601String(),
                  last?['amount'],
                  last == null ? '' : store.dateLabel(last['payment_date']),
                ]);
              }
              final csv = lines
                  .map((row) => row.map(csvCell).join(','))
                  .join('\r\n');
              await downloadText('fitguide-fee-balances.csv', csv, 'text/csv');
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download dues'),
          ),
          child: dueMembers.isEmpty
              ? const EmptyState(
                  title: 'No pending fees',
                  message: 'Generate monthly fees or add a fee invoice to track amounts owed.',
                )
              : Column(
                  children: dueMembers.map((m) {
                    final id = m['id'] as int;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PersonAvatar(m['name'] as String),
                      title: Text(m['name'] as String),
                      subtitle: Text(
                        'Due ${money(store.memberDue(id), store.currency)} • since ${store.dateLabel(store.dueSince(id)?.millisecondsSinceEpoch)}',
                      ),
                      trailing: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Fee invoices',
          action: TextButton.icon(
            onPressed: () =>
                editRecord(context, store, entities['fee_invoices']!),
            icon: const Icon(Icons.add),
            label: const Text('Add invoice'),
          ),
          child: invoices.isEmpty
              ? const EmptyState(
                  title: 'No fee invoices yet',
                  message: 'Generate the current month’s fees, or add a custom invoice.',
                )
              : Column(
                  children: invoices
                      .skip(_page * 50)
                      .take(50)
                      .map(
                        (i) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(store.label('members', i['member_id'])),
                          subtitle: Text(
                            '${i['period'] ?? 'Custom fee'} • Due ${store.dateLabel(i['due_date'])}\n${money(i['amount'], store.currency)} billed • ${money(store.invoiceBalance(i), store.currency)} pending',
                          ),
                          isThreeLine: true,
                          onTap: () => editRecord(
                            context,
                            store,
                            entities['fee_invoices']!,
                            record: i,
                          ),
                          trailing: i['status'] == 'void'
                              ? const Text('Voided')
                              : store.invoiceBalance(i) > 0
                              ? TextButton(
                                  onPressed: () => editRecord(
                                    context,
                                    store,
                                    entities['payments']!,
                                    defaults: {
                                      'member_id': i['member_id'],
                                      'invoice_id': i['id'],
                                      'amount': store.invoiceBalance(i),
                                    },
                                  ),
                                  child: const Text('Receive'),
                                )
                              : const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                        ),
                      )
                      .toList(),
                ),
        ),
        if (pages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Page ${_page + 1} of $pages'),
                IconButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _page + 1 < pages
                      ? () => setState(() => _page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
