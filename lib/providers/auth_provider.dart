import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  Future<void> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await AuthService.login(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      await AuthService.register(name, username, email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }
}
