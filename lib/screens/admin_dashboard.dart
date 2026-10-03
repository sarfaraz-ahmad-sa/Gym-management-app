import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'member_list_screen.dart';
import 'membership_plan_screen.dart';
import 'attendance_screen.dart';
import 'trainer_list_screen.dart';
import 'whatsapp_message_screen.dart';
import 'payment_screen.dart';
import 'inventory_screen.dart';
import 'workout_plan_screen.dart';
import 'analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const AnalyticsScreen(),
    const MemberListScreen(),
    const MembershipPlanScreen(),
    const AttendanceScreen(),
    const TrainerListScreen(),
    const PaymentScreen(),
    const InventoryScreen(),
    const WorkoutPlanScreen(),
    const WhatsAppMessageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.card_membership), text: 'Plans'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Attendance'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Trainers'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.fitness_center_outlined), text: 'Workouts'),
            Tab(icon: Icon(Icons.message), text: 'WhatsApp'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs,
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Add member
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}