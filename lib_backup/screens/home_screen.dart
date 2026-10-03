import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../data/plan_data.dart';
import '../models/workout.dart';
import '../models/goal.dart';
import 'workout_detail_screen.dart';
import 'tips_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final month = PlanData.monthByNumber(state.currentMonth);
    // Pick "today's" workout by rotating through the month's days.
    final dayIndex = (state.dayNumber - 1) % month.days.length;
    final WorkoutDay today = month.days[dayIndex];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(
                              color: AppTheme.textDim, fontSize: 14)),
                      const Text('Aaj ka din 🔥',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TipsScreen()),
                      ),
                      icon: const Icon(Icons.tips_and_updates_outlined),
                      tooltip: 'Fitness Guide',
                      color: AppTheme.accent,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Day ${state.dayNumber}',
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _goalCard(state),
            const SizedBox(height: 16),
            _statsRow(state),
            const SizedBox(height: 16),
            _performanceCard(state),
            const SizedBox(height: 16),
            _achievementsCard(state),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Aaj ka workout',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Month ${month.month} • ${month.name}',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            _todayCard(context, today, state),
            const SizedBox(height: 20),
            _quote(),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _goalCard(AppState s) {
    final pct = (s.progressFraction * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bigStat('${s.currentWeight.toStringAsFixed(1)}', 'Abhi (kg)'),
                const Icon(Icons.arrow_forward, color: AppTheme.textDim),
                _bigStat('${s.goalWeight.toStringAsFixed(0)}', 'Goal (kg)',
                    color: AppTheme.accent2),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: s.progressFraction,
                minHeight: 12,
                backgroundColor: AppTheme.surface2,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.accent2),
              ),
            ),
            const SizedBox(height: 8),
            Text('$pct% goal complete • '
                '${(s.startWeight - s.currentWeight).toStringAsFixed(1)} kg kam hua',
                style: const TextStyle(
                    color: AppTheme.textDim, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String v, String label, {Color? color}) {
    return Column(
      children: [
        Text(v,
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: color ?? AppTheme.textMain)),
        Text(label,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
      ],
    );
  }

  Widget _statsRow(AppState s) {
    return Row(
      children: [
        _miniStat('${s.totalWorkoutsDone}', 'Workouts done', Icons.check_circle),
        const SizedBox(width: 12),
        _miniStat(s.bmi.toStringAsFixed(1), 'BMI', Icons.monitor_weight),
        const SizedBox(width: 12),
        _miniStat('${s.currentMonth}/3', 'Month', Icons.calendar_today),
      ],
    );
  }

  Widget _miniStat(String v, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 22),
            const SizedBox(height: 6),
            Text(v,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppTheme.textDim, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _performanceCard(AppState s) {
    final streak = s.habitStreak(HabitsData.daily.length);
    final trend = s.weightTrend;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: s.weeklyConsistency,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.surface2,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${s.workoutsThisWeek}/${s.weeklyTarget}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('week',
                          style: TextStyle(
                              color: AppTheme.textDim, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _perfRow('🔥', '$streak din habit streak'),
                  const SizedBox(height: 4),
                  _perfRow(
                    trend == null
                        ? '➖'
                        : (trend <= 0 ? '📉' : '📈'),
                    trend == null
                        ? 'Weight log karo trend ke liye'
                        : '${trend <= 0 ? 'Down' : 'Up'} '
                            '${trend.abs().toStringAsFixed(1)} kg (last log)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textDim, fontSize: 13))),
      ],
    );
  }

  Widget _achievementsCard(AppState s) {
    final list = s.achievements;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏅 Achievements',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${list.where((a) => a.unlocked).length}/${list.length}',
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: list.map((a) {
                return Opacity(
                  opacity: a.unlocked ? 1 : 0.32,
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: a.unlocked
                                ? AppTheme.accent.withOpacity(0.18)
                                : AppTheme.surface2,
                            shape: BoxShape.circle,
                          ),
                          child: Text(a.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(height: 5),
                        Text(a.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, height: 1.2)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayCard(BuildContext context, WorkoutDay day, AppState s) {
    final done = s.isDoneToday(day.id);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(day: day)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(day.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (done)
                    const Icon(Icons.check_circle,
                        color: AppTheme.accent2, size: 26),
                ],
              ),
              const SizedBox(height: 4),
              Text(day.focus,
                  style: const TextStyle(
                      color: AppTheme.accent, fontSize: 14)),
              const SizedBox(height: 14),
              Text('${day.exercises.length} exercises • ${day.cardio}',
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Text('Workout kholo',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right, color: AppTheme.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quote() {
    final quotes = [
      'Discipline tab kaam aati hai jab motivation nahi hoti. 🔥',
      'Abs kitchen mein bante hain — diet pe dhyan. 🥗',
      'Aaj ka pasina, kal ka result. 💪',
      'Compare khud se karo, kal ke khud se. 📈',
    ];
    final q = quotes[DateTime.now().day % quotes.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFFFF9558)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(q,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),
    );
  }
}
