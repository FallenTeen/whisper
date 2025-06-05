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

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEncryptEnabled = false;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
        _isEncryptEnabled = false; // Reset encryption toggle after sending
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encryption toggle
          if (widget.whisperMode || _isEncryptEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isEncryptEnabled
                    ? Colors.orange.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isEncryptEnabled
                      ? Colors.orange.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEncryptEnabled ? Icons.lock : Icons.lock_open,
                    size: 16,
                    color: _isEncryptEnabled
                        ? Colors.orange.shade700
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEncryptEnabled
                          ? 'Message will be encrypted'
                          : 'Message will be sent as plain text',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isEncryptEnabled
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isEncryptEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEncryptEnabled = value;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),

          // Message input
          Row(
            children: [
              // Encryption toggle button (when whisper mode is off)
              if (!widget.whisperMode)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEncryptEnabled = !_isEncryptEnabled;
                    });
                  },
                  icon: Icon(
                    _isEncryptEnabled ? Icons.lock : Icons.lock_open,
                    color: _isEncryptEnabled
                        ? Colors.orange
                        : Colors.grey.shade600,
                  ),
                  tooltip: _isEncryptEnabled
                      ? 'Disable encryption'
                      : 'Enable encryption',
                ),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isEncryptEnabled
                          ? Colors.orange.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _isEncryptEnabled
                          ? 'Type an encrypted message...'
                          : 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Container(
                decoration: BoxDecoration(
                  color: _isSending
                      ? Colors.grey.shade400
                      : (_isEncryptEnabled
                            ? Colors.orange
                            : Theme.of(context).primaryColor),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white),
                  tooltip: 'Send message',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
