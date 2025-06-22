import 'package:flutter/material.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  List<ChatRoom> chatRooms = [];
  bool loading = true;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _errorColor = Color(0xFFEF4444);

  static const _headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static const _bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const _captionLarge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static const double _space8 = 8.0;
  static const double _space12 = 12.0;
  static const double _space16 = 16.0;
  static const double _space20 = 20.0;
  static const double _space24 = 24.0;
  static const double _space32 = 32.0;
  static const double _radiusMedium = 8.0;
  static const double _radiusLarge = 12.0;
  static final List<BoxShadow> _shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadChatRooms();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: CircularProgressIndicator(
                  color: _primaryColor,
                  strokeWidth: 3,
                ),
              );
            },
          ),
          const SizedBox(height: _space20),
          const Text(
            'Loading chats...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(_space24),
        padding: const EdgeInsets.all(_space24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radiusLarge),
          boxShadow: _shadowSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_space16),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 32, color: _errorColor),
            ),
            const SizedBox(height: _space16),
            Text(
              'Gagal memuat chats',
              style: _headingMedium.copyWith(color: _textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space8),
            Text(
              error!,
              style: _bodyMedium.copyWith(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _space20),
            ElevatedButton.icon(
              onPressed: _loadChatRooms,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: _space20,
                  vertical: _space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radiusMedium),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(_space24),
        padding: const EdgeInsets.all(_space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_space20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: _space20),
            Text(
              'Belum ada chat',
              style: _headingMedium.copyWith(color: _textPrimary),
            ),
            const SizedBox(height: _space8),
            Text(
              'Mulai percakapan dengan mencari di kontak',
              style: _bodyMedium.copyWith(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatRoom chatRoom, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 20),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: _space16,
                vertical: _space8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radiusLarge),
                boxShadow: _shadowSmall,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_radiusLarge),
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
                  child: Padding(
                    padding: const EdgeInsets.all(_space16),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: chatRoom.displayAvatar == null
                                    ? LinearGradient(
                                        colors: [_primaryColor, _primaryLight],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: chatRoom.displayAvatar != null
                                    ? Image.network(
                                        chatRoom.displayAvatar!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          chatRoom.displayName.isNotEmpty
                                              ? chatRoom.displayName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: _space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chatRoom.displayName,
                                      style: _bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(chatRoom.updatedAt),
                                    style: _captionLarge.copyWith(
                                      color: _textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chatRoom.lastMessage.isNotEmpty
                                    ? chatRoom.lastMessage
                                    : 'Belum ada chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _bodyMedium.copyWith(
                                  color: chatRoom.lastMessage.isNotEmpty
                                      ? _textSecondary
                                      : _textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: _surfaceColor,
      child: RefreshIndicator(
        onRefresh: _loadChatRooms,
        color: _primaryColor,
        backgroundColor: Colors.white,
        child: ListView.builder(
          itemCount: chatRooms.length,
          padding: const EdgeInsets.only(top: _space8, bottom: _space16),
          itemBuilder: (context, index) {
            return _buildChatItem(chatRooms[index], index);
          },
        ),
      ),
    );
  }
}
