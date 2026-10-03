import 'dart:convert';

/// A user-defined life/fitness goal.
class Goal {
  final String id;
  String title;
  DateTime? targetDate;
  bool done;

  Goal({
    required this.id,
    required this.title,
    this.targetDate,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate?.toIso8601String(),
        'done': done,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        title: j['title'] as String,
        targetDate: j['targetDate'] != null
            ? DateTime.parse(j['targetDate'] as String)
            : null,
        done: j['done'] as bool? ?? false,
      );
}

String encodeGoals(List<Goal> g) =>
    jsonEncode(g.map((e) => e.toJson()).toList());

List<Goal> decodeGoals(String s) {
  final raw = jsonDecode(s) as List<dynamic>;
  return raw.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
}

/// Daily habit definition.
class Habit {
  final String id;
  final String emoji;
  final String name;
  const Habit({required this.id, required this.emoji, required this.name});
}

class HabitsData {
  static const List<Habit> daily = [
    Habit(id: 'water', emoji: '💧', name: '3-4 litre paani'),
    Habit(id: 'sleep', emoji: '😴', name: '7-8 ghante neend'),
    Habit(id: 'protein', emoji: '🍳', name: 'Protein target hit'),
    Habit(id: 'steps', emoji: '🚶', name: '8-10k steps / walk'),
    Habit(id: 'nojunk', emoji: '🚫', name: 'No junk / sugar'),
  ];
}
