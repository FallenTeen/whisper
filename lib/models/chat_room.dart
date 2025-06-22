import 'user.dart';

class ChatRoom {
  final int id;
  final String originalName;
  final String displayName;
  final String type;
  final String? displayAvatar;
  final String lastMessage;
  final DateTime updatedAt;
  final List<User> members;

  ChatRoom({
    required this.id,
    required this.originalName,
    required this.displayName,
    required this.type,
    this.displayAvatar,
    required this.lastMessage,
    required this.updatedAt,
    required this.members,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    print('DEBUG: ChatRoom.fromJson input: $json');

    List<User> membersList = [];
    if (json['members'] != null) {
      try {
        membersList = (json['members'] as List<dynamic>)
            .map(
              (memberJson) => User.fromJson(memberJson as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        print('DEBUG: Error parsing members: $e');
        membersList = [];
      }
    }
    String lastMessageContent = '';
    if (json['latest_message'] != null &&
        json['latest_message']['content'] != null) {
      lastMessageContent = json['latest_message']['content'] as String;
    } else if (json['last_message'] != null) {
      lastMessageContent = json['last_message'] as String? ?? '';
    }
    int id = json['id'] as int? ?? -1;
    String originalName = json['name'] as String? ?? 'Unknown Chat';
    String displayName =
        json['display_name'] as String? ??
        json['name'] as String? ??
        'Unknown Chat';
    String type = json['type'] as String? ?? 'private';
    String? displayAvatar = json['display_avatar'] as String?;

    DateTime updatedAt;
    try {
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at'] as String);
      } else {
        updatedAt = DateTime.now();
      }
    } catch (e) {
      print('DEBUG: Error parsing updated_at: $e');
      updatedAt = DateTime.now();
    }

    return ChatRoom(
      id: id,
      originalName: originalName,
      displayName: displayName,
      type: type,
      displayAvatar: displayAvatar,
      lastMessage: lastMessageContent,
      updatedAt: updatedAt,
      members: membersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': originalName,
      'display_name': displayName,
      'type': type,
      'display_avatar': displayAvatar,
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
      'members': members.map((member) => member.toJson()).toList(),
    };
  }
}
