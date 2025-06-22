import 'package:flutter/material.dart';
import '../../models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final int roomId;
  final bool whisperMode;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.roomId,
    required this.whisperMode,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _encryptedColor = Color(0xFF7C3AED);
  static const _successColor = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    if (widget.message.isEncrypted && !widget.whisperMode) {
      _shimmerController.repeat();
    }

    _scaleController.forward();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.isEncrypted && !widget.whisperMode) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    } else {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  minWidth: 60,
                ),
                decoration: BoxDecoration(
                  color: _getMessageColor(),
                  borderRadius: _getBorderRadius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: _buildMessageContent(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildMessageMeta(),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: widget.isMe
          ? const Radius.circular(16)
          : const Radius.circular(4),
      bottomRight: widget.isMe
          ? const Radius.circular(4)
          : const Radius.circular(16),
    );
  }

  Color _getMessageColor() {
    if (widget.message.isEncrypted) {
      return _encryptedColor;
    }
    return widget.isMe ? _primaryColor : _surfaceColor;
  }

  Widget _buildMessageMeta() {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.isMe ? 0 : 8,
        right: widget.isMe ? 8 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.isEncrypted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.whisperMode
                    ? _successColor.withOpacity(0.15)
                    : _encryptedColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.whisperMode
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 10,
                    color: widget.whisperMode ? _successColor : _encryptedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.whisperMode ? 'DECRYPTED' : 'ENCRYPTED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: widget.whisperMode
                          ? _successColor
                          : _encryptedColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _formatTime(widget.message.createdAt),
            style: const TextStyle(
              fontSize: 10,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.isMe) ...[
            const SizedBox(width: 4),
            Icon(Icons.done_all_rounded, size: 10, color: _primaryLight),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    if (!widget.message.isEncrypted) {
      return _buildPlainMessage();
    }

    if (widget.whisperMode &&
        widget.message.decryptedContent != null &&
        widget.message.decryptedContent!.isNotEmpty) {
      return _buildDecryptedMessage();
    }

    return _buildEncryptedMessage();
  }

  Widget _buildPlainMessage() {
    return Text(
      widget.message.content,
      style: TextStyle(
        color: widget.isMe ? Colors.white : _textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildDecryptedMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 11,
                color: Colors.white.withOpacity(0.95),
              ),
              const SizedBox(width: 4),
              Text(
                'Decrypted',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Text(
          widget.message.decryptedContent!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptedMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(
                      0.8 + (_shimmerAnimation.value * 0.2).abs(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                'Encrypted Message',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Enable whisper mode to decrypt',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
