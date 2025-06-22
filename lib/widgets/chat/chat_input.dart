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
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced encryption status indicator
          if (widget.whisperMode || _isEncryptEnabled)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isEncryptEnabled
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.orange.shade50, Colors.orange.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isEncryptEnabled
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isEncryptEnabled ? Colors.green : Colors.orange)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.whisperMode ? _pulseAnimation.value : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isEncryptEnabled
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isEncryptEnabled
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            size: 20,
                            color: _isEncryptEnabled
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEncryptEnabled
                              ? 'WHISPERED! 🤫'
                              : 'Normal Chat 💬',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isEncryptEnabled
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEncryptEnabled
                              ? 'Pesan akan dikirim terenkripsi'
                              : 'Pesan akan dikirim biasa aja',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isEncryptEnabled
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.7),
                    ),
                    child: Switch(
                      value: _isEncryptEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEncryptEnabled = value;
                        });
                      },
                      activeColor: Colors.green.shade600,
                      inactiveThumbColor: Colors.orange.shade600,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!widget.whisperMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _isEncryptEnabled
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isEncryptEnabled
                            ? Colors.green.withOpacity(0.3)
                            : colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isEncryptEnabled = !_isEncryptEnabled;
                        });
                      },
                      icon: Icon(
                        _isEncryptEnabled
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: _isEncryptEnabled
                            ? Colors.green.shade600
                            : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      tooltip: _isEncryptEnabled
                          ? 'Matikan enkripsi'
                          : 'Aktifkan enkripsi',
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isEncryptEnabled
                            ? Colors.green.withOpacity(0.3)
                            : colorScheme.outline.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: _isEncryptEnabled
                            ? 'Ketik pesan rahasia... 🤫'
                            : 'Ketik pesan...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: _isEncryptEnabled
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.security_rounded,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                              )
                            : null,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSending
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : (_isEncryptEnabled
                                ? [Colors.green.shade500, Colors.green.shade600]
                                : [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isEncryptEnabled
                                    ? Colors.green
                                    : colorScheme.primary)
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: 48,
                        child: _isSending
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(
                                _isEncryptEnabled
                                    ? Icons.send_rounded
                                    : Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
