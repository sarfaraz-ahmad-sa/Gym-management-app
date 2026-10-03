import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitguide/services/auth_service.dart';
import 'package:fitguide/screens/login_screen.dart';
import 'package:fitguide/screens/admin_dashboard.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Gym Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.isLoggedIn) {
      // Admin role check? For now assume admin.
      return const AdminDashboard();
    }
    return const LoginScreen();
  }
}