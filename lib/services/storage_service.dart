import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles saving/loading user data from device storage.
/// This survives app close, kill, and device restart.
class StorageService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save user to device storage after login/signup
  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userMap));
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Load saved user from device storage
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;
    return jsonDecode(userString) as Map<String, dynamic>;
  }

  /// Check if user was logged in before app was closed
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Clear everything on logout
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
  }
}
