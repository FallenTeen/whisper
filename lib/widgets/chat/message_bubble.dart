import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import '../../services/encryption_service.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final int roomId;
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.roomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors
                          .blue
                          .shade600 //Suleiman, this it sender buble color
                    : Colors.grey.shade300, // thsis is receiver bubble color
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: message.isEncrypted
                  ? FutureBuilder<String?>(
                      future: ChatService.getRoomKey(roomId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                '[Key not found]',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          );
                        }
                        try {
                          final decrypted = EncryptionService.decrypt(
                            message.content,
                            snapshot.data!,
                          );
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  decrypted,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } catch (_) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                '[Failed to decrypt]',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          );
                        }
                      },
                    )
                  : Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
