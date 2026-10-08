import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _query = '', _filter = 'today';
  DateTime? _date;
  int _limit = 30;
  Future<void> _act(Future<void> Function() action, String message) async {
    try {
      await action();
      if (mounted) toast(context, message);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final today = store.calendar.today;
    final rows =
        store.rows('attendance').where((r) {
          final date = store.calendar.day(
            store.calendar.fromTimestamp(r['check_in'])!,
          );
          return (_filter != 'today' || date == today) &&
              (_filter != 'inside' || r['check_out'] == null) &&
              (_date == null || date == _date) &&
              store
                  .label('members', r['member_id'])
                  .toLowerCase()
                  .contains(_query.toLowerCase());
        }).toList()..sort(
          (a, b) => (b['check_in'] as int).compareTo(a['check_in'] as int),
        );
    final todayCount = store
        .rows('attendance')
        .where(
          (r) =>
              store.calendar.day(
                store.calendar.fromTimestamp(r['check_in'])!,
              ) ==
              today,
        )
        .map((r) => r['member_id'])
        .toSet()
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: 'Attendance',
          subtitle:
              'A smooth check-in. A better workout. Every visit accounted for.',
          action: FilledButton.icon(
            onPressed: () async {
              final id = await chooseReference(
                context,
                'member to check in',
                store.rows('members').where(store.eligible).toList(),
              );
              if (id != null) {
                _act(() => store.checkIn(id), 'Member checked in');
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('Check in member'),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _stat(
              'Checked in today',
              '$todayCount',
              Icons.event_available_outlined,
              AppTheme.blue,
            ),
            _stat(
              'On the gym floor',
              '${store.openVisits.length}',
              Icons.sensors,
              AppTheme.green,
            ),
            _stat(
              'All-time visits',
              '${store.rows('attendance').length}',
              Icons.history,
              const Color(0xFF9334E6),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 600
                        ? double.infinity
                        : 290,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search member name',
                      ),
                      onChanged: (v) => setState(() {
                        _query = v;
                        _limit = 30;
                      }),
                    ),
                  ),
                  ...['today', 'inside', 'all'].map(
                    (f) => ChoiceChip(
                      label: Text(
                        f == 'inside' ? 'Currently inside' : titleCase(f),
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() {
                        _filter = f;
                        _date = null;
                        _limit = 30;
                      }),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: _date ?? today,
                        firstDate: DateTime(1970),
                        lastDate: today,
                      );
                      if (chosen != null) {
                        setState(() {
                          _date = store.calendar.atDate(chosen);
                          _filter = 'all';
                          _limit = 30;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(
                      _date == null
                          ? 'Choose date'
                          : store.dateLabel(_date!.millisecondsSinceEpoch),
                    ),
                  ),
                  if (_date != null)
                    IconButton(
                      tooltip: 'Clear date filter',
                      onPressed: () => setState(() => _date = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (rows.isEmpty)
                const EmptyState(
                  title: 'No visits in this view',
                  message: 'Check in an active member, or choose another date.',
                  icon: Icons.event_available_outlined,
                )
              else
                ...rows.take(_limit).map((r) {
                  final name = store.label('members', r['member_id']);
                  final start = asDate(r['check_in'])!;
                  final end = asDate(r['check_out']);
                  final duration = (end ?? DateTime.now())
                      .difference(start)
                      .inMinutes;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            PersonAvatar(name),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${store.dateLabel(r['check_in'], 'd MMM • h:mm a')}  •  ${duration < 0 ? 0 : duration} min',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  if (end != null)
                                    Text(
                                      'Out ${store.dateLabel(r['check_out'], 'h:mm a')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            if (end == null)
                              FilledButton.tonal(
                                onPressed: () => _act(
                                  () => store.checkOut(r['id'] as int),
                                  'Member checked out',
                                ),
                                child: const Text('Check out'),
                              )
                            else
                              const StatusPill('completed'),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }),
              if (rows.length > _limit)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _limit += 30),
                    child: const Text('Load more visits'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) =>
      SizedBox(
        width: 245,
        child: SectionCard(
          padding: 20,
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      );
}
