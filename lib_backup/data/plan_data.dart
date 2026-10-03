import '../models/workout.dart';

/// The full 3-month plan: 72 kg -> 68 kg + visible abs.
/// Goal logic:
///   Month 1 (Foundation): learn form, build habit, full body 3x/week + core.
///   Month 2 (Build & Burn): upper/lower split 4x/week + cardio + core circuits.
///   Month 3 (Cut & Carve): 5 days, more intensity + HIIT + heavy ab focus.
class PlanData {
  static const List<MonthPlan> months = [
    // ---------------- MONTH 1 ----------------
    MonthPlan(
      month: 1,
      name: 'Foundation',
      goal: 'Form sikho, body adjust karo, habit banao. 3 din/week full body.',
      highlights: [
        'Halka weight rakho, technique perfect karo',
        '3 din workout (1 din gap): Mon / Wed / Fri',
        'Roz 20 min tezi se walk / cardio',
        'Calorie deficit shuru (300 kcal kam)',
      ],
      days: [
        WorkoutDay(
          id: 'm1d1',
          title: 'Full Body A',
          focus: 'Legs + Chest + Core',
          warmup: '5-10 min treadmill walk + joint rotations + light stretch',
          exercises: [
            Exercise(name: 'Bodyweight / Goblet Squat', emoji: '🦵', sets: '3', reps: '12', tip: 'Ghutne toes ke direction mein, peeth seedhi.'),
            Exercise(name: 'Machine Chest Press', emoji: '💪', sets: '3', reps: '12', tip: 'Kohni 45 degree, control se push.'),
            Exercise(name: 'Lat Pulldown', emoji: '🔙', sets: '3', reps: '12', tip: 'Bar chest tak, peeth se kheecho.'),
            Exercise(name: 'Dumbbell Shoulder Press', emoji: '🏋️', sets: '3', reps: '12', tip: 'Halka weight, full range.'),
            Exercise(name: 'Plank', emoji: '🧘', sets: '3', reps: '25 sec', tip: 'Body ek seedhi line mein.'),
          ],
          cardio: '15-20 min brisk walk (incline 3-5)',
          cooldown: '5 min full body stretch',
        ),
        WorkoutDay(
          id: 'm1d2',
          title: 'Full Body B',
          focus: 'Back + Shoulders + Core',
          warmup: '5-10 min cycling + arm circles + light stretch',
          exercises: [
            Exercise(name: 'Leg Press', emoji: '🦵', sets: '3', reps: '12', tip: 'Pair shoulder-width, neeche tak control.'),
            Exercise(name: 'Seated Cable Row', emoji: '🔙', sets: '3', reps: '12', tip: 'Kandhe peeche, chest aage.'),
            Exercise(name: 'Incline Dumbbell Press', emoji: '💪', sets: '3', reps: '12', tip: 'Upper chest target.'),
            Exercise(name: 'Lateral Raise', emoji: '🏋️', sets: '3', reps: '15', tip: 'Bahut halka weight, kohni thodi mudi.'),
            Exercise(name: 'Hanging / Lying Leg Raise', emoji: '🔥', sets: '3', reps: '12', tip: 'Lower abs pe focus.'),
          ],
          cardio: '15-20 min cycle (medium pace)',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm1d3',
          title: 'Full Body C',
          focus: 'Full body + Arms + Core',
          warmup: '5-10 min walk + dynamic stretches',
          exercises: [
            Exercise(name: 'Romanian Deadlift (light)', emoji: '🦵', sets: '3', reps: '12', tip: 'Peeth seedhi, hips peeche.'),
            Exercise(name: 'Push-ups (knee/full)', emoji: '💪', sets: '3', reps: '10-12', tip: 'Body straight, chest neeche.'),
            Exercise(name: 'Assisted Pull-up / Pulldown', emoji: '🔙', sets: '3', reps: '10', tip: 'Full stretch upar.'),
            Exercise(name: 'Dumbbell Bicep Curl', emoji: '💪', sets: '3', reps: '12', tip: 'Kohni body se chipki.'),
            Exercise(name: 'Tricep Pushdown', emoji: '💪', sets: '3', reps: '12', tip: 'Sirf forearm move kare.'),
            Exercise(name: 'Crunches', emoji: '🔥', sets: '3', reps: '15', tip: 'Upper abs squeeze.'),
          ],
          cardio: '15 min brisk walk',
          cooldown: '5 min stretch',
        ),
      ],
    ),

    // ---------------- MONTH 2 ----------------
    MonthPlan(
      month: 2,
      name: 'Build & Burn',
      goal: 'Strength badhao + fat burn tez karo. 4 din split + core circuit.',
      highlights: [
        'Progressive overload: har week thoda weight/reps badhao',
        '4 din: Upper / Lower / Push / Pull',
        '25-30 min cardio + dedicated core day',
        'Protein roz (body weight x 1.6g), deficit jaari',
      ],
      days: [
        WorkoutDay(
          id: 'm2d1',
          title: 'Upper Body',
          focus: 'Chest + Back + Shoulders + Arms',
          warmup: '8 min cardio + band work',
          exercises: [
            Exercise(name: 'Barbell / Machine Bench Press', emoji: '💪', sets: '4', reps: '10', tip: 'Bar chest tak, control.'),
            Exercise(name: 'Lat Pulldown', emoji: '🔙', sets: '4', reps: '10', tip: 'Elbows neeche kheecho.'),
            Exercise(name: 'Seated Shoulder Press', emoji: '🏋️', sets: '3', reps: '10', tip: 'Core tight.'),
            Exercise(name: 'Cable Row', emoji: '🔙', sets: '3', reps: '12', tip: 'Squeeze back.'),
            Exercise(name: 'Bicep Curl + Tricep Pushdown (superset)', emoji: '💪', sets: '3', reps: '12', tip: 'Bina rest dono.'),
          ],
          cardio: '15 min incline walk',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm2d2',
          title: 'Lower Body',
          focus: 'Legs + Glutes + Core',
          warmup: '8 min cycle + leg swings',
          exercises: [
            Exercise(name: 'Squat (barbell/goblet)', emoji: '🦵', sets: '4', reps: '10', tip: 'Depth: thigh parallel.'),
            Exercise(name: 'Leg Press', emoji: '🦵', sets: '3', reps: '12', tip: 'Knees toes direction.'),
            Exercise(name: 'Romanian Deadlift', emoji: '🦵', sets: '3', reps: '10', tip: 'Hamstring stretch feel karo.'),
            Exercise(name: 'Leg Curl + Leg Extension', emoji: '🦵', sets: '3', reps: '12', tip: 'Slow control.'),
            Exercise(name: 'Hanging Leg Raise', emoji: '🔥', sets: '3', reps: '12', tip: 'Lower abs.'),
          ],
          cardio: '10 min cycle',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm2d3',
          title: 'Push + Core',
          focus: 'Chest + Shoulders + Triceps + Abs',
          warmup: '8 min cardio',
          exercises: [
            Exercise(name: 'Incline Dumbbell Press', emoji: '💪', sets: '4', reps: '10', tip: 'Upper chest.'),
            Exercise(name: 'Overhead Press', emoji: '🏋️', sets: '3', reps: '10', tip: 'Core braced.'),
            Exercise(name: 'Lateral Raise', emoji: '🏋️', sets: '3', reps: '15', tip: 'Light weight.'),
            Exercise(name: 'Tricep Dips / Pushdown', emoji: '💪', sets: '3', reps: '12', tip: 'Full extension.'),
            Exercise(name: 'CORE CIRCUIT: Plank + Crunch + Russian Twist', emoji: '🔥', sets: '3', reps: '40s/15/20', tip: 'Round mein, kam rest.'),
          ],
          cardio: '20 min HIIT (30s fast / 60s slow)',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm2d4',
          title: 'Pull + Core',
          focus: 'Back + Biceps + Abs',
          warmup: '8 min cardio + band pull-apart',
          exercises: [
            Exercise(name: 'Pull-up / Assisted Pull-up', emoji: '🔙', sets: '4', reps: '8', tip: 'Full hang.'),
            Exercise(name: 'Bent-over / Machine Row', emoji: '🔙', sets: '4', reps: '10', tip: 'Peeth seedhi.'),
            Exercise(name: 'Face Pull', emoji: '🔙', sets: '3', reps: '15', tip: 'Rear delt.'),
            Exercise(name: 'Bicep Curl (DB + Hammer)', emoji: '💪', sets: '3', reps: '12', tip: 'No swing.'),
            Exercise(name: 'CORE CIRCUIT: Leg raise + Bicycle + Plank', emoji: '🔥', sets: '3', reps: '15/20/40s', tip: 'Continuous.'),
          ],
          cardio: '20 min steady cardio',
          cooldown: '5 min stretch',
        ),
      ],
    ),

    // ---------------- MONTH 3 ----------------
    MonthPlan(
      month: 3,
      name: 'Cut & Carve',
      goal: 'Fat chhilo, abs reveal karo. 5 din + HIIT + heavy core focus.',
      highlights: [
        'Intensity max, rest kam (45-60s)',
        '5 din: Push / Pull / Legs / Upper / Core+HIIT',
        'Roz cardio + 2x dedicated ab sessions',
        'Diet sabse important: deficit + high protein (abs = kitchen)',
      ],
      days: [
        WorkoutDay(
          id: 'm3d1',
          title: 'Push',
          focus: 'Chest + Shoulders + Triceps',
          warmup: '8 min cardio',
          exercises: [
            Exercise(name: 'Bench Press', emoji: '💪', sets: '4', reps: '8-10', tip: 'Heavy but clean.'),
            Exercise(name: 'Incline DB Press', emoji: '💪', sets: '3', reps: '10', tip: 'Upper chest.'),
            Exercise(name: 'Overhead Press', emoji: '🏋️', sets: '3', reps: '10', tip: 'Strict.'),
            Exercise(name: 'Cable Fly', emoji: '💪', sets: '3', reps: '15', tip: 'Squeeze chest.'),
            Exercise(name: 'Tricep Pushdown', emoji: '💪', sets: '3', reps: '12', tip: 'Slow negative.'),
          ],
          cardio: '15 min HIIT',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm3d2',
          title: 'Pull',
          focus: 'Back + Biceps + Rear delt',
          warmup: '8 min cardio',
          exercises: [
            Exercise(name: 'Pull-up (weighted/assisted)', emoji: '🔙', sets: '4', reps: '8', tip: 'Controlled.'),
            Exercise(name: 'Barbell / Machine Row', emoji: '🔙', sets: '4', reps: '10', tip: 'Squeeze.'),
            Exercise(name: 'Lat Pulldown', emoji: '🔙', sets: '3', reps: '12', tip: 'Stretch top.'),
            Exercise(name: 'Face Pull', emoji: '🔙', sets: '3', reps: '15', tip: 'Posture.'),
            Exercise(name: 'Bicep Curl 21s', emoji: '💪', sets: '3', reps: '21', tip: '7+7+7.'),
          ],
          cardio: '15 min steady',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm3d3',
          title: 'Legs',
          focus: 'Quads + Hamstrings + Glutes + Calves',
          warmup: '10 min cycle + leg swings',
          exercises: [
            Exercise(name: 'Squat', emoji: '🦵', sets: '4', reps: '8-10', tip: 'Depth + control.'),
            Exercise(name: 'Romanian Deadlift', emoji: '🦵', sets: '4', reps: '10', tip: 'Hamstrings.'),
            Exercise(name: 'Walking Lunges', emoji: '🦵', sets: '3', reps: '12 each', tip: 'Knee track.'),
            Exercise(name: 'Leg Curl + Extension', emoji: '🦵', sets: '3', reps: '12', tip: 'Slow.'),
            Exercise(name: 'Calf Raise', emoji: '🦵', sets: '4', reps: '15', tip: 'Full stretch.'),
          ],
          cardio: '10 min walk',
          cooldown: '8 min stretch',
        ),
        WorkoutDay(
          id: 'm3d4',
          title: 'Upper Pump',
          focus: 'Whole upper body, higher reps',
          warmup: '8 min cardio',
          exercises: [
            Exercise(name: 'Incline Press', emoji: '💪', sets: '3', reps: '12', tip: 'Pump.'),
            Exercise(name: 'Cable Row', emoji: '🔙', sets: '3', reps: '12', tip: 'Squeeze.'),
            Exercise(name: 'Lateral Raise (drop set)', emoji: '🏋️', sets: '3', reps: '15+drop', tip: 'Burn.'),
            Exercise(name: 'Superset: Curl + Pushdown', emoji: '💪', sets: '3', reps: '15', tip: 'No rest.'),
            Exercise(name: 'Push-up finisher', emoji: '💪', sets: '2', reps: 'AMRAP', tip: 'Max reps.'),
          ],
          cardio: '20 min HIIT',
          cooldown: '5 min stretch',
        ),
        WorkoutDay(
          id: 'm3d5',
          title: 'Core + HIIT',
          focus: '6-pack carve + max fat burn',
          warmup: '8 min cardio',
          exercises: [
            Exercise(name: 'Hanging Leg Raise', emoji: '🔥', sets: '4', reps: '12', tip: 'Lower abs.'),
            Exercise(name: 'Cable Crunch', emoji: '🔥', sets: '4', reps: '15', tip: 'Upper abs squeeze.'),
            Exercise(name: 'Russian Twist (weighted)', emoji: '🔥', sets: '3', reps: '20', tip: 'Obliques.'),
            Exercise(name: 'Bicycle Crunch', emoji: '🔥', sets: '3', reps: '20', tip: 'Controlled.'),
            Exercise(name: 'Plank + Side Plank', emoji: '🔥', sets: '3', reps: '45s + 30s', tip: 'Tight core.'),
          ],
          cardio: '25 min HIIT (sprints/bike intervals)',
          cooldown: '8 min stretch',
        ),
      ],
    ),
  ];

  static MonthPlan monthByNumber(int m) =>
      months.firstWhere((mp) => mp.month == m, orElse: () => months.first);
}
