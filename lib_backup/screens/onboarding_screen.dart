import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _start = TextEditingController(text: '72');
  final _goal = TextEditingController(text: '68');
  final _height = TextEditingController(text: '172.72');

  @override
  void dispose() {
    _start.dispose();
    _goal.dispose();
    _height.dispose();
    super.dispose();
  }

  void _submit() async {
    final s = double.tryParse(_start.text.trim());
    final g = double.tryParse(_goal.text.trim());
    final h = double.tryParse(_height.text.trim());
    if (s == null || g == null || h == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi numbers daalo 🙂')),
      );
      return;
    }
    await context.read<AppState>().saveProfile(
          startWeight: s,
          goalWeight: g,
          height: h,
          startDate: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('💪', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('FitGuide',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                '3 mahine ka safar — apna goal set karo aur shuru ho jao.',
                style: TextStyle(color: AppTheme.textDim, fontSize: 15),
              ),
              const SizedBox(height: 32),
              _field('Abhi ka weight (kg)', _start),
              _field('Goal weight (kg)', _goal),
              _field('Height (cm)  •  5\'8" = 172.72', _height),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Start my journey →',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textDim, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
