import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';
import '../services/db_service.dart';

class WhatsAppMessageScreen extends StatefulWidget {
  const WhatsAppMessageScreen({super.key});

  @override
  State<WhatsAppMessageScreen> createState() => _WhatsAppMessageScreenState();
}

class _WhatsAppMessageScreenState extends State<WhatsAppMessageScreen> {
  late Future<List<Member>> _membersFuture;
  final DatabaseService _db = DatabaseService.instance;
  final TextEditingController _messageController = TextEditingController();
  final List<bool> _selectedMembers = [];

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

  Future<void> _sendWhatsApp(String phone, String message) async {
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _sendBulkMessages() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }
    final members = await _membersFuture;
    for (int i = 0; i < members.length; i++) {
      if (_selectedMembers[i]) {
        final member = members[i];
        await _sendWhatsApp(member.phone, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compose WhatsApp Message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _sendBulkMessages,
                        icon: const Icon(Icons.send),
                        label: const Text('Send to Selected Members'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Member>>(
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
                      ],
                    ),
                  );
                }
                // Initialize selection list
                if (_selectedMembers.length != members.length) {
                  _selectedMembers.clear();
                  _selectedMembers.addAll(List.filled(members.length, false));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return CheckboxListTile(
                      value: _selectedMembers[index],
                      onChanged: (value) {
                        setState(() {
                          _selectedMembers[index] = value!;
                        });
                      },
                      title: Text(member.name),
                      subtitle: Text(member.phone),
                      secondary: IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Message ${member.name}'),
                              content: TextField(
                                controller: TextEditingController(text: _messageController.text),
                                maxLines: 3,
                                decoration: const InputDecoration(hintText: 'Message'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final message = _messageController.text.trim();
                                    if (message.isNotEmpty) {
                                      await _sendWhatsApp(member.phone, message);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Send'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}