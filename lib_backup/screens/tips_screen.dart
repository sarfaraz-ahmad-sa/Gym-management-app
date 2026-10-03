import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/tips_data.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text(
            'Tumhara personal coach 👇 Jab bhi confuse ho, yahan padho.',
            style: TextStyle(color: AppTheme.textDim, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...TipsData.sections.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...s.points.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.arrow_right,
                                      color: AppTheme.accent, size: 18),
                                ),
                                Expanded(
                                    child: Text(p,
                                        style: const TextStyle(
                                            fontSize: 13.5, height: 1.4))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
