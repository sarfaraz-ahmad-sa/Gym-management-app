import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/db_service.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  late Future<List<Member>> _membersFuture;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _membersFuture = _db.getAllMembers();
    });
  }

  void _addMember() {
    // TODO: Implement add member dialog
  }

  void _editMember(Member member) {
    // TODO: Implement edit member dialog
  }

  void _deleteMember(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: const Text('Are you sure you want to delete this member?'),
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
      await _db.deleteMember(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Member>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data!;
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No members yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addMember,
                    child: const Text('Add First Member'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.name[0]),
                  ),
                  title: Text(member.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.phone),
                      if (member.status != null)
                        Chip(
                          label: Text(member.status!,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: member.status == 'active'
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editMember(member),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMember(member.id!),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to member detail
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        child: const Icon(Icons.add),
      ),
    );
  }
}