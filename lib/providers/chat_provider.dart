import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _loading = false;
  String? _error;
  int? _currentRoomId;

  List<Message> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final idComparison = a.id.compareTo(b.id);
      if (idComparison != 0) {
        return idComparison;
      }
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }

      return 0;
    });
  }

  Future<void> fetchMessages(int roomId) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_currentRoomId != null && _currentRoomId != roomId) {
        ChatService.stopMessagePolling();
      }
      final fetchedMessages = await ChatService.getMessages(roomId);
      _messages = List.from(fetchedMessages);
      _sortMessages();
      _currentRoomId = roomId;

      print(
        'ChatProvider: Loaded ${_messages.length} messages for room $roomId',
      );
      print('Message IDs: ${_messages.map((m) => m.id).join(', ')}');
      ChatService.startMessagePolling(roomId, _onMessagesUpdated);
    } catch (e) {
      _setError(e.toString());
      print('ChatProvider fetch error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _onMessagesUpdated(List<Message> updatedMessages) {
    print('ChatProvider: Received ${updatedMessages.length} updated messages');
    _messages = List.from(updatedMessages);
    _sortMessages();

    print(
      'ChatProvider: Updated message IDs: ${_messages.map((m) => m.id).join(', ')}',
    );
    notifyListeners();
  }

  Future<void> sendMessage(
    int roomId,
    String content, {
    bool encrypt = false,
  }) async {
    try {
      _setError(null);

      final sentMessage = await ChatService.sendMessage(
        roomId,
        content,
        encrypt: encrypt,
      );

      print('ChatProvider: Message sent with ID ${sentMessage.id}');
    } catch (e) {
      _setError('Failed to send message: $e');
      print('ChatProvider send error: $e');
      rethrow;
    }
  }

  void dispose() {
    ChatService.stopMessagePolling();
    super.dispose();
  }

  Future<void> refreshMessages() async {
    if (_currentRoomId != null) {
      await fetchMessages(_currentRoomId!);
    }
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    _loading = false;
    ChatService.stopMessagePolling();
    _currentRoomId = null;
    notifyListeners();
  }
}
