import '../services/db_service.dart';

Future<void> seedDemo(DatabaseService service) async {
  final db = await service.database;
  if (await service.setting('demo_seeded') == 'yes') return;
  final now = DateTime.now();
  await db.transaction((tx) async {
    await tx.insert('settings', {
      'key': 'gym_name',
      'value': 'Elevate Fitness Club',
    });
    await tx.insert('settings', {'key': 'currency', 'value': 'PKR'});
    final plans = <int>[];
    for (final p in [
      {
        'name': 'Essential',
        'price': 4500.0,
        'duration_days': 30,
        'description': 'Your daily dose of movement.',
        'features': 'Gym access,Locker room,Fitness assessment',
      },
      {
        'name': 'Performance',
        'price': 8000.0,
        'duration_days': 30,
        'description': 'Build a stronger version of yourself.',
        'features': 'All Essential benefits,Group classes,Trainer consultation',
      },
      {
        'name': 'Elite annual',
        'price': 75000.0,
        'duration_days': 365,
        'description': 'A year of dedicated progress.',
        'features': 'Unlimited classes,Personal coaching,Nutrition guidance',
      },
    ]) {
      plans.add(await tx.insert('membership_plans', p));
    }
    final trainers = <int>[];
    for (final t in [
      {
        'name': 'Ahmed Hassan',
        'phone': '+923001110001',
        'specialization': 'Strength & conditioning',
        'status': 'active',
      },
      {
        'name': 'Sara Khan',
        'phone': '+923001110002',
        'specialization': 'Functional training',
        'status': 'active',
      },
      {
        'name': 'Omar Ali',
        'phone': '+923001110003',
        'specialization': 'Mobility & recovery',
        'status': 'active',
      },
    ]) {
      trainers.add(
        await tx.insert('trainers', {
          ...t,
          'hire_date': now
              .subtract(const Duration(days: 180))
              .millisecondsSinceEpoch,
        }),
      );
    }
    const names = [
      'Ayesha Malik',
      'Bilal Ahmed',
      'Hassan Raza',
      'Fatima Noor',
      'Zain Sheikh',
      'Mariam Ali',
      'Usman Khan',
      'Sana Iqbal',
      'Danish Akhtar',
      'Hira Shah',
      'Ali Hamza',
      'Noor Zahra',
    ];
    final members = <int>[];
    for (var i = 0; i < names.length; i++) {
      members.add(
        await tx.insert('members', {
          'name': names[i],
          'phone': '+923001234${i.toString().padLeft(3, '0')}',
          'email': '${names[i].split(' ').first.toLowerCase()}@example.com',
          'address': 'Karachi, Pakistan',
          'join_date': now
              .subtract(Duration(days: 120 - i * 7))
              .millisecondsSinceEpoch,
          'expiry_date': now
              .add(
                Duration(
                  days: i == 2 || i == 8
                      ? -3
                      : i < 6
                      ? i + 1
                      : 20 + i,
                ),
              )
              .millisecondsSinceEpoch,
          'plan_id': plans[i % 3],
          'trainer_id': trainers[i % 3],
          'status': i == 11 ? 'inactive' : 'active',
          'goal': 'Improve strength and consistency',
        }),
      );
    }
    for (var month = 5; month >= 0; month--) {
      for (var i = 0; i < members.length; i++) {
        await tx.insert('payments', {
          'member_id': members[i],
          'plan_id': plans[i % 3],
          'amount': i % 3 == 0 ? 4500.0 : 8000.0,
          'payment_date': DateTime(
            now.year,
            now.month - month,
            month == 0 ? (now.day - i % 3).clamp(1, now.day) : 8 + i,
          ).millisecondsSinceEpoch,
          'status': month == 0 && i > 8 ? 'pending' : 'completed',
          'payment_method': i % 2 == 0 ? 'cash' : 'bank_transfer',
          'transaction_id': 'FG-${month + 1}${i.toString().padLeft(3, '0')}',
        });
      }
    }
    for (var day = 6; day >= 0; day--) {
      for (var i = 0; i < (day == 0 ? 4 : 5 + day % 4); i++) {
        final date = DateTime(now.year, now.month, now.day - day, 8 + i);
        await tx.insert('attendance', {
          'member_id': members[i],
          'check_in': date.millisecondsSinceEpoch,
          'check_out': day == 0 && i < 2
              ? null
              : date.add(const Duration(minutes: 75)).millisecondsSinceEpoch,
        });
      }
    }
    for (final item in [
      {
        'name': 'Olympic barbell',
        'category': 'strength',
        'quantity': 6,
        'condition': 'good',
      },
      {
        'name': 'Treadmill',
        'category': 'cardio',
        'quantity': 4,
        'condition': 'maintenance',
        'notes': 'Belt inspection scheduled',
      },
      {
        'name': 'Adjustable bench',
        'category': 'strength',
        'quantity': 8,
        'condition': 'good',
      },
      {
        'name': 'Resistance bands',
        'category': 'accessories',
        'quantity': 15,
        'condition': 'good',
      },
    ]) {
      await tx.insert('inventory_items', item);
    }
    final workout = await tx.insert('workout_plans', {
      'name': 'Strength foundations',
      'level': 'beginner',
      'duration_weeks': 4,
      'description':
          '3 sessions per week.\nWarm-up: 5 minutes.\nSquat 3 × 10, row 3 × 12, push-up 3 × 8.\nFinish with mobility and light stretching.',
    });
    await tx.insert('workout_plans', {
      'name': 'Performance builder',
      'level': 'intermediate',
      'duration_weeks': 8,
      'description':
          '4 sessions per week: upper / lower split.\nProgressive resistance training with coaching review each week.',
    });
    await tx.insert('member_workout_assignments', {
      'member_id': members.first,
      'workout_plan_id': workout,
      'assigned_date': now.millisecondsSinceEpoch,
      'status': 'active',
    });
    await tx.insert('settings', {'key': 'demo_seeded', 'value': 'yes'});
  });
}
