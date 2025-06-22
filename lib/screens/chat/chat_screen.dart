import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';
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
  bool isWhisperAuthenticated = false;
  bool _isValidatingPassword = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _passwordController = TextEditingController();

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
    _scrollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    await Provider.of<ChatProvider>(
      context,
      listen: false,
    ).fetchMessages(widget.roomId);

    // Scroll to bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text, bool encrypt) async {
    try {
      await Provider.of<ChatProvider>(
        context,
        listen: false,
      ).sendMessage(widget.roomId, text, encrypt: encrypt);

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showPasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Enter Whisper Password'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your login password to enable whisper mode and decrypt messages.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: true,
                    enabled: !_isValidatingPassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _authenticateWhisper(setDialogState),
                  ),
                  if (_isValidatingPassword) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Validating password...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isValidatingPassword
                      ? null
                      : () {
                          _passwordController.clear();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isValidatingPassword
                      ? null
                      : () => _authenticateWhisper(setDialogState),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isValidatingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _authenticateWhisper(StateSetter setDialogState) async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter your password'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setDialogState(() {
      _isValidatingPassword = true;
    });

    try {
      // Validate password with API
      final isValid = await AuthService.validatePassword(
        _passwordController.text,
      );

      setDialogState(() {
        _isValidatingPassword = false;
      });

      if (isValid) {
        setState(() {
          isWhisperAuthenticated = true;
          whisperMode = true;
        });
        _passwordController.clear();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Whisper mode activated'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Incorrect password'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setDialogState(() {
        _isValidatingPassword = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Failed to validate password: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _toggleWhisperMode(bool value) {
    if (value && !isWhisperAuthenticated) {
      _showPasswordDialog();
      return;
    }

    setState(() {
      whisperMode = value;
      if (!value) {
        isWhisperAuthenticated = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              whisperMode ? Icons.lock_open : Icons.lock,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              whisperMode
                  ? 'Whisper mode ON - Messages will be decrypted'
                  : 'Whisper mode OFF - Showing encrypted messages',
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: whisperMode ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                widget.partnerName.isNotEmpty
                    ? widget.partnerName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          // Whisper mode toggle with better design
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: whisperMode
                  ? Colors.green.withOpacity(0.1)
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: whisperMode
                    ? Colors.green.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  whisperMode ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                  color: whisperMode
                      ? Colors.green
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Whisper',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: whisperMode
                        ? Colors.green
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 20,
                  child: Switch(
                    value: whisperMode,
                    onChanged: _toggleWhisperMode,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading messages...',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          if (chat.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chat.error!,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadMessages,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (whisperMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.lock_open_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Whisper mode active - Encrypted messages are being decrypted',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: chat.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation with ${widget.partnerName}!',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chat
                                .messages[index]; // Messages in chronological order (oldest first)
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MessageBubble(
                                message: msg,
                                isMe:
                                    currentUserId != null &&
                                    msg.senderId == currentUserId,
                                roomId: widget.roomId,
                                whisperMode: whisperMode,
                              ),
                            );
                          },
                        ),
                      ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: ChatInput(
                    onSendMessage: _sendMessage,
                    whisperMode: whisperMode,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
