import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/encryption_service.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static Future<void> ensureRoomKey(int roomId) async {
    final response = await ApiService.get(
      '${ApiConstants.chatRoomsUrl}/$roomId',
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data']['key'] != null) {
        await saveRoomKey(roomId, data['data']['key']);
      }
    }
  }

  static Future<void> saveRoomKey(int roomId, String base64Key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_key_$roomId', base64Key);
  }

  static Future<String?> getRoomKey(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('room_key_$roomId');
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

        // Decrypt encrypted messages
        final roomKey = await getRoomKey(roomId);
        if (roomKey != null) {
          for (var message in messages) {
            if (message.isEncrypted && message.decryptedContent == null) {
              try {
                print('Attempting to decrypt message ${message.id}');
                print('Encrypted content: ${message.content}');
                EncryptionService.debugEncryptedData(message.content);

                final decrypted = EncryptionService.decrypt(
                  message.content,
                  roomKey,
                );
                // Update message dengan decrypted content
                // Note: Ini hanya untuk tampilan, tidak mengubah data di server
                print('Decryption successful: $decrypted');
              } catch (e) {
                print('Failed to decrypt message ${message.id}: $e');
                // Biarkan pesan tetap dalam bentuk encrypted
              }
            }
          }
        }

        return messages;
      } else {
        throw Exception('Failed to fetch messages');
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
      String finalContent = content;

      // Encrypt jika diminta
      if (encrypt) {
        final roomKey = await getRoomKey(roomId);
        if (roomKey != null) {
          try {
            finalContent = EncryptionService.encrypt(content, roomKey);
            print('Message encrypted successfully');
            print('Original: $content');
            print('Encrypted: $finalContent');
          } catch (e) {
            print('Encryption failed: $e');
            throw Exception('Failed to encrypt message: $e');
          }
        } else {
          throw Exception('No encryption key found for room $roomId');
        }
      }

      final response = await ApiService.post(
        ApiConstants.getSendMessageUrl(roomId),
        {'content': finalContent, 'encrypt': encrypt},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }

  static Future<ChatRoom> createPrivateChat(int userId) async {
    final response = await ApiService.post(ApiConstants.createPrivateChatUrl, {
      'user_id': userId,
    });
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final key = data['data']['key'] ?? data['data']['encryption_key'];
      if (key != null) {
        await saveRoomKey(data['data']['id'], key);
      }
      return ChatRoom.fromJson(data['data']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to create chat');
    }
  }

  static Future<List<User>> searchUsers(String query) async {
    try {
      final url = '${ApiConstants.searchUsersUrl}?query=$query';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((user) => User.fromJson(user))
            .toList();
      } else {
        throw Exception('Failed to search users');
      }
    } catch (e) {
      throw Exception('Search users error: $e');
    }
  }
}
