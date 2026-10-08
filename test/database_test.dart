import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitguide/core/gym_store.dart';
import 'package:fitguide/core/format.dart';
import 'package:fitguide/services/db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late TrackingDatabaseService service;
  late GymStore store;
  setUp(() async {
    service = TrackingDatabaseService(
      name: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    store = GymStore(service);
    await store.load();
    await store.save('membership_plans', {
      'name': 'Monthly',
      'description': 'Gym access',
      'price': 5000.0,
      'duration_days': 30,
    });
    await store.save('members', {
      'name': 'Anis',
      'phone': '+923001234567',
      'plan_id': store.rows('membership_plans').first['id'],
      'join_date': dateOnly(DateTime.now()).millisecondsSinceEpoch,
      'status': 'active',
    });
  });
  tearDown(() async {
    store.dispose();
    await service.close();
  });

  test('member persists and receives plan-based expiry', () async {
    final member = store.rows('members').first;
    expect(
      member['expiry_date'],
      store.calendar
          .addDays(store.calendar.fromTimestamp(member['join_date'])!, 30)
          .millisecondsSinceEpoch,
    );
    await store.load();
    expect(store.rows('members').first['name'], 'Anis');
  });
  test(
    'only one open attendance session; checkout allows next visit',
    () async {
      final memberId = store.rows('members').first['id'] as int;
      await store.checkIn(memberId);
      await expectLater(store.checkIn(memberId), throwsStateError);
      expect(store.openVisits.length, 1);
      await store.checkOut(store.openVisits.first['id'] as int);
      expect(store.openVisits, isEmpty);
      await store.checkIn(memberId);
      expect(store.rows('attendance').length, 2);
    },
  );
  test('expired and suspended members cannot check in', () async {
    var member = store.rows('members').first;
    await store.save('members', {
      ...member,
      'expiry_date': DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch,
    });
    expect(store.memberStatus(store.rows('members').first), 'expired');
    await expectLater(store.checkIn(member['id'] as int), throwsStateError);
    member = store.rows('members').first;
    await store.save('members', {...member, 'status': 'suspended'});
    await expectLater(store.checkIn(member['id'] as int), throwsStateError);
  });
  test(
    'completed payment renews once; editing receipt does not renew twice',
    () async {
      final member = store.rows('members').first;
      final old = member['expiry_date'] as int;
      await store.save('payments', {
        'member_id': member['id'],
        'plan_id': member['plan_id'],
        'amount': 5000.0,
        'status': 'completed',
        'payment_date': DateTime.now().millisecondsSinceEpoch,
      }, renew: true);
      final renewed = store.rows('members').first['expiry_date'] as int;
      expect(renewed - old, const Duration(days: 30).inMilliseconds);
      await store.save('payments', {
        ...store.rows('payments').first,
        'transaction_id': 'TEST-01',
      }, renew: true);
      expect(store.rows('members').first['expiry_date'], renewed);
      expect(
        store.revenue(
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 1)),
        ),
        5000,
      );
    },
  );
  test('pending payment cannot renew; completion can renew', () async {
    final member = store.rows('members').first;
    final old = member['expiry_date'];
    await store.save('payments', {
      'member_id': member['id'],
      'plan_id': member['plan_id'],
      'amount': 5000.0,
      'status': 'pending',
      'payment_date': DateTime.now().millisecondsSinceEpoch,
    }, renew: true);
    expect(store.rows('members').first['expiry_date'], old);
    await store.save('payments', {
      ...store.rows('payments').first,
      'status': 'completed',
    }, renew: true);
    expect(
      store.rows('members').first['expiry_date'],
      (old as int) + const Duration(days: 30).inMilliseconds,
    );
  });
  test('renewal without a valid plan rolls back receipt', () async {
    await expectLater(
      store.save('payments', {
        'member_id': store.rows('members').first['id'],
        'amount': 5000.0,
        'status': 'completed',
        'payment_date': DateTime.now().millisecondsSinceEpoch,
      }, renew: true),
      throwsStateError,
    );
    await store.load();
    expect(store.rows('payments'), isEmpty);
  });
  test('linked payment history prevents destructive member deletion', () async {
    final member = store.rows('members').first;
    await store.save('payments', {
      'member_id': member['id'],
      'amount': 5000.0,
      'status': 'completed',
      'payment_date': DateTime.now().millisecondsSinceEpoch,
    });
    await expectLater(
      store.delete('members', member['id'] as int),
      throwsStateError,
    );
    expect(store.rows('members').length, 1);
  });
  test(
    'workout assignment replaces active program while preserving history',
    () async {
      await store.save('workout_plans', {
        'name': 'Foundation',
        'description': 'Three sessions',
        'duration_weeks': 4,
      });
      final memberId = store.rows('members').first['id'] as int;
      final workoutId = store.rows('workout_plans').first['id'] as int;
      await store.assignWorkout(memberId, workoutId);
      await store.assignWorkout(memberId, workoutId);
      final rows = store.rows('member_workout_assignments');
      expect(rows.length, 2);
      expect(rows.where((r) => r['status'] == 'active').length, 1);
    },
  );
  test('backup round trip and malformed import rollback', () async {
    await service.setSetting('gym_name', 'Test Club');
    final backup = await service.exportData();
    await store.save('members', {
      'name': 'Second member',
      'phone': '03009998888',
      'status': 'active',
    });
    await service.importData(backup);
    await store.load();
    expect(store.rows('members').length, 1);
    expect(store.gymName, 'Test Club');
    final invalid = jsonDecode(backup) as Map<String, dynamic>;
    (invalid['tables']['members'] as List).first['plan_id'] = 999999;
    await expectLater(
      service.importData(jsonEncode(invalid)),
      throwsA(isA<DatabaseException>()),
    );
    await store.load();
    expect(store.rows('members').first['name'], 'Anis');
    expect(
      (jsonDecode(backup)['tables'] as Map).containsKey('owner_account'),
      isFalse,
    );
  });
  test(
    'receipt status cycles and backup restore cannot apply a renewal twice',
    () async {
      final member = store.rows('members').first;
      await store.save('payments', {
        'member_id': member['id'],
        'plan_id': member['plan_id'],
        'amount': 5000.0,
        'status': 'completed',
        'payment_date': DateTime.now().millisecondsSinceEpoch,
      }, renew: true);
      final expiry = store.rows('members').first['expiry_date'];
      var receipt = store.rows('payments').first;
      expect(receipt['renewal_applied'], 1);
      await store.save('payments', {
        ...receipt,
        'status': 'pending',
        'renewal_applied': 0,
      });
      await store.save('payments', {
        ...receipt,
        'status': 'completed',
        'renewal_applied': 0,
      }, renew: true);
      expect(store.rows('members').first['expiry_date'], expiry);
      await service.importData(await service.exportData());
      await store.load();
      receipt = store.rows('payments').first;
      await store.save('payments', {...receipt, 'status': 'pending'});
      await store.save('payments', {
        ...receipt,
        'status': 'completed',
      }, renew: true);
      expect(store.rows('members').first['expiry_date'], expiry);
      await expectLater(
        store.save('payments', {...receipt, 'plan_id': null}),
        throwsStateError,
      );
    },
  );

  test(
    'an invoice with any linked receipt cannot be moved to another member',
    () async {
      final member = store.rows('members').first;
      await store.save('members', {
        'name': 'Second',
        'phone': '03009998888',
        'status': 'active',
      });
      final second = store
          .rows('members')
          .firstWhere((m) => m['id'] != member['id']);
      await store.generateFees('2026-10', store.calendar.today);
      final invoice = store.rows('fee_invoices').first;
      await store.save('payments', {
        'member_id': member['id'],
        'invoice_id': invoice['id'],
        'amount': 1000.0,
        'status': 'pending',
        'payment_date': DateTime.now().millisecondsSinceEpoch,
      });
      await expectLater(
        store.save('fee_invoices', {...invoice, 'member_id': second['id']}),
        throwsStateError,
      );
      await store.save('payments', {
        ...store.rows('payments').first,
        'status': 'completed',
      });
      await expectLater(
        store.save('fee_invoices', {...invoice, 'member_id': second['id']}),
        throwsStateError,
      );
      await expectLater(
        store.save('fee_invoices', {...invoice, 'status': 'void'}),
        throwsStateError,
      );
      await service.importData(await service.exportData());
      await store.load();
      expect(store.rows('fee_invoices').first['member_id'], member['id']);
      expect(store.memberDue(member['id'] as int), 4000);
    },
  );

  test(
    'membership remains valid for its whole workspace expiry date',
    () async {
      final member = store.rows('members').first;
      await store.save('members', {
        ...member,
        'join_date': store.calendar
            .addDays(store.calendar.today, -30)
            .millisecondsSinceEpoch,
        'expiry_date': store.calendar.today.millisecondsSinceEpoch,
      });
      expect(store.memberStatus(store.rows('members').first), 'active');
      await store.checkIn(member['id'] as int);
      expect(store.openVisits.length, 1);
    },
  );

  test('saves and check-ins refresh only affected tables', () async {
    service.reads.clear();
    await store.save('trainers', {
      'name': 'Coach',
      'phone': '03001112222',
      'status': 'active',
    });
    expect(service.reads, ['trainers']);
    service.reads.clear();
    await store.checkIn(store.rows('members').first['id'] as int);
    expect(service.reads, ['attendance']);
    service.reads.clear();
    final member = store.rows('members').first;
    await store.save('payments', {
      'member_id': member['id'],
      'plan_id': member['plan_id'],
      'amount': 5000.0,
      'payment_date': DateTime.now().millisecondsSinceEpoch,
      'status': 'completed',
    }, renew: true);
    expect(service.reads.toSet(), {'payments', 'members'});
    expect(store.rows('trainers').first['name'], 'Coach');
    expect(store.openVisits.length, 1);
  });
  test(
    'version 4 database upgrades without losing completed receipt history',
    () async {
      final folder = await Directory.systemTemp.createTemp('fitguide-upgrade-');
      final path = '${folder.path}/legacy.db';
      final legacy = DatabaseService(name: path, factory: databaseFactoryFfi);
      final old = GymStore(legacy);
      await old.load();
      await old.save('members', {
        'name': 'Legacy',
        'phone': '03009999999',
        'status': 'active',
      });
      await old.save('payments', {
        'member_id': old.rows('members').first['id'],
        'amount': 5000.0,
        'status': 'completed',
        'payment_date': DateTime.now().millisecondsSinceEpoch,
      });
      final connection = await legacy.database;
      await connection.execute(
        'ALTER TABLE payments DROP COLUMN renewal_applied',
      );
      await connection.execute('PRAGMA user_version=4');
      old.dispose();
      await legacy.close();
      final upgraded = DatabaseService(name: path, factory: databaseFactoryFfi);
      try {
        final connection = await upgraded.database;
        expect(
          (await connection.query('payments')).single['renewal_applied'],
          1,
        );
        expect((await connection.query('members')).single['name'], 'Legacy');
        expect(
          (await connection.rawQuery('PRAGMA user_version'))
              .single['user_version'],
          5,
        );
        await upgraded.close();
        final reopened = await upgraded.database;
        expect((await reopened.query('payments')).single['renewal_applied'], 1);
      } finally {
        await upgraded.close();
        await folder.delete(recursive: true);
      }
    },
  );
}

class TrackingDatabaseService extends DatabaseService {
  TrackingDatabaseService({required super.name, super.factory});
  final reads = <String>[];
  @override
  Future<List<Map<String, Object?>>> readRecords(String table) async {
    reads.add(table);
    return super.readRecords(table);
  }
}
