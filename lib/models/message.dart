class Message {
  final int id;
  final int senderId;
  final String content;
  final bool isEncrypted;
  final DateTime createdAt;
  final String? decryptedContent;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.isEncrypted,
    required this.createdAt,
    this.decryptedContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Message.fromJson input: $json');
    int senderId = json['sender_id'] ?? (json['user']?['id'] ?? -1);
    return Message(
      id: json['id'] ?? -1,
      senderId: senderId,
      content: json['content'] ?? '',
      isEncrypted: json['is_encrypted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      decryptedContent: json['decrypted_content'],
    );
  }
}
