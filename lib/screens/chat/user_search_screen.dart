import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  List<User> users = [];
  bool loading = false;
  String error = '';
  String query = '';

  @override
  void initState() {
    super.initState();
    _searchUsers('');
  }

  void _searchUsers(String q) async {
    if (q.length < 2) {
      setState(() {
        users = [];
        error = 'Type at least 2 characters to search users';
      });
      return;
    }
    setState(() {
      loading = true;
      error = '';
      query = q;
    });
    try {
      final result = await ChatService.searchUsers(q);
      setState(() {
        users = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search user...',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error.isNotEmpty)
            Text(error, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('@${user.username ?? "unknown"}'),
                  onTap: () async {
                    try {
                      final chatRoom = await ChatService.createPrivateChat(
                        user.id,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            roomId: chatRoom.id,
                            partnerName: user.name,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create chat: $e')),
                      );
                    }
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
