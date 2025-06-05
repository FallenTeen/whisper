class ChatRoom {
  final int id;
  final String name;
  final String lastMessage;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      lastMessage: json['last_message'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
