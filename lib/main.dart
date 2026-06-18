import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'screens/root_nav.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const FitGuideApp());
}

class FitGuideApp extends StatelessWidget {
  const FitGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'FitGuide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const _Gate(),
      ),
    );
  }
}

/// Shows onboarding until a profile is set, then the main app.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.hasProfile) {
      return const OnboardingScreen();
    }
    return const RootNav();
  }
}
