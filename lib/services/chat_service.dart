import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static Future<void> ensureRoomKey(int roomId) async {
    try {
      final response = await ApiService.get(
        '${ApiConstants.chatRoomsUrl}/$roomId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data']['key'] != null) {
          await saveRoomKey(roomId, data['data']['key']);
          print('Room key saved for room $roomId');
        }
      }
    } catch (e) {
      print('Error ensuring room key: $e');
    }
  }

  static Future<void> saveRoomKey(int roomId, String base64Key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('room_key_$roomId', base64Key);
      print('Room key saved successfully for room $roomId');
    } catch (e) {
      print('Error saving room key: $e');
    }
  }

  static Future<String?> getRoomKey(int roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('room_key_$roomId');
      if (key != null) {
        print('Room key found for room $roomId');
      } else {
        print('No room key found for room $roomId');
      }
      return key;
    } catch (e) {
      print('Error getting room key: $e');
      return null;
    }
  }

  static Future<List<Message>> getMessages(int roomId, {int page = 1}) async {
    try {
      final url = '${ApiConstants.getChatMessagesUrl(roomId)}?page=$page';
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = (data['data'] as List)
            .map((message) => Message.fromJson(message))
            .toList();

        print('Fetched ${messages.length} messages for room $roomId');

        return messages;
      } else {
        throw Exception('Failed to fetch messages: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get messages error: $e');
    }
  }

  static Future<Message> sendMessage(
    int roomId,
    String content, {
    bool encrypt = false,
  }) async {
    try {
      // Always send plain text; API will handle encryption if needed
      final response = await ApiService.post(
        ApiConstants.getSendMessageUrl(roomId),
        {'content': content, 'encrypt': encrypt},
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data['data']);
      } else {
        throw Exception('Failed to send message: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }

  static Future<ChatRoom> createPrivateChat(int userId) async {
    try {
      final response = await ApiService.post(
        ApiConstants.createPrivateChatUrl,
        {'user_id': userId},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final chatRoom = ChatRoom.fromJson(data['data']);

        // Save room key if provided
        final key = data['data']['key'] ?? data['data']['encryption_key'];
        if (key != null) {
          await saveRoomKey(chatRoom.id, key);
          print('Private chat created with encryption key');
        }

        return chatRoom;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create chat');
      }
    } catch (e) {
      print('Create private chat error: $e');
      throw Exception('Create private chat error: $e');
    }
  }

  static Future<List<User>> searchUsers(String query) async {
    try {
      final url =
          '${ApiConstants.searchUsersUrl}?query=${Uri.encodeComponent(query)}';
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = (data['data'] as List)
            .map((user) => User.fromJson(user))
            .toList();
        print('Found ${users.length} users for query: $query');
        return users;
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('Search users error: $e');
      throw Exception('Search users error: $e');
    }
  }

  // Helper method untuk membersihkan room key (jika diperlukan)
  static Future<void> clearRoomKey(int roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('room_key_$roomId');
      print('Room key cleared for room $roomId');
    } catch (e) {
      print('Error clearing room key: $e');
    }
  }

  // Helper method untuk mendapatkan semua room keys (untuk debugging)
  static Future<Map<int, String>> getAllRoomKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final roomKeys = <int, String>{};

      for (final key in keys) {
        if (key.startsWith('room_key_')) {
          final roomIdStr = key.substring('room_key_'.length);
          final roomId = int.tryParse(roomIdStr);
          if (roomId != null) {
            final roomKey = prefs.getString(key);
            if (roomKey != null) {
              roomKeys[roomId] = roomKey;
            }
          }
        }
      }

      print('Found ${roomKeys.length} room keys in storage');
      return roomKeys;
    } catch (e) {
      print('Error getting all room keys: $e');
      return {};
    }
  }
}
