import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:splitzon/model/user.dart';
import 'package:splitzon/services/storage_service.dart';

class UserProviders extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  // ✅ Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  /// Called from splash screen on every app open.
  /// Checks SharedPreferences to restore session.
  /// Returns true → go to home, false → go to onboarding
  Future<bool> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user was logged in before app closed
      final loggedIn = await StorageService.isLoggedIn();

      if (loggedIn) {
        // Load saved user data from device storage
        final userMap = await StorageService.getUser();
        if (userMap != null) {
          _user = User.fromMap(userMap);
          _isLoading = false;
          notifyListeners();
          return true; // ✅ go to home
        }
      }

      // No saved session found
      _isLoading = false;
      notifyListeners();
      return false; // ❌ go to onboarding
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Called after OTP success (signup or login).
  /// Saves user to RAM + device storage.
  Future<void> setAuthenticated(Map<String, dynamic> userMap) async {
    _user = User.fromMap(userMap);

    // ✅ Save to device storage — this is what persists across app kills
    await StorageService.saveUser(userMap);

    notifyListeners();
  }

  /// Set user from map (kept for compatibility)
  Future<void> setUserFromMap(Map<String, dynamic> map) async {
    await setAuthenticated(map); // ← now calls setAuthenticated
  }

  /// Full logout — clears RAM + device storage + Firebase session
  Future<void> logout() async {
    // Clear RAM
    _user = null;

    // Clear device storage
    await StorageService.clearAll();

    // Clear Firebase session
    await fb.FirebaseAuth.instance.signOut();

    notifyListeners();
  }

  /// Legacy method kept for compatibility
  void clearUser() {
    logout(); // ← now calls full logout
  }
}

// import 'package:flutter/material.dart';
// import 'package:splitzon/model/user.dart';

// class UserProviders extends ChangeNotifier {
//   User? _user; // ← nullable, null means not logged in

//   User? get user => _user;
//   bool get isLoggedIn => _user != null;

//   // ✅ Set user from Map (from API response)
//   void setUserFromMap(Map<String, dynamic> map) {
//     _user = User.fromMap(map);
//     notifyListeners();
//   }

//   // ✅ Clear user on logout
//   void clearUser() {
//     _user = null;
//     notifyListeners();
//   }
// }
