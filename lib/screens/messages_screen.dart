import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/message_templates.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int? _memberId;
  String _template = 'payment';
  final _message = TextEditingController();
  bool _launching = false;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _fill(GymStore store) {
    final member = store.find('members', _memberId);
    if (member == null) return;
    _message.text = memberMessage(store, member, _template);
  }

  Future<void> _open(GymStore store) async {
    final member = store.find('members', _memberId);
    if (member == null || _message.text.trim().isEmpty) {
      toast(context, 'Choose a member and enter a message.');
      return;
    }
    setState(() => _launching = true);
    try {
      var phone = (member['phone'] as String).replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('00')) phone = phone.substring(2);
      if (phone.startsWith('0')) {
        phone =
            '${await store.db.setting('country_code') ?? '92'}${phone.substring(1)}';
      }
      final uri = Uri.https('wa.me', '/$phone', {'text': _message.text.trim()});
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('WhatsApp could not open. Check the phone number.');
      }
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final followups = store
        .rows('members')
        .where((m) => store.memberDue(m['id'] as int) > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          title: 'Member messages',
          subtitle: 'A thoughtful nudge keeps your community connected.',
        ),
        const SizedBox(height: 26),
        SectionCard(
          title: 'Write a WhatsApp message',
          subtitle: 'Review your message before opening WhatsApp.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.green,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _memberId == null
                          ? 'Choose a recipient'
                          : store.label('members', _memberId),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final id = await chooseReference(
                        context,
                        'member',
                        store.rows('members'),
                      );
                      if (id != null) {
                        setState(() {
                          _memberId = id;
                          _fill(store);
                        });
                      }
                    },
                    child: Text(_memberId == null ? 'Select' : 'Change'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _template,
                decoration: const InputDecoration(
                  labelText: 'Message template',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'renewal',
                    child: Text('Membership renewal'),
                  ),
                  DropdownMenuItem(
                    value: 'welcome',
                    child: Text('Welcome to the club'),
                  ),
                  DropdownMenuItem(
                    value: 'payment',
                    child: Text('Payment reminder'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _template = v!;
                  _fill(store);
                }),
              ),
              const SizedBox(height: 12),
              if (_memberId != null)
                Text(
                  'Pending ${money(store.memberDue(_memberId!), store.currency)} • Last payment ${money(store.lastPayment(_memberId!)?['amount'] ?? 0, store.currency)}',
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText:
                      'Select a member to start with a personalized message…',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _launching ? null : () => _open(store),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(_launching ? 'Opening…' : 'Open WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _message.text),
                      );
                      if (context.mounted) toast(context, 'Message copied');
                    },
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy message'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'You press Send in WhatsApp. No message is sent automatically.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Pending fee follow-ups',
          subtitle: '${followups.length} members need a check-in',
          child: followups.isEmpty
              ? const EmptyState(
                  title: 'All recorded fees are up to date',
                  message: 'Members with unpaid invoices or pending receipts appear here.',
                )
              : Column(
                  children: followups
                      .map(
                        (m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PersonAvatar(m['name'] as String),
                          title: Text(m['name'] as String),
                          subtitle: Text(
                            'Pending ${money(store.memberDue(m['id'] as int), store.currency)} • since ${store.dateLabel(store.dueSince(m['id'] as int)?.millisecondsSinceEpoch)}',
                          ),
                          trailing: TextButton(
                            onPressed: () => setState(() {
                              _memberId = m['id'] as int;
                              _template = 'payment';
                              _fill(store);
                            }),
                            child: const Text('Prepare message'),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
