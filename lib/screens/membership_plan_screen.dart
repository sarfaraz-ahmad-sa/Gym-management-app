import 'package:flutter/material.dart';
import '../models/membership_plan.dart';
import '../services/db_service.dart';

class MembershipPlanScreen extends StatefulWidget {
  const MembershipPlanScreen({super.key});

  @override
  State<MembershipPlanScreen> createState() => _MembershipPlanScreenState();
}

class _MembershipPlanScreenState extends State<MembershipPlanScreen> {
  late Future<List<MembershipPlan>> _plansFuture;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _plansFuture = _db.getAllMembershipPlans();
    });
  }

  void _addPlan() {
    // TODO: Implement add plan dialog
  }

  void _editPlan(MembershipPlan plan) {
    // TODO: Implement edit plan dialog
  }

  void _deletePlan(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Membership Plan'),
        content: const Text('Are you sure you want to delete this plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteMembershipPlan(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MembershipPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_membership_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No membership plans yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addPlan,
                    child: const Text('Add First Plan'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(plan.name[0]),
                  ),
                  title: Text(plan.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$${plan.price.toStringAsFixed(2)} - ${plan.durationDays} days'),
                      if (plan.features != null && plan.features!.isNotEmpty)
                        Text('Features: ${plan.features!}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPlan(plan),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlan(plan.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlan,
        child: const Icon(Icons.add),
      ),
    );
  }
}