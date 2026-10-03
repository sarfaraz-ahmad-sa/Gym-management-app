import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitguide/core/gym_store.dart';
import 'package:fitguide/core/format.dart';
import 'package:fitguide/services/db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late DatabaseService service;
  late GymStore store;
  setUp(() async {
    service = DatabaseService(
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
      asDate(
        member['expiry_date'],
      )!.difference(asDate(member['join_date'])!).inDays,
      30,
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
}
