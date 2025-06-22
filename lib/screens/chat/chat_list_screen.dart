import 'package:flutter/material.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import '../../models/user.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> chatRooms = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final rooms = await ChatService.getChatRooms();
      setState(() {
        chatRooms = rooms;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Ming'];
      return days[date.weekday - 1];
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chats...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat chats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChatRooms,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada chat',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai percakapan dengan mencari di kontak',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = chatRooms[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: chatRoom.displayAvatar != null
                    ? NetworkImage(chatRoom.displayAvatar!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: chatRoom.displayAvatar == null
                    ? Text(
                        chatRoom.displayName.isNotEmpty
                            ? chatRoom.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                chatRoom.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                chatRoom.lastMessage.isNotEmpty
                    ? chatRoom.lastMessage
                    : 'Belum ada chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chatRoom.lastMessage.isNotEmpty
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              trailing: Text(
                _formatDate(chatRoom.updatedAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      roomId: chatRoom.id,
                      partnerName: chatRoom.displayName,
                    ),
                  ),
                ).then((_) {
                  _loadChatRooms();
                });
              },
            ),
          );
        },
      ),
    );
  }
}
