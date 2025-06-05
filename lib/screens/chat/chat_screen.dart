import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../providers/chat_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

int? currentUserId;

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String partnerName;
  const ChatScreen({Key? key, required this.roomId, required this.partnerName})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).fetchMessages(widget.roomId);
    });
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      final userMap = json.decode(userJson);
      setState(() {
        currentUserId = userMap['id'];
      });
    }
  }

  void _sendMessage(String text, bool encrypt) {
    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).sendMessage(widget.roomId, text, encrypt: encrypt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.partnerName)),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chat.error != null) {
            return Center(child: Text('Error: ${chat.error}'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chat.messages[chat.messages.length - 1 - index];
                    return MessageBubble(
                      message: msg,
                      isMe:
                          currentUserId != null &&
                          msg.senderId == currentUserId,
                      roomId: widget.roomId,
                    );
                  },
                ),
              ),
              ChatInput(onSendMessage: _sendMessage),
            ],
          );
        },
      ),
    );
  }
}
