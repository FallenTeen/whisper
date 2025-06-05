import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _loading = false;
  String? _error;

  List<Message> get messages => _messages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMessages(int roomId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await ChatService.getMessages(roomId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> decryptAllMessages(int roomId) async {
    return;
  }

  Future<void> sendMessage(
    int roomId,
    String content, {
    bool encrypt = false,
  }) async {
    try {
      final message = await ChatService.sendMessage(
        roomId,
        content,
        encrypt: encrypt,
      );
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clear() {
    _messages = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
