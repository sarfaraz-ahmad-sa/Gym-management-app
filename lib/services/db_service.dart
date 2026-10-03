import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member.dart';
import '../models/membership_plan.dart';
import '../models/attendance.dart';
import '../models/trainer.dart';
import '../models/payment.dart';
import '../models/inventory_item.dart';
import '../models/workout_plan.dart';

class DatabaseService {
  static const _dbName = 'gym_management.db';
  static const _dbVersion = 2;

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        join_date INTEGER,
        plan_id INTEGER,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (plan_id) REFERENCES membership_plans(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE membership_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        duration_days INTEGER NOT NULL,
        features TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        check_in INTEGER NOT NULL,
        check_out INTEGER,
        notes TEXT,
        FOREIGN KEY (member_id) REFERENCES members(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE trainers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        specialization TEXT,
        hire_date INTEGER,
        status TEXT DEFAULT 'active'
      )
    ''');
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        plan_id INTEGER,
        amount REAL NOT NULL,
        payment_date INTEGER NOT NULL,
        status TEXT NOT NULL,
        payment_method TEXT,
        transaction_id TEXT,
        FOREIGN KEY (member_id) REFERENCES members(id),
        FOREIGN KEY (plan_id) REFERENCES membership_plans(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE inventory_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        condition TEXT,
        purchase_price REAL,
        purchase_date INTEGER,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_plans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        level TEXT,
        duration_weeks INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE member_workout_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        workout_plan_id INTEGER NOT NULL,
        assigned_date INTEGER NOT NULL,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (member_id) REFERENCES members(id),
        FOREIGN KEY (workout_plan_id) REFERENCES workout_plans(id)
      )
    ''');
  }

  // Member CRUD
  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert('members', member.toMap());
  }

  Future<List<Member>> getAllMembers() async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'name');
    return maps.map((map) => Member.fromMap(map)).toList();
  }

  Future<Member?> getMember(int id) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Member.fromMap(maps.first);
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MembershipPlan CRUD
  Future<int> insertMembershipPlan(MembershipPlan plan) async {
    final db = await database;
    return await db.insert('membership_plans', plan.toMap());
  }

  Future<List<MembershipPlan>> getAllMembershipPlans() async {
    final db = await database;
    final maps = await db.query('membership_plans', orderBy: 'name');
    return maps.map((map) => MembershipPlan.fromMap(map)).toList();
  }

  Future<MembershipPlan?> getMembershipPlan(int id) async {
    final db = await database;
    final maps = await db.query(
      'membership_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MembershipPlan.fromMap(maps.first);
  }

  Future<int> updateMembershipPlan(MembershipPlan plan) async {
    final db = await database;
    return await db.update(
      'membership_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deleteMembershipPlan(int id) async {
    final db = await database;
    return await db.delete(
      'membership_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Attendance CRUD
  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAllAttendance() async {
    final db = await database;
    final maps = await db.query('attendance', orderBy: 'check_in DESC');
    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  Future<List<Attendance>> getAttendanceByMember(int memberId) async {
    final db = await database;
    final maps = await db.query(
      'attendance',
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'check_in DESC',
    );
    return maps.map((map) => Attendance.fromMap(map)).toList();
  }

  Future<Attendance?> getAttendance(int id) async {
    final db = await database;
    final maps = await db.query(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Attendance.fromMap(maps.first);
  }

  Future<int> updateAttendance(Attendance attendance) async {
    final db = await database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Trainer CRUD
  Future<int> insertTrainer(Trainer trainer) async {
    final db = await database;
    return await db.insert('trainers', trainer.toMap());
  }

  Future<List<Trainer>> getAllTrainers() async {
    final db = await database;
    final maps = await db.query('trainers', orderBy: 'name');
    return maps.map((map) => Trainer.fromMap(map)).toList();
  }

  Future<Trainer?> getTrainer(int id) async {
    final db = await database;
    final maps = await db.query(
      'trainers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Trainer.fromMap(maps.first);
  }

  Future<int> updateTrainer(Trainer trainer) async {
    final db = await database;
    return await db.update(
      'trainers',
      trainer.toMap(),
      where: 'id = ?',
      whereArgs: [trainer.id],
    );
  }

  Future<int> deleteTrainer(int id) async {
    final db = await database;
    return await db.delete(
      'trainers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Payment CRUD
  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'payment_date DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByMember(int memberId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<Payment?> getPayment(int id) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromMap(maps.first);
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Inventory CRUD
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert('inventory_items', item.toMap());
  }

  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await database;
    final maps = await db.query('inventory_items', orderBy: 'name');
    return maps.map((map) => InventoryItem.fromMap(map)).toList();
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return InventoryItem.fromMap(maps.first);
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return await db.delete(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // WorkoutPlan CRUD
  Future<int> insertWorkoutPlan(WorkoutPlan plan) async {
    final db = await database;
    return await db.insert('workout_plans', plan.toMap());
  }

  Future<List<WorkoutPlan>> getAllWorkoutPlans() async {
    final db = await database;
    final maps = await db.query('workout_plans', orderBy: 'name');
    return maps.map((map) => WorkoutPlan.fromMap(map)).toList();
  }

  Future<WorkoutPlan?> getWorkoutPlan(int id) async {
    final db = await database;
    final maps = await db.query(
      'workout_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutPlan.fromMap(maps.first);
  }

  Future<int> updateWorkoutPlan(WorkoutPlan plan) async {
    final db = await database;
    return await db.update(
      'workout_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deleteWorkoutPlan(int id) async {
    final db = await database;
    return await db.delete(
      'workout_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MemberWorkoutAssignment CRUD
  Future<int> assignWorkoutToMember(int memberId, int workoutPlanId) async {
    final db = await database;
    return await db.insert('member_workout_assignments', {
      'member_id': memberId,
      'workout_plan_id': workoutPlanId,
      'assigned_date': DateTime.now().millisecondsSinceEpoch,
      'status': 'active',
    });
  }

  Future<List<Map<String, dynamic>>> getMemberAssignments(int memberId) async {
    final db = await database;
    return await db.query(
      'member_workout_assignments',
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'assigned_date DESC',
    );
  }

  Future<int> updateAssignmentStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'member_workout_assignments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAssignment(int id) async {
    final db = await database;
    return await db.delete(
      'member_workout_assignments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}