// ════════════════════════════════════════════════════════════════
// FILE: lib/provider/user_providers.dart
// ════════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:splitzon/model/user.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/services/storage_service.dart';

class UserProviders extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // ── INIT ON APP START ─────────────────────────────────────
  Future<bool> initAuth(
    GroupProvider groupProvider,
    ExpenseProvider expenseProvider,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await StorageService.isLoggedIn();
      if (loggedIn) {
        final userMap = await StorageService.getUser();
        final savedToken = await StorageService.getToken();

        if (userMap != null) {
          _user = User.fromMap(userMap);
          if (savedToken != null && savedToken.isNotEmpty) {
            _token = savedToken;
            groupProvider.setAuthToken(savedToken);
            groupProvider.setUserId(_user!.id);
            // ← also set on expense provider
            expenseProvider.setAuthToken(savedToken);
            expenseProvider.setUserId(_user!.id);
            debugPrint('✅ Session restored for user: ${_user!.id}');
          }
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── SET AFTER LOGIN / SIGNUP ──────────────────────────────
  Future<void> setAuthenticated(
    Map<String, dynamic> userMap,
    String token,
    GroupProvider groupProvider,
    ExpenseProvider expenseProvider,
  ) async {
    _user = User.fromMap(userMap);
    _token = token;

    await StorageService.saveUser(userMap);
    await StorageService.saveToken(token);

    groupProvider.setAuthToken(token);
    groupProvider.setUserId(_user!.id);
    // ← also set on expense provider
    expenseProvider.setAuthToken(token);
    expenseProvider.setUserId(_user!.id);

    debugPrint('✅ Authenticated user: ${_user!.id}');
    notifyListeners();
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout(
    GroupProvider groupProvider,
    ExpenseProvider expenseProvider,
  ) async {
    await groupProvider.clearForLogout();
    expenseProvider.clearForLogout(); // ← clear expense data too

    _user = null;
    _token = null;
    await StorageService.clearAll();
    await fb.FirebaseAuth.instance.signOut();

    notifyListeners();
  }
}

// import 'package:firebase_auth/firebase_auth.dart' as fb;
// import 'package:flutter/material.dart';
// import 'package:splitzon/model/user.dart';
// import 'package:splitzon/providers/group_provider.dart';
// import 'package:splitzon/services/storage_service.dart';

// class UserProviders extends ChangeNotifier {
//   User? _user;
//   String? _token;
//   bool _isLoading = false;

//   User? get user => _user;
//   String? get token => _token;
//   bool get isLoading => _isLoading;
//   bool get isLoggedIn => _user != null;

//   Future<bool> initAuth(GroupProvider groupProvider) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final loggedIn = await StorageService.isLoggedIn();
//       if (loggedIn) {
//         final userMap = await StorageService.getUser();
//         final savedToken = await StorageService.getToken();

//         if (userMap != null) {
//           _user = User.fromMap(userMap);
//           if (savedToken != null && savedToken.isNotEmpty) {
//             _token = savedToken;
//             groupProvider.setAuthToken(savedToken);
//             groupProvider.setUserId(_user!.id); // ← NEW
//             debugPrint('✅ Session restored for user: ${_user!.id}');
//           }
//           _isLoading = false;
//           notifyListeners();
//           return true;
//         }
//       }
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   Future<void> setAuthenticated(
//     Map<String, dynamic> userMap,
//     String token,
//     GroupProvider groupProvider,
//   ) async {
//     _user = User.fromMap(userMap);
//     _token = token;

//     await StorageService.saveUser(userMap);
//     await StorageService.saveToken(token);

//     // Push both token AND userId to GroupProvider
//     groupProvider.setAuthToken(token);
//     groupProvider.setUserId(_user!.id); // ← NEW

//     debugPrint('✅ Authenticated user: ${_user!.id}');
//     notifyListeners();
//   }

//   Future<void> logout(GroupProvider groupProvider) async {
//     // Wipe this user's local SQLite data before clearing identity
//     await groupProvider.clearForLogout(); // ← NEW: cleans SQLite too

//     _user = null;
//     _token = null;
//     await StorageService.clearAll();
//     await fb.FirebaseAuth.instance.signOut();

//     notifyListeners();
//   }
// }
