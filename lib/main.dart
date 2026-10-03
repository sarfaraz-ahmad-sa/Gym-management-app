import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database_factory.dart';
import 'core/gym_store.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDatabaseFactory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => AuthService()),
    ],
    child: const FitGuideApp(),
  );
}

class FitGuideApp extends StatelessWidget {
  const FitGuideApp({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'FitGuide Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(false),
      darkTheme: AppTheme.build(true),
      themeMode: theme.dark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.error != null) {
      return Scaffold(
        body: EmptyState(
          title: 'Workspace unavailable',
          message: auth.error!,
          action: FilledButton(
            onPressed: auth.initialize,
            child: const Text('Retry'),
          ),
        ),
      );
    }
    if (!auth.loggedIn) return const LoginScreen();
    return ChangeNotifierProvider(
      key: ValueKey('${auth.demo}_${auth.workspaceId}'),
      create: (_) {
        final db = auth.demo
            ? DatabaseService(name: 'fitguide_demo.db')
            : auth.db;
        final store = GymStore(db, demo: auth.demo);
        store.initialize();
        return store;
      },
      child: const AppShell(),
    );
  }
}
