import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String text, bool encrypt) onSendMessage;
  final bool whisperMode;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    this.whisperMode = false,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEncryptEnabled = false;
  bool _isSending = false;
  late AnimationController _pulseController;
  late AnimationController _encryptionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _encryptionScaleAnimation;

  // Design System Constants
  static const _primaryColor = Color(0xFF6366F1);
  static const _primaryLight = Color(0xFF818CF8);
  static const _primaryDark = Color(0xFF4F46E5);

  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _surfaceSecondary = Color(0xFFF1F5F9);

  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);

  static const _encryptedColor = Color(0xFF7C3AED);
  static const _encryptedLight = Color(0xFFA855F7);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);

  // Typography
  static const _bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const _bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const _captionLarge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // Spacing
  static const double _space4 = 4.0;
  static const double _space8 = 8.0;
  static const double _space12 = 12.0;
  static const double _space16 = 16.0;
  static const double _space20 = 20.0;
  static const double _space24 = 24.0;

  // Border Radius
  static const double _radiusMedium = 8.0;
  static const double _radiusLarge = 12.0;
  static const double _radiusXLarge = 16.0;

  // Shadows
  static final List<BoxShadow> _shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> _shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for whisper mode
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scale animation for encryption toggle
    _encryptionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _encryptionScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _encryptionController, curve: Curves.elasticOut),
    );

    if (widget.whisperMode) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.whisperMode && !oldWidget.whisperMode) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.whisperMode && oldWidget.whisperMode) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _encryptionController.dispose();
    super.dispose();
  }

  void _toggleEncryption() {
    setState(() {
      _isEncryptEnabled = !_isEncryptEnabled;
    });

    // Trigger scale animation
    _encryptionController.forward().then((_) {
      _encryptionController.reverse();
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSendMessage(text, _isEncryptEnabled);
      _controller.clear();
      setState(() {
        _isEncryptEnabled = false;
      });
    } catch (e) {
      // Error handling is done in parent widget
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          top: BorderSide(color: _textTertiary.withOpacity(0.1), width: 1),
        ),
        boxShadow: _shadowMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced encryption status indicator
          if (widget.whisperMode || _isEncryptEnabled)
            _buildEncryptionIndicator(),

          // Main input area
          Padding(
            padding: const EdgeInsets.all(_space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Encryption toggle button (only show when not in whisper mode)
                if (!widget.whisperMode) _buildEncryptionToggle(),

                // Text input field
                Expanded(child: _buildTextInput()),

                SizedBox(width: _space12),

                // Send button
                _buildSendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(_space16, _space12, _space16, 0),
      padding: const EdgeInsets.all(_space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isEncryptEnabled
              ? [
                  _encryptedColor.withOpacity(0.08),
                  _encryptedLight.withOpacity(0.12),
                ]
              : [
                  _warningColor.withOpacity(0.08),
                  _warningColor.withOpacity(0.12),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_radiusXLarge),
        border: Border.all(
          color: _isEncryptEnabled
              ? _encryptedColor.withOpacity(0.2)
              : _warningColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: _shadowSmall,
      ),
      child: Row(
        children: [
          // Animated lock icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.whisperMode ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(_space8),
                  decoration: BoxDecoration(
                    color: _isEncryptEnabled
                        ? _encryptedColor.withOpacity(0.15)
                        : _warningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_radiusLarge),
                  ),
                  child: Icon(
                    _isEncryptEnabled
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    size: 18,
                    color: _isEncryptEnabled ? _encryptedColor : _warningColor,
                  ),
                ),
              );
            },
          ),

          SizedBox(width: _space12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEncryptEnabled ? 'WHISPERED! 🤫' : 'Normal Chat 💬',
                  style: _captionLarge.copyWith(
                    color: _isEncryptEnabled ? _encryptedColor : _warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _space4),
                Text(
                  _isEncryptEnabled
                      ? 'Pesan akan dikirim terenkripsi'
                      : 'Pesan akan dikirim biasa aja',
                  style: _bodySmall.copyWith(
                    color: _isEncryptEnabled
                        ? _encryptedColor.withOpacity(0.8)
                        : _warningColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Toggle switch
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_space20),
              color: Colors.white.withOpacity(0.8),
              boxShadow: _shadowSmall,
            ),
            child: Switch(
              value: _isEncryptEnabled,
              onChanged: (value) => _toggleEncryption(),
              activeColor: _encryptedColor,
              inactiveThumbColor: _warningColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionToggle() {
    return Container(
      margin: EdgeInsets.only(right: _space12, bottom: _space4),
      child: AnimatedBuilder(
        animation: _encryptionScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _encryptionScaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _isEncryptEnabled
                    ? _encryptedColor.withOpacity(0.1)
                    : _surfaceSecondary,
                borderRadius: BorderRadius.circular(_radiusXLarge),
                border: Border.all(
                  color: _isEncryptEnabled
                      ? _encryptedColor.withOpacity(0.3)
                      : _textTertiary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: _shadowSmall,
              ),
              child: IconButton(
                onPressed: _toggleEncryption,
                icon: Icon(
                  _isEncryptEnabled
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  color: _isEncryptEnabled ? _encryptedColor : _textSecondary,
                  size: 20,
                ),
                tooltip: _isEncryptEnabled
                    ? 'Matikan enkripsi'
                    : 'Aktifkan enkripsi',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(_radiusXLarge * 1.5),
        border: Border.all(
          color: _isEncryptEnabled
              ? _encryptedColor.withOpacity(0.2)
              : _textTertiary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: _shadowSmall,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: _isEncryptEnabled
              ? 'Ketik pesan rahasia... 🤫'
              : 'Ketik pesan...',
          hintStyle: _bodyMedium.copyWith(color: _textTertiary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: _space20,
            vertical: _space16,
          ),
          prefixIcon: _isEncryptEnabled
              ? Padding(
                  padding: EdgeInsets.only(left: _space8),
                  child: Icon(
                    Icons.security_rounded,
                    color: _encryptedColor,
                    size: 18,
                  ),
                )
              : null,
        ),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _sendMessage(),
        enabled: !_isSending,
        style: _bodyMedium.copyWith(color: _textPrimary),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSending
              ? [_textTertiary, _textTertiary.withOpacity(0.8)]
              : (_isEncryptEnabled
                    ? [_encryptedColor, _encryptedLight]
                    : [_primaryColor, _primaryLight]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_space20),
        boxShadow: _isSending
            ? []
            : [
                BoxShadow(
                  color: (_isEncryptEnabled ? _encryptedColor : _primaryColor)
                      .withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSending ? null : _sendMessage,
          borderRadius: BorderRadius.circular(_space20),
          child: Container(
            width: 48,
            height: 48,
            child: _isSending
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
