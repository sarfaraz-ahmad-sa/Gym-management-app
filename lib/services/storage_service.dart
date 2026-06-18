import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';
import '../models/goal.dart';

/// Simple key-value persistence wrapper around SharedPreferences.
class StorageService {
  static const _kStartWeight = 'start_weight';
  static const _kGoalWeight = 'goal_weight';
  static const _kHeight = 'height';
  static const _kStartDate = 'start_date';
  static const _kWeights = 'weights';
  static const _kPhotos = 'photos';
  static const _kDoneWorkouts = 'done_workouts'; // set of "yyyy-mm-dd|dayId"
  static const _kHabits = 'habit_done'; // set of "yyyy-mm-dd|habitId"
  static const _kGoals = 'goals';

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ---- Profile ----
  Future<void> saveProfile({
    required double startWeight,
    required double goalWeight,
    required double height,
    required DateTime startDate,
  }) async {
    final p = await _prefs;
    await p.setDouble(_kStartWeight, startWeight);
    await p.setDouble(_kGoalWeight, goalWeight);
    await p.setDouble(_kHeight, height);
    await p.setString(_kStartDate, startDate.toIso8601String());
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    final p = await _prefs;
    if (!p.containsKey(_kStartWeight)) return null;
    return {
      'startWeight': p.getDouble(_kStartWeight),
      'goalWeight': p.getDouble(_kGoalWeight),
      'height': p.getDouble(_kHeight),
      'startDate': DateTime.parse(p.getString(_kStartDate)!),
    };
  }

  // ---- Weights ----
  Future<List<WeightEntry>> loadWeights() async {
    final p = await _prefs;
    final s = p.getString(_kWeights);
    if (s == null || s.isEmpty) return [];
    return decodeWeights(s);
  }

  Future<void> saveWeights(List<WeightEntry> list) async {
    final p = await _prefs;
    await p.setString(_kWeights, encodeWeights(list));
  }

  // ---- Photos ----
  Future<List<ProgressPhoto>> loadPhotos() async {
    final p = await _prefs;
    final s = p.getString(_kPhotos);
    if (s == null || s.isEmpty) return [];
    return decodePhotos(s);
  }

  Future<void> savePhotos(List<ProgressPhoto> list) async {
    final p = await _prefs;
    await p.setString(_kPhotos, encodePhotos(list));
  }

  // ---- Done workouts ----
  Future<Set<String>> loadDone() async {
    final p = await _prefs;
    return (p.getStringList(_kDoneWorkouts) ?? <String>[]).toSet();
  }

  Future<void> saveDone(Set<String> done) async {
    final p = await _prefs;
    await p.setStringList(_kDoneWorkouts, done.toList());
  }

  // ---- Daily habits ----
  Future<Set<String>> loadHabits() async {
    final p = await _prefs;
    return (p.getStringList(_kHabits) ?? <String>[]).toSet();
  }

  Future<void> saveHabits(Set<String> done) async {
    final p = await _prefs;
    await p.setStringList(_kHabits, done.toList());
  }

  // ---- Life goals ----
  Future<List<Goal>> loadGoals() async {
    final p = await _prefs;
    final s = p.getString(_kGoals);
    if (s == null || s.isEmpty) return [];
    return decodeGoals(s);
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final p = await _prefs;
    await p.setString(_kGoals, encodeGoals(goals));
  }
}
