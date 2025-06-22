import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/chat_service.dart';

class ContactsProvider with ChangeNotifier {
  List<User> _contacts = [];
  bool _loading = false;
  String? _error;

  List<User> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchContacts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all users as contacts
      _contacts = await ChatService.searchUsers('');
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<List<User>> searchContacts(String query) async {
    try {
      if (query.isEmpty) {
        return _contacts;
      }

      final searchResults = await ChatService.searchUsers(query);
      return searchResults;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clear() {
    _contacts = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
