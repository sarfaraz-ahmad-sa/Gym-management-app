class WorkoutPlan {
  int? id;
  String name;
  String description;
  String? level; // beginner, intermediate, advanced
  int? durationWeeks; // optional duration in weeks

  WorkoutPlan({
    this.id,
    required this.name,
    required this.description,
    this.level,
    this.durationWeeks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'duration_weeks': durationWeeks,
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      level: map['level'],
      durationWeeks: map['duration_weeks'],
    );
  }
}