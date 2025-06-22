import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';

class ChatRoomsProvider with ChangeNotifier {
  List<ChatRoom> _chatRooms = [];
  bool _loading = false;
  String? _error;

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchChatRooms() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _chatRooms = await ChatService.getChatRooms();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<ChatRoom> createPrivateChat(int userId) async {
    try {
      final chatRoom = await ChatService.createPrivateChat(userId);

      // Add to list if not already exists
      if (!_chatRooms.any((room) => room.id == chatRoom.id)) {
        _chatRooms.insert(0, chatRoom);
        notifyListeners();
      }

      return chatRoom;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void updateChatRoom(ChatRoom updatedRoom) {
    final index = _chatRooms.indexWhere((room) => room.id == updatedRoom.id);
    if (index != -1) {
      _chatRooms[index] = updatedRoom;
      // Move to top when updated
      _chatRooms.removeAt(index);
      _chatRooms.insert(0, updatedRoom);
      notifyListeners();
    }
  }

  void clear() {
    _chatRooms = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
