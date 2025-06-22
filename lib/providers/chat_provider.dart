import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _loading = false;
  String? _error;
  int? _currentRoomId;

  int _optimisticMessageIdCounter = -1;

  List<Message> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  ChatProvider();

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
      if (a.id < 0 && b.id < 0) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      if (a.id < 0) return 1;
      if (b.id < 0) return -1;

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

  void _onNewMessageFromWebSocket(Message newMessage) {
    int existingIndex = _messages.indexWhere(
      (msg) =>
          msg.id < 0 &&
          msg.senderId == newMessage.senderId &&
          msg.content == newMessage.content &&
          msg.createdAt != null &&
          msg.createdAt!.isBefore(
            newMessage.createdAt.add(const Duration(seconds: 5)),
          ),
    );

    if (existingIndex != -1) {
      _messages[existingIndex] = newMessage;
      print(
        'ChatProvider: Mengganti pesan optimistik dengan pesan server: ${newMessage.id}',
      );
    } else {
      bool messageExists = _messages.any((msg) => msg.id == newMessage.id);
      if (!messageExists) {
        _messages.add(newMessage);
        print('ChatProvider: Pesan baru diterima via WS: ${newMessage.id}');
      } else {
        print(
          'ChatProvider: Pesan duplikat diterima via WS: ${newMessage.id}. Melewati.',
        );
      }
    }

    _sortMessages();
    notifyListeners();
  }

  Future<void> addOptimisticMessage(Message message) async {
    _messages.add(message);
    _sortMessages();
    notifyListeners();
  }

  void removeOptimisticMessage(int optimisticId) {
    _messages.removeWhere((msg) => msg.id == optimisticId);
    _sortMessages();
    notifyListeners();
  }

  Future<void> fetchMessages(int roomId) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_currentRoomId != null && _currentRoomId != roomId) {
        ChatService.disconnectWebSocket();
      }
      _currentRoomId = roomId;
      final fetchedMessages = await ChatService.getMessages(roomId);
      _messages = List.from(fetchedMessages);
      _sortMessages();

      print(
        'ChatProvider: Memuat ${_messages.length} pesan untuk room $roomId',
      );
      print('Message IDs: ${_messages.map((m) => m.id).join(', ')}');
      await ChatService.connectWebSocket(roomId, _onNewMessageFromWebSocket);
    } catch (e) {
      _setError(e.toString());
      print('ChatProvider error saat fetch: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage(
    int roomId,
    String content, {
    bool encrypt = false,
    required int senderId,
  }) async {
    _setError(null);

    final optimisticMessage = Message(
      id: _optimisticMessageIdCounter--,
      roomId: roomId,
      senderId: senderId,
      content: content,
      isEncrypted: encrypt,
      createdAt: DateTime.now(),
      decryptedContent: encrypt ? null : content,
    );

    await addOptimisticMessage(optimisticMessage);

    try {
      await ChatService.sendMessage(roomId, content, encrypt: encrypt);
      print(
        'ChatProvider: Pengiriman pesan dimulai. Menunggu broadcast WebSocket untuk pembaruan.',
      );

      await Future.delayed(const Duration(seconds: 2));

      bool wasReplaced = _messages.any(
        (msg) =>
            msg.id > 0 &&
            msg.senderId == senderId &&
            msg.content == content &&
            msg.createdAt!.isAfter(
              optimisticMessage.createdAt!.subtract(const Duration(seconds: 1)),
            ),
      );

      if (!wasReplaced) {
        await refreshMessages();
      }
    } catch (e) {
      removeOptimisticMessage(optimisticMessage.id);
      _setError('Gagal mengirim pesan: $e');
      print('ChatProvider error saat kirim: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    ChatService.disconnectWebSocket();
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
    ChatService.disconnectWebSocket();
    _currentRoomId = null;
    notifyListeners();
  }
}
