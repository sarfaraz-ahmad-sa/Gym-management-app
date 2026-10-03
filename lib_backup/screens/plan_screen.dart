import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../data/plan_data.dart';
import '../models/workout.dart';
import 'workout_detail_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _selectedMonth = 1;

  @override
  void initState() {
    super.initState();
    _selectedMonth = context.read<AppState>().currentMonth;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final month = PlanData.monthByNumber(_selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('3-Month Plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // Month selector
          Row(
            children: PlanData.months.map((m) {
              final sel = m.month == _selectedMonth;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMonth = m.month),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.accent : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text('Month ${m.month}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : AppTheme.textMain)),
                        Text(m.name,
                            style: TextStyle(
                                fontSize: 11,
                                color: sel
                                    ? Colors.white70
                                    : AppTheme.textDim)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎯 ${month.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(month.goal,
                      style: const TextStyle(
                          color: AppTheme.textDim, fontSize: 14)),
                  const SizedBox(height: 14),
                  ...month.highlights.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(color: AppTheme.accent2)),
                            Expanded(
                                child: Text(h,
                                    style: const TextStyle(fontSize: 13.5))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Workout days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...month.days.map((d) => _dayTile(context, d, state)),
        ],
      ),
    );
  }

  Widget _dayTile(BuildContext context, WorkoutDay day, AppState s) {
    final done = s.isDoneToday(day.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withOpacity(0.15),
          child: Text('${day.exercises.length}',
              style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w800)),
        ),
        title: Text(day.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(day.focus,
            style: const TextStyle(color: AppTheme.textDim, fontSize: 12.5)),
        trailing: Icon(
          done ? Icons.check_circle : Icons.chevron_right,
          color: done ? AppTheme.accent2 : AppTheme.textDim,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkoutDetailScreen(day: day)),
        ),
      ),
    );
  }
}
