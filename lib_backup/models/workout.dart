/// Models describing the workout plan.

class Exercise {
  final String name;
  final String emoji;
  final String sets; // e.g. "3"
  final String reps; // e.g. "12" or "30 sec"
  final String tip; // short form/technique tip

  const Exercise({
    required this.name,
    required this.emoji,
    required this.sets,
    required this.reps,
    this.tip = '',
  });
}

class WorkoutDay {
  final String id; // unique, e.g. "m1d1"
  final String title; // e.g. "Full Body A"
  final String focus; // e.g. "Legs + Chest + Core"
  final String warmup;
  final List<Exercise> exercises;
  final String cardio;
  final String cooldown;

  const WorkoutDay({
    required this.id,
    required this.title,
    required this.focus,
    required this.warmup,
    required this.exercises,
    required this.cardio,
    required this.cooldown,
  });
}

class MonthPlan {
  final int month; // 1, 2, 3
  final String name; // e.g. "Foundation"
  final String goal; // short description
  final List<String> highlights;
  final List<WorkoutDay> days;

  const MonthPlan({
    required this.month,
    required this.name,
    required this.goal,
    required this.highlights,
    required this.days,
  });
}
