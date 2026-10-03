import 'package:flutter/material.dart';
import '../models/trainer.dart';
import '../services/db_service.dart';

class TrainerListScreen extends StatefulWidget {
  const TrainerListScreen({super.key});

  @override
  State<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  late Future<List<Trainer>> _trainersFuture;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _trainersFuture = _db.getAllTrainers();
    });
  }

  void _addTrainer() {
    // TODO: Implement add trainer dialog
  }

  void _editTrainer(Trainer trainer) {
    // TODO: Implement edit trainer dialog
  }

  void _deleteTrainer(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trainer'),
        content: const Text('Are you sure you want to delete this trainer?'),
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
      await _db.deleteTrainer(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Trainer>>(
        future: _trainersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final trainers = snapshot.data!;
          if (trainers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No trainers yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTrainer,
                    child: const Text('Add First Trainer'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trainers.length,
            itemBuilder: (context, index) {
              final trainer = trainers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(trainer.name[0]),
                  ),
                  title: Text(trainer.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.phone),
                      if (trainer.specialization != null)
                        Chip(
                          label: Text(trainer.specialization!,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      if (trainer.status != null)
                        Chip(
                          label: Text(trainer.status!,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: trainer.status == 'active'
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
                        onPressed: () => _editTrainer(trainer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTrainer(trainer.id!),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to trainer detail
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrainer,
        child: const Icon(Icons.add),
      ),
    );
  }
}