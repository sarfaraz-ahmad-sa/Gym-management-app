import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/progress.dart';
import '../models/goal.dart';
import '../services/storage_service.dart';

/// Central app state. Holds profile, weights, photos, completed workouts.
class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();

  bool loaded = false;

  // Profile
  double startWeight = 72;
  double goalWeight = 68;
  double height = 172.72; // 5'8" in cm
  DateTime startDate = DateTime.now();
  bool hasProfile = false;

  // Data
  List<WeightEntry> weights = [];
  List<ProgressPhoto> photos = [];
  Set<String> doneWorkouts = {}; // "yyyy-MM-dd|dayId"
  Set<String> habitDone = {}; // "yyyy-MM-dd|habitId"
  List<Goal> goals = [];

  Future<void> init() async {
    final profile = await _storage.loadProfile();
    if (profile != null) {
      startWeight = profile['startWeight'] as double;
      goalWeight = profile['goalWeight'] as double;
      height = profile['height'] as double;
      startDate = profile['startDate'] as DateTime;
      hasProfile = true;
    }
    weights = await _storage.loadWeights();
    photos = await _storage.loadPhotos();
    doneWorkouts = await _storage.loadDone();
    habitDone = await _storage.loadHabits();
    goals = await _storage.loadGoals();
    loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    required double startWeight,
    required double goalWeight,
    required double height,
    DateTime? startDate,
  }) async {
    this.startWeight = startWeight;
    this.goalWeight = goalWeight;
    this.height = height;
    this.startDate = startDate ?? this.startDate;
    hasProfile = true;
    await _storage.saveProfile(
      startWeight: startWeight,
      goalWeight: goalWeight,
      height: height,
      startDate: this.startDate,
    );
    // Seed first weight entry if empty.
    if (weights.isEmpty) {
      weights.add(WeightEntry(date: this.startDate, weight: startWeight));
      await _storage.saveWeights(weights);
    }
    notifyListeners();
  }

  // ---- Derived values ----
  double get currentWeight =>
      weights.isNotEmpty ? weights.last.weight : startWeight;

  /// Total kg to lose.
  double get totalToLose => (startWeight - goalWeight).abs();

  /// Progress fraction toward goal (0..1).
  double get progressFraction {
    if (totalToLose == 0) return 1;
    final lost = startWeight - currentWeight;
    final f = lost / totalToLose;
    return f.clamp(0.0, 1.0);
  }

  int get dayNumber => DateTime.now().difference(startDate).inDays + 1;

  /// Program month (1, 2 or 3) based on days elapsed.
  int get currentMonth {
    final m = (dayNumber / 30).ceil();
    return m.clamp(1, 3);
  }

  double get bmi {
    final hM = height / 100;
    return currentWeight / (hM * hM);
  }

  // ---- Mutations ----
  Future<void> addWeight(double w, {DateTime? date}) async {
    weights.add(WeightEntry(date: date ?? DateTime.now(), weight: w));
    weights.sort((a, b) => a.date.compareTo(b.date));
    await _storage.saveWeights(weights);
    notifyListeners();
  }

  Future<void> removeWeight(int index) async {
    weights.removeAt(index);
    await _storage.saveWeights(weights);
    notifyListeners();
  }

  Future<void> addPhoto(String path) async {
    photos.add(ProgressPhoto(
      path: path,
      date: DateTime.now(),
      weightAtTime: weights.isNotEmpty ? weights.last.weight : null,
    ));
    photos.sort((a, b) => b.date.compareTo(a.date));
    await _storage.savePhotos(photos);
    notifyListeners();
  }

  Future<void> removePhoto(int index) async {
    photos.removeAt(index);
    await _storage.savePhotos(photos);
    notifyListeners();
  }

  String _todayKey(String dayId) =>
      '${DateFormat('yyyy-MM-dd').format(DateTime.now())}|$dayId';

  bool isDoneToday(String dayId) => doneWorkouts.contains(_todayKey(dayId));

  Future<void> toggleDone(String dayId) async {
    final key = _todayKey(dayId);
    if (doneWorkouts.contains(key)) {
      doneWorkouts.remove(key);
    } else {
      doneWorkouts.add(key);
    }
    await _storage.saveDone(doneWorkouts);
    notifyListeners();
  }

  int get totalWorkoutsDone => doneWorkouts.length;

  // ---------- Daily habits ----------
  String _dayKey([DateTime? d]) =>
      DateFormat('yyyy-MM-dd').format(d ?? DateTime.now());

  bool isHabitDoneToday(String habitId) =>
      habitDone.contains('${_dayKey()}|$habitId');

  Future<void> toggleHabit(String habitId) async {
    final key = '${_dayKey()}|$habitId';
    if (habitDone.contains(key)) {
      habitDone.remove(key);
    } else {
      habitDone.add(key);
    }
    await _storage.saveHabits(habitDone);
    notifyListeners();
  }

  int habitsCompletedOn(DateTime d, int totalHabits) {
    final prefix = '${_dayKey(d)}|';
    return habitDone.where((k) => k.startsWith(prefix)).length;
  }

  /// Consecutive days (ending today/yesterday) where ALL habits were done.
  int habitStreak(int totalHabits) {
    if (totalHabits == 0) return 0;
    var streak = 0;
    var day = DateTime.now();
    // Allow today to be incomplete without breaking an existing streak.
    if (habitsCompletedOn(day, totalHabits) < totalHabits) {
      day = day.subtract(const Duration(days: 1));
    }
    while (habitsCompletedOn(day, totalHabits) >= totalHabits) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---------- Weekly performance ----------
  DateTime get _startOfWeek {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1)); // Monday
  }

  int get workoutsThisWeek {
    final start = _startOfWeek;
    var count = 0;
    for (final k in doneWorkouts) {
      final datePart = k.split('|').first;
      final date = DateTime.tryParse(datePart);
      if (date != null && !date.isBefore(start)) count++;
    }
    return count;
  }

  int get weeklyTarget {
    switch (currentMonth) {
      case 1:
        return 3;
      case 2:
        return 4;
      default:
        return 5;
    }
  }

  double get weeklyConsistency =>
      (workoutsThisWeek / weeklyTarget).clamp(0.0, 1.0);

  /// + means gained, - means lost (good for fat loss).
  double? get weightTrend {
    if (weights.length < 2) return null;
    return weights.last.weight - weights[weights.length - 2].weight;
  }

  // ---------- Achievements ----------
  List<Achievement> get achievements {
    final lost = startWeight - currentWeight;
    final hs = habitStreak(5);
    return [
      Achievement('🏁', 'Pehla workout', totalWorkoutsDone >= 1),
      Achievement('🔟', '10 workouts', totalWorkoutsDone >= 10),
      Achievement('💪', '25 workouts', totalWorkoutsDone >= 25),
      Achievement('⚖️', 'Pehla 1 kg kam', lost >= 1),
      Achievement('🎯', 'Goal ka aadha', progressFraction >= 0.5),
      Achievement('🏆', 'Goal complete', progressFraction >= 1.0),
      Achievement('🔥', '7-din habit streak', hs >= 7),
      Achievement('📸', 'Progress photo', photos.isNotEmpty),
    ];
  }

  // ---------- Life goals ----------
  Future<void> addGoal(String title, {DateTime? targetDate}) async {
    goals.add(Goal(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetDate: targetDate,
    ));
    await _storage.saveGoals(goals);
    notifyListeners();
  }

  Future<void> toggleGoal(String id) async {
    final g = goals.firstWhere((e) => e.id == id);
    g.done = !g.done;
    await _storage.saveGoals(goals);
    notifyListeners();
  }

  Future<void> removeGoal(String id) async {
    goals.removeWhere((e) => e.id == id);
    await _storage.saveGoals(goals);
    notifyListeners();
  }
}

class Achievement {
  final String emoji;
  final String label;
  final bool unlocked;
  const Achievement(this.emoji, this.label, this.unlocked);
}
