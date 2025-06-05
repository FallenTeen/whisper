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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  bool whisperMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh messages when app becomes active (user returns to app)
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
    }
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

  Future<void> _loadMessages() async {
    // Hanya load pesan tanpa dekripsi otomatis
    // Dekripsi akan dilakukan di level MessageBubble sesuai whisperMode
    await Provider.of<ChatProvider>(
      context,
      listen: false,
    ).fetchMessages(widget.roomId);
  }

  void _sendMessage(String text, bool encrypt) async {
    try {
      // Send message
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendMessage(widget.roomId, text, encrypt: encrypt);

      // Refresh messages after sending
      await _loadMessages();
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleWhisperMode(bool value) {
    setState(() {
      whisperMode = value;
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          whisperMode
              ? 'Whisper mode ON - Messages will be decrypted'
              : 'Whisper mode OFF - Encrypted messages will show as ciphertext',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: whisperMode ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Whisper mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  whisperMode ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text('Whisper', style: TextStyle(fontSize: 14)),
                Switch(
                  value: whisperMode,
                  onChanged: _toggleWhisperMode,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading messages...'),
                ],
              ),
            );
          }

          if (chat.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chat.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadMessages,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Status bar showing whisper mode
              if (whisperMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Whisper mode active - Encrypted messages will be decrypted',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: chat.messages.isEmpty
                    ? Center(
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
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation!',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg =
                                chat.messages[chat.messages.length - 1 - index];
                            return MessageBubble(
                              message: msg,
                              isMe:
                                  currentUserId != null &&
                                  msg.senderId == currentUserId,
                              roomId: widget.roomId,
                              whisperMode: whisperMode,
                            );
                          },
                        ),
                      ),
              ),

              // Chat input
              ChatInput(onSendMessage: _sendMessage, whisperMode: whisperMode),
            ],
          );
        },
      ),
    );
  }
}
