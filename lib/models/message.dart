import 'dart:convert';

class Message {
  final int id;
  final int roomId;
  final int senderId;
  final String content;
  final bool isEncrypted;
  final DateTime createdAt;
  final String? decryptedContent;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.isEncrypted,
    required this.createdAt,
    this.decryptedContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? -1,
      roomId: json['room_id'] ?? -1,
      senderId: json['sender_id'] ?? (json['user']?['id'] ?? -1),
      content: json['content'] ?? '',
      isEncrypted: json['is_encrypted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      decryptedContent: json['decrypted_content'],
    );
  }
}
