import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diet_data.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.accent2, Color(0xFF1FB789)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('🥗 Fat loss + abs diet',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(DietData.summary,
                    style: TextStyle(color: Colors.black87, fontSize: 13.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Din ka plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...DietData.meals.map((m) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.time,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5)),
                            const SizedBox(height: 6),
                            ...m.options.map((o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text('• $o',
                                      style: const TextStyle(
                                          color: AppTheme.textDim,
                                          fontSize: 13)),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
          const Text('Diet rules',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: DietData.rules
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppTheme.accent2, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(r,
                                      style: const TextStyle(fontSize: 13.5))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
            ),
            child: const Text(
              'Note: Ye general guidance hai. Koi medical condition ho '
              '(diabetes, BP, etc.) to doctor/dietician se confirm karo.',
              style: TextStyle(color: AppTheme.textDim, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
