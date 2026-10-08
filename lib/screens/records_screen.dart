import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/entities.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../services/export_service.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';
import 'member_detail_screen.dart';

String recordValue(
  GymStore store,
  EntitySpec spec,
  RecordData row,
  String key,
) {
  final f = spec.fields.firstWhere((f) => f.key == key);
  final v = row[key];
  if (key == 'status' && spec.table == 'members') {
    return titleCase(store.memberStatus(row));
  }
  if (f.type == 'reference') return store.label(f.reference!, v);
  if (f.type == 'date') return store.dateLabel(v);
  if (f.type == 'money') return money(v, store.currency);
  if (key == 'duration_days') return '$v days';
  if (key == 'duration_weeks') return '$v weeks';
  if (v == null || v == '') return '—';
  return f.type == 'select' ? titleCase(v as String) : v.toString();
}

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.table});
  final String table;
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _query = '', _filter = 'all';
  int _page = 0;
  bool _ascending = false;
  EntitySpec get spec => entities[widget.table]!;
  Future<void> _edit(GymStore store, [RecordData? row]) async {
    if (await editRecord(context, store, spec, record: row) && mounted) {
      toast(context, '${titleCase(spec.singular)} saved');
    }
  }

  Future<void> _delete(GymStore store, RecordData row) async {
    if (!await confirm(
      context,
      'Delete ${spec.singular}?',
      'This permanently removes the record. Linked history is protected.',
      label: 'Delete',
    )) {
      return;
    }
    try {
      await store.delete(widget.table, row['id'] as int);
      if (mounted) toast(context, 'Record deleted');
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    }
  }

  void _open(GymStore store, RecordData row) {
    if (widget.table == 'members') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: store,
            child: MemberDetailScreen(memberId: row['id'] as int),
          ),
        ),
      );
    } else {
      _edit(store, row);
    }
  }

  List<String> get filters => switch (widget.table) {
    'members' => ['all', 'active', 'expired', 'inactive', 'suspended'],
    'payments' => ['all', 'completed', 'pending', 'failed'],
    'trainers' => ['all', 'active', 'inactive'],
    'inventory_items' => ['all', 'good', 'fair', 'poor', 'maintenance'],
    'workout_plans' => ['all', 'beginner', 'intermediate', 'advanced'],
    _ => ['all'],
  };
  String status(GymStore store, RecordData row) => widget.table == 'members'
      ? store.memberStatus(row)
      : (row[widget.table == 'inventory_items'
                    ? 'condition'
                    : widget.table == 'workout_plans'
                    ? 'level'
                    : 'status']
                as String? ??
            '');
  Future<void> _export(GymStore store, List<RecordData> rows) async {
    String escape(Object? v) => '"${v.toString().replaceAll('"', '""')}"';
    final headers = spec.fields.map((f) => f.label).toList();
    final csv = [
      headers.map(escape).join(','),
      ...rows.map(
        (row) => spec.fields
            .map((f) {
              var value = recordValue(store, spec, row, f.key);
              // Guard spreadsheet formula injection in text fields.
              if (RegExp(r'^[=+@\-\t\r]').hasMatch(value)) value = "'$value";
              return escape(value);
            })
            .join(','),
      ),
    ].join('\r\n');
    try {
      await downloadText('fitguide-${widget.table}.csv', csv, 'text/csv');
    } catch (_) {
      if (mounted) {
        toast(context, 'Export could not be saved. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final rows = store
        .rows(widget.table)
        .where(
          (r) =>
              (_filter == 'all' || status(store, r) == _filter) &&
              spec.fields
                  .map((f) => recordValue(store, spec, r, f.key))
                  .join(' ')
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    rows.sort((a, b) {
      if (widget.table == 'payments') {
        return (b['payment_date'] as int).compareTo(a['payment_date'] as int) *
            (_ascending ? -1 : 1);
      }
      final cmp = (a['name'] as String).toLowerCase().compareTo(
        (b['name'] as String).toLowerCase(),
      );
      return _ascending ? cmp : -cmp;
    });
    final grid = [
      'membership_plans',
      'workout_plans',
      'inventory_items',
    ].contains(widget.table);
    final pages = (rows.length / 10).ceil().clamp(1, 999999);
    final page = _page.clamp(0, pages - 1);
    final visible = rows.skip(page * 10).take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          title: spec.title,
          subtitle: spec.subtitle,
          action: FilledButton.icon(
            onPressed: () => _edit(store),
            icon: const Icon(Icons.add, size: 20),
            label: Text('Add ${spec.singular}'),
          ),
        ),
        const SizedBox(height: 24),
        if (widget.table == 'payments') ...[
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _smallStat(
                'Collected',
                money(
                  store
                      .rows('payments')
                      .where((p) => p['status'] == 'completed')
                      .fold<double>(
                        0.0,
                        (v, p) => v + (p['amount'] as num).toDouble(),
                      ),
                  store.currency,
                ),
                AppTheme.green,
              ),
              _smallStat(
                'Pending',
                money(
                  store
                      .rows('payments')
                      .where((p) => p['status'] == 'pending')
                      .fold<double>(
                        0.0,
                        (v, p) => v + (p['amount'] as num).toDouble(),
                      ),
                  store.currency,
                ),
                AppTheme.amber,
              ),
              _smallStat(
                'Receipts',
                '${store.rows('payments').length}',
                AppTheme.blue,
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        SectionCard(
          padding: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 600
                        ? double.infinity
                        : 300,
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: 'Search ${spec.title.toLowerCase()}…',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        _query = v;
                        _page = 0;
                      }),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _ascending = !_ascending),
                    icon: const Icon(Icons.sort, size: 18),
                    label: Text(
                      widget.table == 'payments'
                          ? (_ascending ? 'Oldest first' : 'Latest first')
                          : (_ascending ? 'Name A–Z' : 'Name Z–A'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: rows.isEmpty ? null : () => _export(store, rows),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
              if (filters.length > 1) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filters
                      .map(
                        (f) => ChoiceChip(
                          label: Text(titleCase(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() {
                            _filter = f;
                            _page = 0;
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (rows.isEmpty)
          SectionCard(
            child: EmptyState(
              icon: spec.icon,
              title: store.rows(widget.table).isEmpty
                  ? 'Your first ${spec.singular} starts here'
                  : 'No matching records',
              message: store.rows(widget.table).isEmpty
                  ? 'Add a ${spec.singular} to bring this workspace to life.'
                  : 'Try a different search or filter.',
              action: store.rows(widget.table).isEmpty
                  ? FilledButton.icon(
                      onPressed: () => _edit(store),
                      icon: const Icon(Icons.add),
                      label: Text('Add ${spec.singular}'),
                    )
                  : null,
            ),
          )
        else
          LayoutBuilder(
            builder: (ctx, c) {
              if (grid) {
                final count = c.maxWidth > 1000
                    ? 3
                    : c.maxWidth > 620
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: visible
                      .map(
                        (row) => SizedBox(
                          width: (c.maxWidth - (count - 1) * 18) / count,
                          child: _entityCard(store, row),
                        ),
                      )
                      .toList(),
                );
              }
              if (c.maxWidth < 650) {
                return Column(
                  children: visible
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _open(store, row),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        PersonAvatar(
                                          widget.table == 'payments'
                                              ? store.label(
                                                  'members',
                                                  row['member_id'],
                                                )
                                              : row['name'] as String,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.table == 'payments'
                                                ? store.label(
                                                    'members',
                                                    row['member_id'],
                                                  )
                                                : row['name'] as String,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        _menu(store, row),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: spec.columns
                                          .skip(1)
                                          .map(
                                            (key) => key == 'status'
                                                ? StatusPill(status(store, row))
                                                : Text(
                                                    recordValue(
                                                      store,
                                                      spec,
                                                      row,
                                                      key,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: c.maxWidth),
                      child: DataTable(
                        columns: [
                          ...spec.columns.map(
                            (key) => DataColumn(
                              label: Text(
                                spec.fields
                                    .firstWhere((f) => f.key == key)
                                    .label,
                              ),
                            ),
                          ),
                          const DataColumn(label: Text('')),
                        ],
                        rows: visible
                            .map(
                              (row) => DataRow(
                                cells: [
                                  ...spec.columns.map(
                                    (key) => DataCell(
                                      key == 'status'
                                          ? StatusPill(status(store, row))
                                          : key == 'name' || key == 'member_id'
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PersonAvatar(
                                                  recordValue(
                                                    store,
                                                    spec,
                                                    row,
                                                    key,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      recordValue(
                                                        store,
                                                        spec,
                                                        row,
                                                        key,
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      widget.table == 'payments'
                                                          ? '${row['transaction_id'] ?? 'Receipt #${row['id']}'}'
                                                          : '${row['phone'] ?? ''}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : Text(
                                              recordValue(
                                                store,
                                                spec,
                                                row,
                                                key,
                                              ),
                                            ),
                                      onTap: () => _open(store, row),
                                    ),
                                  ),
                                  DataCell(_menu(store, row)),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${page * 10 + 1}–${(page * 10 + visible.length)} of ${rows.length} records',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: page > 0
                    ? () => setState(() => _page = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${page + 1} / $pages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: page + 1 < pages
                    ? () => setState(() => _page = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _smallStat(String label, String value, Color color) => SizedBox(
    width: 240,
    child: SectionCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _menu(GymStore store, RecordData row) => PopupMenuButton<String>(
    tooltip: 'Record actions',
    onSelected: (value) {
      if (value == 'delete') {
        _delete(store, row);
      } else if (value == 'open') {
        _open(store, row);
      } else {
        _edit(store, row);
      }
    },
    itemBuilder: (_) => [
      if (widget.table == 'members')
        const PopupMenuItem(value: 'open', child: Text('View profile')),
      const PopupMenuItem(value: 'edit', child: Text('Edit details')),
      const PopupMenuItem(value: 'delete', child: Text('Delete record')),
    ],
  );
  Widget _entityCard(GymStore store, RecordData row) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(spec.icon, color: AppTheme.blue),
            ),
            const Spacer(),
            _menu(store, row),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          row['name'] as String,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (widget.table == 'membership_plans') ...[
          Text(
            money(row['price'], store.currency),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.blue,
            ),
          ),
          Text(
            'every ${row['duration_days']} days',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          for (final feature
              in (row['features'] as String? ?? '')
                  .split(',')
                  .where((v) => v.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.green,
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      feature.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${store.rows('members').where((m) => m['plan_id'] == row['id']).length} members on this plan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else if (widget.table == 'inventory_items') ...[
          Row(
            children: [
              StatusPill(row['condition'] as String? ?? 'good'),
              const Spacer(),
              Text(
                'Qty ${row['quantity']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            titleCase(row['category'] as String),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (row['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(
              row['notes'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ] else ...[
          Row(
            children: [
              StatusPill(row['level'] as String? ?? 'beginner'),
              const Spacer(),
              Text(
                '${row['duration_weeks']} weeks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            row['description'] as String? ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 18),
          Text(
            '${store.rows('member_workout_assignments').where((a) => a['workout_plan_id'] == row['id'] && a['status'] == 'active').length} active assignments',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _edit(store, row),
            child: const Text('Manage details'),
          ),
        ),
      ],
    ),
  );
}
