import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/entities.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import 'common.dart';

Future<bool> editRecord(
  BuildContext context,
  GymStore store,
  EntitySpec spec, {
  RecordData? record,
  RecordData? defaults,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecordEditor(
        store: store,
        spec: spec,
        record: record,
        defaults: defaults,
      ),
    ) ??
    false;

Future<int?> chooseReference(
  BuildContext context,
  String title,
  List<RecordData> records,
) async {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      var query = '';
      return StatefulBuilder(
        builder: (ctx, update) {
          final filtered = records
              .where(
                (r) => '${r['name']} ${r['phone'] ?? ''}'
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
          return SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose $title',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or phone',
                    ),
                    onChanged: (v) => update(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            title: 'No matches',
                            message:
                                'Add a record first or try another search.',
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final row = filtered[i];
                              return ListTile(
                                leading: PersonAvatar(row['name'] as String),
                                title: Text(row['name'] as String),
                                subtitle: row['phone'] != null
                                    ? Text(row['phone'] as String)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pop(ctx, row['id']),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.store,
    required this.spec,
    this.record,
    this.defaults,
  });
  final GymStore store;
  final EntitySpec spec;
  final RecordData? record, defaults;
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, Object?>{};
  bool _saving = false, _renew = false;
  final _operationId = base64UrlEncode(
    List.generate(32, (_) => Random.secure().nextInt(256)),
  );
  String? _error;
  bool get _isNew => widget.record == null;
  @override
  void initState() {
    super.initState();
    for (final f in widget.spec.fields) {
      var value =
          widget.record?[f.key] ?? widget.defaults?[f.key] ?? f.defaultValue;
      if (value == null &&
          f.type == 'date' &&
          f.key != 'expiry_date' &&
          f.key != 'purchase_date') {
        value = dateOnly(DateTime.now()).millisecondsSinceEpoch;
      }
      _values[f.key] = value;
      if (!['date', 'reference', 'select'].contains(f.type)) {
        _controllers[f.key] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    }
    if (widget.spec.table == 'payments' &&
        _isNew &&
        _values['member_id'] != null) {
      final member = widget.store.find('members', _values['member_id']);
      _values['plan_id'] ??= member?['plan_id'];
      final plan = widget.store.find('membership_plans', _values['plan_id']);
      if (plan != null && widget.defaults?['amount'] == null) {
        _controllers['amount']!.text = plan['price'].toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (final f in widget.spec.fields) {
        final c = _controllers[f.key];
        if (c == null) continue;
        final text = c.text.trim();
        _values[f.key] = text.isEmpty
            ? null
            : switch (f.type) {
                'money' => double.parse(text),
                'integer' || 'positive' => int.parse(text),
                _ => text,
              };
      }
      if (widget.spec.table == 'members') {
        final normalized = (_values['phone'] as String).replaceAll(
          RegExp(r'\D'),
          '',
        );
        if (widget.store
            .rows('members')
            .any(
              (m) =>
                  m['id'] != widget.record?['id'] &&
                  (m['phone'] as String).replaceAll(RegExp(r'\D'), '') ==
                      normalized,
            )) {
          throw StateError('A member with this phone number already exists.');
        }
        final start = asDate(_values['join_date']);
        final end = asDate(_values['expiry_date']);
        if (start != null && end != null && end.isBefore(start)) {
          throw StateError('Membership end cannot be before the joining date.');
        }
      }
      await widget.store.save(
        widget.spec.table,
        {..._values, if (!_isNew) 'id': widget.record!['id']},
        renew: _renew,
        operationId: _operationId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  void _planChanged(Object? id) {
    final plan = widget.store.find('membership_plans', id);
    if (plan == null) return;
    if (widget.spec.table == 'members' && _isNew) {
      _values['expiry_date'] =
          (asDate(_values['join_date']) ?? dateOnly(DateTime.now()))
              .add(Duration(days: plan['duration_days'] as int))
              .millisecondsSinceEpoch;
    }
    if (widget.spec.table == 'payments') {
      _controllers['amount']!.text = plan['price'].toString();
    }
  }

  Widget _field(FieldSpec f) {
    final label = '${f.label}${f.required ? ' *' : ''}';
    if (f.type == 'reference') {
      return FormField<Object?>(
        key: ValueKey('${f.key}_${_values[f.key]}'),
        initialValue: _values[f.key],
        validator: (v) =>
            f.required && v == null ? 'Choose ${f.label.toLowerCase()}' : null,
        builder: (field) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _saving
              ? null
              : () async {
                  final id = await chooseReference(
                    context,
                    f.label.toLowerCase(),
                    widget.store
                        .rows(f.reference!)
                        .where(
                          (r) =>
                              f.reference != 'fee_invoices' ||
                              (_values['member_id'] == r['member_id'] &&
                                  widget.store.invoiceBalance(r) > 0),
                        )
                        .map(
                          (r) => {
                            ...r,
                            'name': widget.store.label(f.reference!, r['id']),
                          },
                        )
                        .toList(),
                  );
                  if (id != null && mounted) {
                    setState(() {
                      _values[f.key] = id;
                      field.didChange(id);
                      if (f.key == 'plan_id') _planChanged(id);
                      if (f.key == 'invoice_id') {
                        _controllers['amount']!.text = widget.store
                            .invoiceBalance(
                              widget.store.find('fee_invoices', id)!,
                            )
                            .toString();
                      }
                      if (f.key == 'member_id' &&
                          widget.spec.table == 'payments') {
                        _values['invoice_id'] = null;
                        _values['plan_id'] = widget.store.find(
                          'members',
                          id,
                        )?['plan_id'];
                        _planChanged(_values['plan_id']);
                      }
                    });
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              suffixIcon: !f.required && _values[f.key] != null
                  ? IconButton(
                      onPressed: () => setState(() {
                        _values[f.key] = null;
                        field.didChange(null);
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    )
                  : const Icon(Icons.expand_more),
            ),
            child: Text(
              _values[f.key] == null
                  ? 'Select ${f.label.toLowerCase()}'
                  : widget.store.label(f.reference!, _values[f.key]),
            ),
          ),
        ),
      );
    }
    if (f.type == 'date') {
      return FormField<Object?>(
        key: ValueKey('${f.key}_${_values[f.key]}'),
        initialValue: _values[f.key],
        validator: (v) => f.required && v == null ? 'Choose a date' : null,
        builder: (field) => InkWell(
          onTap: _saving
              ? null
              : () async {
                  final value = asDate(_values[f.key]) ?? DateTime.now();
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: value,
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2100),
                  );
                  if (chosen != null && mounted) {
                    setState(() {
                      _values[f.key] = chosen.millisecondsSinceEpoch;
                      field.didChange(_values[f.key]);
                      if (f.key == 'join_date' && _isNew) {
                        _planChanged(_values['plan_id']);
                      }
                    });
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              suffixIcon: !f.required && _values[f.key] != null
                  ? IconButton(
                      onPressed: () => setState(() {
                        _values[f.key] = null;
                        field.didChange(null);
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              _values[f.key] == null
                  ? 'Select date'
                  : dateLabel(_values[f.key]),
            ),
          ),
        ),
      );
    }
    if (f.type == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: _values[f.key] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: f.options
            .map((v) => DropdownMenuItem(value: v, child: Text(titleCase(v))))
            .toList(),
        onChanged: _saving ? null : (v) => setState(() => _values[f.key] = v),
      );
    }
    final numeric = ['money', 'integer', 'positive'].contains(f.type);
    return TextFormField(
      controller: _controllers[f.key],
      enabled: !_saving,
      maxLines: f.type == 'multiline' ? 3 : 1,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.type == 'phone'
          ? TextInputType.phone
          : f.type == 'email'
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: f.hint),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return f.required ? 'Enter ${f.label.toLowerCase()}' : null;
        }
        if (numeric) {
          final n = f.type == 'money'
              ? double.tryParse(text)
              : int.tryParse(text);
          if (n == null ||
              !n.isFinite ||
              n < 0 ||
              (f.type == 'positive' && n <= 0) ||
              (widget.spec.table == 'payments' &&
                  f.key == 'amount' &&
                  n <= 0)) {
            return 'Enter a valid ${f.type == 'positive' ? 'positive whole' : 'non-negative'} number';
          }
        }
        if (f.type == 'email' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Enter a valid email address';
        }
        if (f.type == 'phone' &&
            text.replaceAll(RegExp(r'\D'), '').length < 7) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.spec.fields;
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 40,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_isNew ? 'Add' : 'Edit'} ${widget.spec.singular}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Keep the details that make your workspace work.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 22),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _form,
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final width = constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 20,
                            children: [
                              for (final f in fields)
                                SizedBox(
                                  width: width >= 500 && f.type != 'multiline'
                                      ? (width - 16) / 2
                                      : width,
                                  child: _field(f),
                                ),
                              if (widget.spec.table == 'payments' &&
                                  widget.record?['status'] != 'completed')
                                SizedBox(
                                  width: width,
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _renew,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: _saving
                                        ? null
                                        : (v) => setState(() => _renew = v!),
                                    title: const Text(
                                      'Renew membership with this payment',
                                    ),
                                    subtitle: const Text(
                                      'For completed payments only. Adds the selected plan duration to the membership.',
                                    ),
                                  ),
                                ),
                              if (_error != null)
                                SizedBox(
                                  width: width,
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(ctx).colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        _saving ? 'Saving…' : 'Save ${widget.spec.singular}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
