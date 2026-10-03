import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/db_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<List<Payment>> _paymentsFuture;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _paymentsFuture = _db.getAllPayments();
    });
  }

  void _addPayment() {
    // TODO: Implement add payment dialog
  }

  void _editPayment(Payment payment) {
    // TODO: Implement edit payment dialog
  }

  void _deletePayment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
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
      await _db.deletePayment(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Payment>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final payments = snapshot.data!;
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No payments yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addPayment,
                    child: const Text('Add First Payment'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(payment.memberId.toString()),
                  ),
                  title: Text('Member ID: ${payment.memberId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount: \$${payment.amount.toStringAsFixed(2)}'),
                      Text('Date: ${payment.paymentDate.toString().substring(0, 16)}'),
                      Text('Status: ${payment.status}'),
                      if (payment.paymentMethod != null)
                        Text('Method: ${payment.paymentMethod}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPayment(payment),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePayment(payment.id!),
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
        onPressed: _addPayment,
        child: const Icon(Icons.add),
      ),
    );
  }
}