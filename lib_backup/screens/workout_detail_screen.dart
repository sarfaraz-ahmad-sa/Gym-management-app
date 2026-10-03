import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../models/workout.dart';
import '../data/exercise_guides.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutDay day;
  const WorkoutDetailScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final done = state.isDoneToday(day.id);

    return Scaffold(
      appBar: AppBar(title: Text(day.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.focus,
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _row(Icons.local_fire_department, 'Warm-up', day.warmup),
                const SizedBox(height: 6),
                _row(Icons.directions_run, 'Cardio', day.cardio),
                const SizedBox(height: 6),
                _row(Icons.self_improvement, 'Cool-down', day.cooldown),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Exercises',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...day.exercises.asMap().entries.map((e) {
            final i = e.key;
            final ex = e.value;
            final guide = ExerciseGuides.forName(ex.name);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showGuide(context, ex, guide),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset(guide.asset),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. ${ex.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${ex.sets} sets × ${ex.reps}',
                                  style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ),
                            if (ex.tip.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('💡 ${ex.tip}',
                                  style: const TextStyle(
                                      color: AppTheme.textDim,
                                      fontSize: 12.5)),
                            ],
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(Icons.menu_book_outlined,
                                    size: 14, color: AppTheme.accent2),
                                SizedBox(width: 4),
                                Text('Tap: kaise karein dekho',
                                    style: TextStyle(
                                        color: AppTheme.accent2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    done ? AppTheme.surface2 : AppTheme.accent2,
                foregroundColor: done ? AppTheme.textDim : Colors.black,
              ),
              onPressed: () =>
                  context.read<AppState>().toggleDone(day.id),
              icon: Icon(done ? Icons.refresh : Icons.check),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                    done ? 'Done hai ✓ (undo karne ke liye tap)' : 'Mark as done',
                    style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuide(BuildContext context, Exercise ex, ExerciseGuide g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(g.asset),
            ),
            const SizedBox(height: 14),
            Text(ex.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${g.category} • ${ex.sets} sets × ${ex.reps}',
                style: const TextStyle(color: AppTheme.accent, fontSize: 13.5)),
            const SizedBox(height: 18),
            _guideBlock('✅ Kaise karein', g.steps, AppTheme.accent2,
                numbered: true),
            const SizedBox(height: 14),
            _guideBlock('⚠️ Common galtiyan', g.mistakes, AppTheme.danger),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.air, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Saans: ${g.breathing}',
                        style: const TextStyle(fontSize: 13.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideBlock(String title, List<String> items, Color color,
      {bool numbered = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    alignment: Alignment.center,
                    child: numbered
                        ? Text('${e.key + 1}',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w800))
                        : Icon(Icons.circle, size: 7, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 13.5, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textDim),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                    text: value,
                    style: const TextStyle(color: AppTheme.textDim)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
