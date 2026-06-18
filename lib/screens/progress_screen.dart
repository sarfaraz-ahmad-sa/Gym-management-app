import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../state/app_state.dart';
import 'photos_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Progress photos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhotosScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: () => _addWeightDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Weight log'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          _summaryCard(state),
          const SizedBox(height: 20),
          const Text('Weight graph',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: SizedBox(
                height: 220,
                child: state.weights.length < 2
                    ? const Center(
                        child: Text(
                            'Kam se kam 2 entries daalo graph ke liye 📈',
                            style: TextStyle(color: AppTheme.textDim)))
                    : _chart(state),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Records',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${state.weights.length} entries',
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (state.weights.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Abhi koi record nahi. + button se weight log karo.',
                  style: TextStyle(color: AppTheme.textDim)),
            )
          else
            ...List.generate(state.weights.length, (i) {
              final idx = state.weights.length - 1 - i; // newest first
              final e = state.weights[idx];
              final prev = idx > 0 ? state.weights[idx - 1].weight : null;
              final diff = prev != null ? e.weight - prev : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight,
                      color: AppTheme.accent),
                  title: Text('${e.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(DateFormat('EEE, d MMM yyyy').format(e.date),
                      style: const TextStyle(
                          color: AppTheme.textDim, fontSize: 12.5)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (diff != null)
                        Text(
                          '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: diff <= 0
                                ? AppTheme.accent2
                                : AppTheme.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.textDim, size: 20),
                        onPressed: () =>
                            context.read<AppState>().removeWeight(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _summaryCard(AppState s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${s.startWeight.toStringAsFixed(1)}', 'Start'),
            _stat('${s.currentWeight.toStringAsFixed(1)}', 'Abhi',
                color: AppTheme.accent),
            _stat('${s.goalWeight.toStringAsFixed(0)}', 'Goal',
                color: AppTheme.accent2),
            _stat('${(s.currentWeight - s.goalWeight).toStringAsFixed(1)}',
                'Baaki'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String l, {Color? color}) => Column(
        children: [
          Text(v,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color ?? AppTheme.textMain)),
          Text(l,
              style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
        ],
      );

  Widget _chart(AppState s) {
    final spots = <FlSpot>[];
    for (var i = 0; i < s.weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), s.weights[i].weight));
    }
    final values = s.weights.map((e) => e.weight).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 1);
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 1);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.surface2, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 11)),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        // Goal line
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: s.goalWeight,
            color: AppTheme.accent2,
            strokeWidth: 1.5,
            dashArray: [6, 4],
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  void _addWeightDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Aaj ka weight'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: 'kg',
            hintText: 'e.g. 71.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(ctrl.text.trim());
              if (w != null) {
                context.read<AppState>().addWeight(w);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
