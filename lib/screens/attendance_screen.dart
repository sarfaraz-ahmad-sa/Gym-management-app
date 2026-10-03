import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/db_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<Attendance>> _attendanceFuture;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _attendanceFuture = _db.getAllAttendance();
    });
  }

  void _addAttendance() {
    // TODO: Implement add attendance dialog (check-in)
  }

  void _checkOut(Attendance attendance) async {
    attendance.checkOut = DateTime.now();
    await _db.updateAttendance(attendance);
    _refresh();
  }

  void _deleteAttendance(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: const Text('Are you sure you want to delete this attendance record?'),
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
      await _db.deleteAttendance(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Attendance>>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final attendanceList = snapshot.data!;
          if (attendanceList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No attendance records yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addAttendance,
                    child: const Text('Check In First Member'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attendanceList.length,
            itemBuilder: (context, index) {
              final attendance = attendanceList[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(attendance.memberId.toString()),
                  ),
                  title: Text('Member ID: ${attendance.memberId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Check-in: ${attendance.checkIn.toString().substring(0, 16)}'),
                      if (attendance.checkOut != null)
                        Text('Check-out: ${attendance.checkOut.toString().substring(0, 16)}'),
                      if (attendance.checkOut == null)
                        const Text('Status: Currently in gym',
                            style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attendance.checkOut == null)
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.orange),
                          onPressed: () => _checkOut(attendance),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAttendance(attendance.id!),
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
        onPressed: _addAttendance,
        child: const Icon(Icons.add),
      ),
    );
  }
}