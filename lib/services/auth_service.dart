import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post(ApiConstants.loginUrl, {
        'email': email,
        'password': password,
      }, includeAuth: false);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_data', json.encode(data['user']));
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post(ApiConstants.registerUrl, {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      }, includeAuth: false);
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_data', json.encode(data['user']));
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConstants.logoutUrl, {});
    } catch (e) {
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<bool> validatePassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson == null) {
        throw Exception('User data not found');
      }

      final userMap = json.decode(userJson);
      final userEmail = userMap['email'];

      // Validate password using login endpoint
      final response = await ApiService.post(ApiConstants.loginUrl, {
        'email': userEmail,
        'password': password,
      }, includeAuth: false);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
