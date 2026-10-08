import 'dart:convert';

import 'cloud_api.dart';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const dataTables = [
  'membership_plans',
  'trainers',
  'members',
  'attendance',
  'fee_invoices',
  'payments',
  'inventory_items',
  'workout_plans',
  'member_workout_assignments',
];

class DatabaseService {
  DatabaseService({
    this.name = 'gym_management.db',
    this.factory,
    this.cloud,
    this.workspaceId,
  });
  static final instance = DatabaseService();
  final String name;
  final DatabaseFactory? factory;
  final CloudApi? cloud;
  final String? workspaceId;
  Map<String, String> cloudSettings = {};
  bool get isCloud => cloud != null;
  Future<Map<String, dynamic>> request(
    String action, [
    Map<String, dynamic> values = const {},
  ]) => cloud!.call(action, {'workspaceId': workspaceId, ...values});
  Future<List<Map<String, Object?>>> readRecords(String table) async {
    if (!dataTables.contains(table)) throw ArgumentError('Unknown record type');
    if (!isCloud) {
      return (await (await database).query(
        table,
        orderBy: 'id DESC',
      )).map((r) => Map<String, Object?>.from(r)).toList();
    }
    final result = <Map<String, Object?>>[];
    int? before;
    do {
      final page = await request('records', {
        'table': table,
        'before': ?before,
      });
      result.addAll(
        (page['rows'] as List).map((r) => Map<String, Object?>.from(r as Map)),
      );
      before = page['next'] as int?;
    } while (before != null);
    return result;
  }

  Future<void> refreshSettings() async {
    if (isCloud) {
      cloudSettings = Map<String, String>.from(
        (await request('workspace'))['settings'] as Map,
      );
    }
  }

