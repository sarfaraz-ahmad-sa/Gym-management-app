import 'package:flutter/foundation.dart';
import '../services/db_service.dart';
import 'format.dart';
import 'demo_data.dart';
import 'fee_ledger.dart';

class GymStore extends ChangeNotifier {
  GymStore(this.db, {this.demo = false});
  final DatabaseService db;
  final bool demo;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> initialize() async {
    try {
      if (demo) await seedDemo(db);
      await load();
    } catch (_) {
      error = 'Workspace could not open. Please retry.';
      loading = false;
      notifyListeners();
    }
  }

  bool loading = true;
  String? error;
  String gymName = 'My fitness club', currency = 'PKR';
  String setting(String key, [String fallback = '']) =>
      _settings[key] ?? fallback;
  Map<String, String> _settings = {};
  bool get isCloud => db.isCloud;
  final Map<String, List<RecordData>> _records = {};
  FeeLedger _ledger = FeeLedger([], []);
  List<RecordData> rows(String table) => _records[table] ?? [];
  RecordData? find(String table, Object? id) {
    for (final row in rows(table)) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  String label(String table, Object? id) {
    final row = find(table, id);
    if (row == null) return 'Not assigned';
    if (table == 'fee_invoices') {
      return '${label('members', row['member_id'])} • ${row['period'] ?? dateLabel(row['due_date'])}';
    }
    return row['name'] as String? ?? 'Not assigned';
  }

  String memberStatus(RecordData row) {
    final status = row['status'] as String? ?? 'active';
    if (status != 'active') return status;
    final expiry = asDate(row['expiry_date']);
    return expiry != null && dateOnly(expiry).isBefore(dateOnly(DateTime.now()))
        ? 'expired'
        : status;
  }

  bool eligible(RecordData member) => memberStatus(member) == 'active';

  Future<void> load() async {
    loading = _records.isEmpty;
    error = null;
    notifyListeners();
    try {
      await db.refreshSettings();
      final next = <String, List<RecordData>>{};
      for (final table in dataTables) {
        next[table] = (await db.readRecords(
          table,
        )).map((r) => Map<String, Object?>.from(r)).toList();
      }
      _settings = {};
      for (final key in [
        'gym_logo',
        'gym_address',
        'gym_phone',
        'gym_email',
        'gym_hours',
        'message_tagline',
        'message_payment',
        'message_welcome',
        'message_renewal',
      ]) {
        final value = await db.setting(key);
        if (value != null) _settings[key] = value;
      }
      gymName = await db.setting('gym_name') ?? 'My fitness club';
      currency = await db.setting('currency') ?? 'PKR';
      _records.clear();
      _records.addAll(next);
      _ledger = FeeLedger(rows('fee_invoices'), rows('payments'));
    } catch (_) {
      error = 'Unable to load workspace. Please retry.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> save(
    String table,
    RecordData row, {
    bool renew = false,
    String? operationId,
  }) async {
    if (!dataTables.contains(table)) throw ArgumentError('Unknown record type');
    if (isCloud) {
      await db.request('save', {
        'table': table,
        'row': row,
        'renew': renew,
        'operationId': ?operationId,
      });
      await load();
      return;
    }
    final values = Map<String, Object?>.from(row);
    final id = values.remove('id');
    final database = await db.database;
    await database.transaction((tx) async {
      if (table == 'members') {
        values['join_date'] ??= DateTime.now().millisecondsSinceEpoch;
        if (id == null &&
            values['plan_id'] != null &&
            values['expiry_date'] == null) {
          final plan = find('membership_plans', values['plan_id']);
          values['expiry_date'] = asDate(values['join_date'])!
              .add(Duration(days: (plan?['duration_days'] as int?) ?? 30))
              .millisecondsSinceEpoch;
        }
      }
      if (id == null) {
        await tx.insert(table, values);
      } else {
        await tx.update(table, values, where: 'id = ?', whereArgs: [id]);
      }
      if (table == 'payments' && renew && values['status'] == 'completed') {
        if (id != null) {
          // Editing an already-completed receipt must not extend membership twice.
          final original = find('payments', id);
          if (original?['status'] == 'completed') return;
        }
        final planId = values['plan_id'];
        final plan = find('membership_plans', planId);
        if (plan == null) {
          throw StateError('Choose a membership plan to renew.');
        }
        final memberRows = await tx.query(
          'members',
          where: 'id = ?',
          whereArgs: [values['member_id']],
        );
        if (memberRows.isEmpty) throw StateError('Member no longer exists.');
        final oldExpiry = asDate(memberRows.first['expiry_date']);
        final today = dateOnly(DateTime.now());
        final base = oldExpiry != null && oldExpiry.isAfter(today)
            ? oldExpiry
            : today;
        await tx.update(
          'members',
          {
            'plan_id': planId,
            'status': 'active',
            'expiry_date': base
                .add(Duration(days: plan['duration_days'] as int))
                .millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [values['member_id']],
        );
      }
    });
    await load();
  }

  Future<void> delete(String table, int id) async {
    if (isCloud) {
      await db.request('delete', {'table': table, 'id': id});
      await load();
      return;
    }
    final database = await db.database;
    try {
      await database.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      throw StateError(
        'This record has linked history. Archive the member or remove the linked records first.',
      );
    }
    await load();
  }

  Future<void> checkIn(int memberId, {String? notes}) async {
    if (isCloud) {
      await db.request('checkIn', {'memberId': memberId, 'notes': notes});
      await load();
      return;
    }
    final member = find('members', memberId);
    if (member == null || !eligible(member)) {
      throw StateError(
        'Only active members with a valid membership can check in.',
      );
    }
    final database = await db.database;
    await database.transaction((tx) async {
      final open = await tx.query(
        'attendance',
        where: 'member_id = ? AND check_out IS NULL',
        whereArgs: [memberId],
      );
      if (open.isNotEmpty) {
        throw StateError('This member is already checked in.');
      }
      await tx.insert('attendance', {
        'member_id': memberId,
        'check_in': DateTime.now().millisecondsSinceEpoch,
        'notes': notes,
      });
    });
    await load();
  }

  Future<void> checkOut(int id) async {
    if (isCloud) {
      await db.request('checkOut', {'id': id});
      await load();
      return;
    }
    await (await db.database).update(
      'attendance',
      {'check_out': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ? AND check_out IS NULL',
      whereArgs: [id],
    );
    await load();
  }

  Future<void> assignWorkout(int memberId, int workoutId) async {
    if (isCloud) {
      await db.request('assignWorkout', {
        'memberId': memberId,
        'workoutId': workoutId,
      });
      await load();
      return;
    }
    await (await db.database).transaction((tx) async {
      await tx.update(
        'member_workout_assignments',
        {'status': 'completed'},
        where: 'member_id = ? AND status = ?',
        whereArgs: [memberId, 'active'],
      );
      await tx.insert('member_workout_assignments', {
        'member_id': memberId,
        'workout_plan_id': workoutId,
        'assigned_date': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
      });
    });
    await load();
  }

  double invoiceBalance(RecordData invoice) =>
      _ledger.balances[invoice['id']] ?? 0;
  double memberDue(int memberId) => _ledger.dues[memberId] ?? 0;
  RecordData? lastPayment(int memberId) => _ledger.last[memberId];
  DateTime? dueSince(int memberId) => _ledger.since[memberId];
  Future<int> generateFees(String period, DateTime dueDate) async {
    if (isCloud) {
      final result = await db.request('generateFees', {
        'period': period,
        'dueDate': dueDate.millisecondsSinceEpoch,
      });
      await load();
      return result['created'] as int;
    }
    var created = 0;
    await (await db.database).transaction((tx) async {
      for (final m in rows('members').where((m) => m['status'] == 'active')) {
        final plan = find('membership_plans', m['plan_id']);
        if (plan == null) continue;
        if ((await tx.query(
          'fee_invoices',
          where: 'member_id = ? AND period = ?',
          whereArgs: [m['id'], period],
        )).isNotEmpty) {
          continue;
        }
        await tx.insert('fee_invoices', {
          'member_id': m['id'],
          'amount': plan['price'],
          'due_date': dueDate.millisecondsSinceEpoch,
          'period': period,
          'description': 'Membership fee • $period',
          'status': 'unpaid',
        });
        created++;
      }
    });
    await load();
    return created;
  }

  double revenue(DateTime start, DateTime end) => rows('payments')
      .where((p) {
        final date = asDate(p['payment_date']);
        return p['status'] == 'completed' &&
            date != null &&
            !date.isBefore(start) &&
            date.isBefore(end);
      })
      .fold(0.0, (total, p) => total + (p['amount'] as num).toDouble());
  List<RecordData> get expiring =>
      rows('members').where((m) {
        final expiry = asDate(m['expiry_date']);
        return memberStatus(m) == 'active' &&
            expiry != null &&
            !expiry.isBefore(dateOnly(DateTime.now())) &&
            expiry.isBefore(
              dateOnly(DateTime.now()).add(const Duration(days: 8)),
            );
      }).toList()..sort(
        (a, b) => (a['expiry_date'] as int).compareTo(b['expiry_date'] as int),
      );
  List<RecordData> get overdue =>
      rows('members').where((m) => memberStatus(m) == 'expired').toList();
  List<RecordData> get openVisits =>
      rows('attendance').where((r) => r['check_out'] == null).toList();
}
