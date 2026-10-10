import 'package:flutter/foundation.dart';

import '../services/db_service.dart';
import 'format.dart';
import 'demo_data.dart';
import 'fee_ledger.dart';
import 'workspace_calendar.dart';
import 'dashboard_analytics.dart';

import 'package:intl/intl.dart';

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
  int loadCount = 0; // Incremented on each load - use to detect changes
  String? error;
  String gymName = 'My fitness club', currency = 'PKR';
  String setting(String key, [String fallback = '']) =>
      _settings[key] ?? fallback;
  Map<String, String> _settings = {};
  bool get isCloud => db.isCloud;
  WorkspaceCalendar get calendar =>
      WorkspaceCalendar(setting('timezone', defaultWorkspaceTimeZone));
  String dateLabel(Object? value, [String format = 'd MMM yyyy']) {
    final date = calendar.fromTimestamp(value);
    return date == null ? '—' : DateFormat(format).format(date);
  }

  final Map<String, List<RecordData>> _records = {};
  final Map<String, Map<dynamic, RecordData>> _recordIndex = {}; // O(1) lookups
  final Map<String, Map<int, List<RecordData>>> _byMemberIndex = {}; // O(n) → O(1) by member_id
  FeeLedger _ledger = FeeLedger([], []);
  
  // Cached analytics - invalidated on data change
  DashboardAnalytics? _analytics7;
  DashboardAnalytics? _analytics30;
  DashboardAnalytics? _analytics90;
  
  // Cached lazy getters
  List<RecordData>? _cachedExpiring;
  List<RecordData>? _cachedOverdue;
  List<RecordData>? _cachedOpenVisits;
  
  List<RecordData> rows(String table) => _records[table] ?? [];

  /// Get all records for a specific member_id - O(1) lookup
  List<RecordData> byMember(String table, int memberId) {
    return _byMemberIndex[table]?[memberId] ?? [];
  }

  RecordData? find(String table, Object? id) {
    if (id == null) return null;
    final index = _recordIndex[table];
    if (index != null) return index[id];
    // Fallback to linear search if index not built
    for (final row in rows(table)) {
      if (row['id'] == id) return row;
    }
    return null;
  }
  
  /// Get cached analytics for specified days (7, 30, or 90)
  DashboardAnalytics analytics({int days = 30}) {
    switch (days) {
      case 7:
        _analytics7 ??= DashboardAnalytics(this, days: 7);
        return _analytics7!;
      case 90:
        _analytics90 ??= DashboardAnalytics(this, days: 90);
        return _analytics90!;
      case 30:
      default:
        _analytics30 ??= DashboardAnalytics(this, days: 30);
        return _analytics30!;
    }
  }
  
  void _invalidateCache() {
    _analytics7 = null;
    _analytics30 = null;
    _analytics90 = null;
    _cachedExpiring = null;
    _cachedOverdue = null;
    _cachedOpenVisits = null;
    _recordIndex.clear();
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
    final expiry = calendar.fromTimestamp(row['expiry_date']);
    return expiry != null && calendar.day(expiry).isBefore(calendar.today)
        ? 'expired'
        : status;
  }

  bool eligible(RecordData member) => memberStatus(member) == 'active';

  Future<void> _loadQueue = Future<void>.value();
  Future<void> load({Set<String>? changedTables, bool refreshSettings = true}) {
    _loadQueue = _loadQueue.then(
      (_) =>
          _load(changedTables: changedTables, refreshSettings: refreshSettings),
    );
    return _loadQueue;
  }

  Future<void> _load({
    Set<String>? changedTables,
    required bool refreshSettings,
  }) async {
    if (_disposed) return;
    loading = _records.isEmpty;
    error = null;
    notifyListeners();
    try {
      if (_records.isEmpty) refreshSettings = true;
      if (refreshSettings) await db.refreshSettings();
      final next = <String, List<RecordData>>{};
      for (final table
          in _records.isEmpty
              ? dataTables
              : changedTables ?? dataTables.toSet()) {
        next[table] = (await db.readRecords(table))
            .map((r) => Map<String, Object?>.from(r))
            .toList();
      }
      if (_disposed) return;
      if (refreshSettings) {
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
          'timezone',
        ]) {
          final value = await db.setting(key);
          if (value != null) _settings[key] = value;
        }
        gymName = await db.setting('gym_name') ?? 'My fitness club';
        currency = await db.setting('currency') ?? 'PKR';
      }
      if (changedTables == null) {
        _records.clear();
        _invalidateCache(); // Full reload - invalidate all caches
      } else {
        // Partial reload - only invalidate affected tables
        for (final table in changedTables) {
          _recordIndex.remove(table);
        }
        _analytics7 = null;
        _analytics30 = null;
        _analytics90 = null;
        _cachedExpiring = null;
        _cachedOverdue = null;
        _cachedOpenVisits = null;
      }
      _records.addAll(next);
      
      // Build index for O(1) lookups
      for (final table in _records.keys) {
        final index = <dynamic, RecordData>{};
        for (final row in _records[table]!) {
          final id = row['id'];
          if (id != null) index[id] = row;
        }
        _recordIndex[table] = index;
        
        // Build member_id index for fast lookups
        final byMember = <int, List<RecordData>>{};
        for (final row in _records[table]!) {
          final mid = row['member_id'] as int?;
          if (mid != null) {
            byMember.putIfAbsent(mid, () => []).add(row);
          }
        }
        if (byMember.isNotEmpty) _byMemberIndex[table] = byMember;
      }
      
      _ledger = FeeLedger(rows('fee_invoices'), rows('payments'));
    } catch (_) {
      error = 'Unable to load workspace. Please retry.';
    }
    loading = false;
    loadCount++; // Notify observers data changed
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
      await load(
        changedTables: {table, if (table == 'payments' && renew) 'members'},
        refreshSettings: false,
      );
      return;
    }
    final values = Map<String, Object?>.from(row);
    final id = values.remove('id');
    values.remove('renewal_applied');
    final database = await db.database;
    await database.transaction((tx) async {
      final original = id == null
          ? null
          : (await tx.query(table, where: 'id=?', whereArgs: [id])).firstOrNull;
      if (id != null && original == null)
        throw StateError('Record no longer exists.');
      if (table == 'fee_invoices' && original != null) {
        final linked = await tx.query(
          'payments',
          where: 'invoice_id=?',
          whereArgs: [id],
        );
        if (original['member_id'] != values['member_id'] && linked.isNotEmpty) {
          throw StateError(
            'An invoice with linked payments cannot change member.',
          );
        }
        if (values['status'] == 'void' && linked.isNotEmpty) {
          throw StateError('An invoice with linked payments cannot be voided.');
        }
      }
      if (table == 'payments') {
        if (original?['renewal_applied'] == 1 &&
            (values['member_id'] != original!['member_id'] ||
                values['plan_id'] != original['plan_id'])) {
          throw StateError(
            'A receipt with applied renewal cannot change member or plan.',
          );
        }
        if (values['invoice_id'] != null) {
          final invoices = await tx.query(
            'fee_invoices',
            where: 'id=?',
            whereArgs: [values['invoice_id']],
          );
          if (invoices.isEmpty ||
              invoices.first['member_id'] != values['member_id'] ||
              invoices.first['status'] == 'void') {
            throw StateError(
              'Choose an active invoice for the selected member.',
            );
          }
        }
      }
      if (table == 'members') {
        values['join_date'] ??= DateTime.now().millisecondsSinceEpoch;
        if (id == null &&
            values['plan_id'] != null &&
            values['expiry_date'] == null) {
          final plan = find('membership_plans', values['plan_id']);
          values['expiry_date'] = calendar
              .addDays(
                calendar.fromTimestamp(values['join_date'])!,
                (plan?['duration_days'] as int?) ?? 30,
              )
              .millisecondsSinceEpoch;
        }
      }
      int savedId;
      if (id == null) {
        savedId = await tx.insert(table, values);
      } else {
        await tx.update(table, values, where: 'id = ?', whereArgs: [id]);
        savedId = id as int;
      }
      if (table == 'payments' && renew && values['status'] == 'completed') {
        if (original?['renewal_applied'] == 1 ||
            original?['status'] == 'completed')
          return;
        final planId = values['plan_id'];
        if (planId == null)
          throw StateError('Choose a membership plan to renew.');
        final plans = await tx.query(
          'membership_plans',
          where: 'id=?',
          whereArgs: [planId],
        );
        if (plans.isEmpty) {
          throw StateError('Choose a membership plan to renew.');
        }
        final plan = plans.first;
        final memberRows = await tx.query(
          'members',
          where: 'id = ?',
          whereArgs: [values['member_id']],
        );
        if (memberRows.isEmpty) throw StateError('Member no longer exists.');
        final oldExpiry = calendar.fromTimestamp(
          memberRows.first['expiry_date'],
        );
        final today = calendar.today;
        final base = oldExpiry != null && oldExpiry.isAfter(today)
            ? oldExpiry
            : today;
        await tx.update(
          'members',
          {
            'plan_id': planId,
            'status': 'active',
            'expiry_date': calendar
                .addDays(base, plan['duration_days'] as int)
                .millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [values['member_id']],
        );
        await tx.update(
          'payments',
          {'renewal_applied': 1},
          where: 'id=?',
          whereArgs: [savedId],
        );
      }
    });
    await load(
      changedTables: {table, if (table == 'payments' && renew) 'members'},
      refreshSettings: false,
    );
  }

  Future<void> delete(String table, int id) async {
    if (isCloud) {
      await db.request('delete', {'table': table, 'id': id});
      await load(changedTables: {table}, refreshSettings: false);
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
    await load(changedTables: {table}, refreshSettings: false);
  }

  Future<void> checkIn(int memberId, {String? notes}) async {
    if (isCloud) {
      await db.request('checkIn', {'memberId': memberId, 'notes': notes});
      await load(changedTables: {'attendance'}, refreshSettings: false);
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
    await load(changedTables: {'attendance'}, refreshSettings: false);
  }

  Future<void> checkOut(int id) async {
    if (isCloud) {
      await db.request('checkOut', {'id': id});
      await load(changedTables: {'attendance'}, refreshSettings: false);
      return;
    }
    await (await db.database).update(
      'attendance',
      {'check_out': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ? AND check_out IS NULL',
      whereArgs: [id],
    );
    await load(changedTables: {'attendance'}, refreshSettings: false);
  }

  Future<void> assignWorkout(int memberId, int workoutId) async {
    if (isCloud) {
      await db.request('assignWorkout', {
        'memberId': memberId,
        'workoutId': workoutId,
      });
      await load(
        changedTables: {'member_workout_assignments'},
        refreshSettings: false,
      );
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
    await load(
      changedTables: {'member_workout_assignments'},
      refreshSettings: false,
    );
  }

  double invoiceBalance(RecordData invoice) =>
      _ledger.balances[invoice['id']] ?? 0;
  double memberDue(int memberId) => _ledger.dues[memberId] ?? 0;
  RecordData? lastPayment(int memberId) => _ledger.last[memberId];
  DateTime? dueSince(int memberId) {
    final date = _ledger.since[memberId];
    return date == null ? null : calendar.instant(date);
  }

  Future<int> generateFees(String period, DateTime dueDate) async {
    if (isCloud) {
      final result = await db.request('generateFees', {
        'period': period,
        'dueDate': calendar.atDate(dueDate).millisecondsSinceEpoch,
      });
      await load(changedTables: {'fee_invoices'}, refreshSettings: false);
      return result['created'] as int;
    }
    var created = 0;
    await (await db.database).transaction((tx) async {
      for (final m in rows('members').where(eligible)) {
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
          'due_date': calendar.atDate(dueDate).millisecondsSinceEpoch,
          'period': period,
          'description': 'Membership fee • $period',
          'status': 'unpaid',
        });
        created++;
      }
    });
    await load(changedTables: {'fee_invoices'}, refreshSettings: false);
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
  
  /// Cached: members expiring within 8 days
  List<RecordData> get expiring {
    _cachedExpiring ??= rows('members').where((m) {
      final expiry = calendar.fromTimestamp(m['expiry_date']);
      return memberStatus(m) == 'active' &&
          expiry != null &&
          !expiry.isBefore(calendar.today) &&
          expiry.isBefore(calendar.addDays(calendar.today, 8));
    }).toList()
      ..sort(
        (a, b) => (a['expiry_date'] as int).compareTo(b['expiry_date'] as int),
      );
    return _cachedExpiring!;
  }
  
  /// Cached: expired members
  List<RecordData> get overdue {
    _cachedOverdue ??= rows('members').where((m) => memberStatus(m) == 'expired').toList();
    return _cachedOverdue!;
  }
  
  /// Cached: members currently checked in
  List<RecordData> get openVisits {
    _cachedOpenVisits ??= rows('attendance').where((r) => r['check_out'] == null).toList();
    return _cachedOpenVisits!;
  }
}