  Future<void> setSettings(Map<String, String> values) async {
    if (isCloud) {
      await request('settings', {'values': values});
      cloudSettings.addAll(values);
    } else {
      for (final e in values.entries) {
        await setSetting(e.key, e.value);
      }
    }
  }

  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    if (isCloud) {
      throw StateError('Cloud workspaces use the authenticated API.');
    }
    final engine = factory ?? databaseFactory;
    final path = name == inMemoryDatabasePath
        ? name
        : p.join(await engine.getDatabasesPath(), name);
    try {
      return await engine.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) => _schema(db),
          onUpgrade: (db, _, _) => _schema(db),
        ),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> _schema(Database db) async {
    for (final sql in [
      '''CREATE TABLE IF NOT EXISTS membership_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        description TEXT, price REAL NOT NULL, duration_days INTEGER NOT NULL,
        features TEXT)''',
      '''CREATE TABLE IF NOT EXISTS trainers (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        phone TEXT NOT NULL, email TEXT, specialization TEXT, hire_date INTEGER,
        status TEXT DEFAULT 'active')''',
      '''CREATE TABLE IF NOT EXISTS members (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        phone TEXT NOT NULL, email TEXT, address TEXT, join_date INTEGER,
        plan_id INTEGER REFERENCES membership_plans(id), status TEXT DEFAULT 'active',
        trainer_id INTEGER REFERENCES trainers(id), expiry_date INTEGER, goal TEXT)''',
      '''CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members(id),
        check_in INTEGER NOT NULL, check_out INTEGER, notes TEXT)''',
      '''CREATE TABLE IF NOT EXISTS fee_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members(id),
        amount REAL NOT NULL, due_date INTEGER NOT NULL, period TEXT,
        description TEXT, status TEXT NOT NULL DEFAULT 'unpaid', UNIQUE(member_id, period))''',
      '''CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members(id),
        plan_id INTEGER REFERENCES membership_plans(id), amount REAL NOT NULL,
        payment_date INTEGER NOT NULL, status TEXT NOT NULL,
        payment_method TEXT, transaction_id TEXT, invoice_id INTEGER REFERENCES fee_invoices(id),
        renewal_applied INTEGER NOT NULL DEFAULT 0)''',
      '''CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT NOT NULL,
        quantity INTEGER NOT NULL, condition TEXT, purchase_price REAL,
        purchase_date INTEGER, notes TEXT)''',
      '''CREATE TABLE IF NOT EXISTS workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
        description TEXT, level TEXT, duration_weeks INTEGER)''',
      '''CREATE TABLE IF NOT EXISTS member_workout_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT, member_id INTEGER NOT NULL REFERENCES members(id),
        workout_plan_id INTEGER NOT NULL REFERENCES workout_plans(id),
        assigned_date INTEGER NOT NULL, status TEXT DEFAULT 'active')''',
      '''CREATE TABLE IF NOT EXISTS owner_account (
        id INTEGER PRIMARY KEY CHECK (id = 1), name TEXT NOT NULL,
        username TEXT NOT NULL, password_hash TEXT NOT NULL, salt TEXT NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)''',
      '''CREATE TABLE IF NOT EXISTS sessions (
        token_hash TEXT PRIMARY KEY, expires_at INTEGER NOT NULL)''',
      'CREATE INDEX IF NOT EXISTS idx_attendance_member ON attendance(member_id, check_in)',
      'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date, status)',
    ]) {
      await db.execute(sql);
    }
    final paymentColumns = await db.rawQuery('PRAGMA table_info(payments)');
    if (!paymentColumns.any((c) => c['name'] == 'invoice_id')) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN invoice_id INTEGER REFERENCES fee_invoices(id)',
      );
    }
    if (!paymentColumns.any((c) => c['name'] == 'renewal_applied')) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN renewal_applied INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE payments SET renewal_applied=1 WHERE status='completed'",
      );
    }
    // Preserve existing records; only add the missing columns.
    final columns = await db.rawQuery('PRAGMA table_info(members)');
    for (final entry in {
      'trainer_id': 'INTEGER REFERENCES trainers(id)',
      'expiry_date': 'INTEGER',
      'goal': 'TEXT',
    }.entries) {
      if (!columns.any((c) => c['name'] == entry.key)) {
        await db.execute(
          'ALTER TABLE members ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
    await db.rawUpdate(
      '''UPDATE members SET expiry_date = join_date +
      (SELECT duration_days FROM membership_plans WHERE id = members.plan_id) * 86400000
      WHERE expiry_date IS NULL AND join_date IS NOT NULL AND plan_id IS NOT NULL''',
    );
  }

  Future<String?> setting(String key) async {
    if (isCloud) return cloudSettings[key];
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    if (isCloud) {
      await setSettings({key: value});
      return;
    }
    await (await database).insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> exportData() async {
    if (isCloud) {
      await refreshSettings();
      final tables = <String, dynamic>{};
      for (final table in dataTables) {
        tables[table] = await readRecords(table);
      }
      tables['settings'] = cloudSettings.entries
          .map((e) => {'key': e.key, 'value': e.value})
          .toList();
      return const JsonEncoder.withIndent('  ').convert({
        'format': 'fitguide-backup',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'tables': tables,
      });
    }
    final db = await database;
    final tables = <String, dynamic>{};
    await db.transaction((tx) async {
      for (final table in dataTables) {
        tables[table] = await tx.query(table);
      }
      tables['settings'] = await tx.query('settings');
    });
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'fitguide-backup',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tables,
    });
  }

  Future<void> importData(String json) async {
    final data = jsonDecode(json);
    if (data is! Map ||
        data['format'] != 'fitguide-backup' ||
        data['version'] != 1 ||
        data['tables'] is! Map) {
      throw const FormatException('Choose a valid FitGuide backup.');
    }
    if (isCloud) {
      if (utf8.encode(json).length > 3 * 1024 * 1024) {
        throw const FormatException(
          'Cloud restore supports backups up to 3 MB. Larger backups require the server migration script.',
        );
      }
      await request('restore', {'backup': data});
      await refreshSettings();
      return;
    }
    final tables = data['tables'] as Map;
    final db = await database;
    // All validation/inserts share a transaction, so a malformed backup rolls back.
    await db.transaction((tx) async {
      for (final table in dataTables.reversed) {
        await tx.delete(table);
      }
      for (final table in [...dataTables, 'settings']) {
        if (table == 'fee_invoices' && tables[table] == null) {
          tables[table] = [];
        }
        if (tables[table] is! List) {
          throw const FormatException('Backup is incomplete.');
        }
        if (table == 'settings') await tx.delete(table);
        for (final row in tables[table] as List) {
          if (row is! Map) {
            throw const FormatException('Invalid backup record.');
          }
          final values = Map<String, Object?>.from(row);
          if (table == 'payments') {
            values['renewal_applied'] ??= values['status'] == 'completed'
                ? 1
                : 0;
            if (values['renewal_applied'] != 0 &&
                values['renewal_applied'] != 1) {
              throw const FormatException('Invalid renewal history.');
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
                throw const FormatException(
                  'Backup receipt has an invalid member or invoice.',
                );
              }
            }
          }
          await tx.insert(table, values);
        }
      }
    });
  }

  Future<void> close() async {
    if (_opening != null) await (await _opening!).close();
    _opening = null;
  }
}
