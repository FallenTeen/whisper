import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static WebSocketChannel? _channel;
  static StreamSubscription? _webSocketSubscription;
  static Function(Message)? _onNewMessageReceived;
  static int? _activeRoomId;
  static Timer? _reconnectTimer;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

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

  static List<Message> _sortMessagesProperly(List<Message> messages) {
    messages.sort((a, b) {
      final idComparison = a.id.compareTo(b.id);
      if (idComparison != 0) {
        return idComparison;
      }

      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }

      return 0;
    });

    return messages;
  }

  static Future<List<Message>> getMessages(int roomId, {int page = 1}) async {
    try {
      final url = '${ApiConstants.getChatMessagesUrl(roomId)}?page=$page';
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Message> messages = (data['data'] as List)
            .map((message) => Message.fromJson(message))
            .toList();
        messages = _sortMessagesProperly(messages);

        print('Fetched ${messages.length} messages for room $roomId');
        print(
          'Message IDs (chronological): ${messages.map((m) => m.id).join(', ')}',
        );
        return messages;
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get messages error: $e');
    }
  }

  static Future<void> connectWebSocket(
    int roomId,
    Function(Message) onNewMessage,
  ) async {
    if (_channel != null && _activeRoomId == roomId) {
      print('WebSocket already connected for room $roomId');
      _onNewMessageReceived = onNewMessage;
      return;
    }

    disconnectWebSocket();

    _activeRoomId = roomId;
    _onNewMessageReceived = onNewMessage;
    _reconnectAttempts = 0;

    await _connectWebSocketInternal();
  }

  static Future<void> _connectWebSocketInternal() async {
    if (_activeRoomId == null) return;

    try {
      final token = await ApiService.getToken();
      final wsUrl = Uri.parse(
        '${ApiConstants.wsBaseUrl}/chat/$_activeRoomId?token=$token',
      );

      _channel = WebSocketChannel.connect(wsUrl);
      print('Attempting to connect WebSocket to $wsUrl');

      _webSocketSubscription = _channel!.stream.listen(
        (messageEvent) {
          print('WebSocket message received: $messageEvent');
          _reconnectAttempts = 0;
          try {
            final Map<String, dynamic> data = json.decode(messageEvent);
            if (data['event'] == 'new_message') {
              final Message newMessage = Message.fromJson(data['data']);
              if (newMessage.roomId == _activeRoomId) {
                _onNewMessageReceived?.call(newMessage);
              }
            }
          } catch (e) {
            print('Error decoding WebSocket message: $e');
          }
        },
        onDone: () {
          print('WebSocket disconnected (onDone)');
          _handleWebSocketDisconnection();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleWebSocketDisconnection();
        },
        cancelOnError: true,
      );
      print('WebSocket connected for room $_activeRoomId');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _handleWebSocketDisconnection();
    }
  }

  static void _handleWebSocketDisconnection() {
    if (_activeRoomId != null &&
        _reconnectAttempts < _maxReconnectAttempts &&
        _onNewMessageReceived != null) {
      _reconnectAttempts++;
      print('Attempting to reconnect WebSocket (attempt $_reconnectAttempts)');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(
        Duration(seconds: _reconnectAttempts * 2),
        () => _connectWebSocketInternal(),
      );
    } else {
      disconnectWebSocket();
    }
  }

  static void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    _channel?.sink.close();
    _channel = null;
    _activeRoomId = null;
    _onNewMessageReceived = null;
    _reconnectAttempts = 0;
    print('WebSocket disconnected');
  }

  static Future<Message> sendMessage(
    int roomId,
    String content, {
    bool encrypt = false,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConstants.getSendMessageUrl(roomId),
        {'content': content, 'encrypt': encrypt},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final message = Message.fromJson(data['data']);
        print(
          'Message sent successfully via HTTP POST. Awaiting WebSocket broadcast.',
        );
        return message;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
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

  static Future<List<ChatRoom>> getChatRooms() async {
    try {
      final response = await ApiService.get(ApiConstants.chatRoomsUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chatRooms = (data['data'] as List)
            .map((chatRoom) => ChatRoom.fromJson(chatRoom))
            .toList();
        print('Fetched ${chatRooms.length} chat rooms');
        return chatRooms;
      } else {
        throw Exception('Failed to fetch chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Get chat rooms error: $e');
      throw Exception('Get chat rooms error: $e');
    }
  }

  static Future<void> clearRoomKey(int roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('room_key_$roomId');
      print('Room key cleared for room $roomId');
    } catch (e) {
      print('Error clearing room key: $e');
    }
  }

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
