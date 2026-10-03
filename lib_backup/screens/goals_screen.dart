import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../models/goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.habitStreak(HabitsData.daily.length);
    final doneToday = HabitsData.daily
        .where((h) => state.isHabitDoneToday(h.id))
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals & Habits')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: () => _addGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          // Habit streak header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFFFF9558)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 38)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$streak din ka streak',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('Aaj: $doneToday/${HabitsData.daily.length} habits done',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Aaj ke daily habits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...HabitsData.daily.map((h) {
            final done = state.isHabitDoneToday(h.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.read<AppState>().toggleHabit(h.id),
                leading: Text(h.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(h.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done ? AppTheme.textDim : AppTheme.textMain)),
                trailing: Icon(
                  done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: done ? AppTheme.accent2 : AppTheme.textDim,
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Life goals',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${state.goals.where((g) => g.done).length}/${state.goals.length} done',
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (state.goals.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '🎯 Abhi koi goal nahi.\n\nExamples: "68 kg tak pahunchna", '
                '"Pehla pull-up", "30 din lagatar gym", "Abs dikhna".\n\n'
                '+ button se apne goals add karo.',
                style: TextStyle(color: AppTheme.textDim, height: 1.5),
              ),
            )
          else
            ...state.goals.map((g) => _goalTile(context, g)),
        ],
      ),
    );
  }

  Widget _goalTile(BuildContext context, Goal g) {
    final dateStr = g.targetDate != null
        ? DateFormat('d MMM yyyy').format(g.targetDate!)
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.read<AppState>().toggleGoal(g.id),
        leading: Icon(
          g.done ? Icons.task_alt : Icons.flag_outlined,
          color: g.done ? AppTheme.accent2 : AppTheme.accent,
        ),
        title: Text(g.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: g.done ? TextDecoration.lineThrough : null,
                color: g.done ? AppTheme.textDim : AppTheme.textMain)),
        subtitle: dateStr != null
            ? Text('🎯 $dateStr',
                style:
                    const TextStyle(color: AppTheme.textDim, fontSize: 12.5))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: AppTheme.textDim, size: 20),
          onPressed: () => context.read<AppState>().removeGoal(g.id),
        ),
      ),
    );
  }

  void _addGoalDialog(BuildContext context) {
    final ctrl = TextEditingController();
    DateTime? picked;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Naya goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. 68 kg tak pahunchna',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      picked == null
                          ? 'Target date (optional)'
                          : DateFormat('d MMM yyyy').format(picked!),
                      style: const TextStyle(color: AppTheme.textDim),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 730)),
                      );
                      if (d != null) setLocal(() => picked = d);
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final t = ctrl.text.trim();
                if (t.isNotEmpty) {
                  context.read<AppState>().addGoal(t, targetDate: picked);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
