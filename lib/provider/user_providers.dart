// ════════════════════════════════════════════════════════════════
// FILE: lib/provider/user_providers.dart
// ════════════════════════════════════════════════════════════════
//
// Single source of truth for the logged-in user.
// ProfileController and DashboardScreen both read from here.
// After updateUserProfile() the dashboard greeting rebuilds
// automatically because UserProviders calls notifyListeners().
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

  void _log(String m) => debugPrint('👤 UserProviders: $m');

  // ─────────────────────────────────────────────────────────
  // INIT ON APP START
  // ─────────────────────────────────────────────────────────

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
            expenseProvider.setAuthToken(savedToken);
            expenseProvider.setUserId(_user!.id);
            _log('Session restored for user: ${_user!.name} (${_user!.id})');
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

  // ─────────────────────────────────────────────────────────
  // SET AFTER LOGIN / SIGNUP
  // ─────────────────────────────────────────────────────────

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
    expenseProvider.setAuthToken(token);
    expenseProvider.setUserId(_user!.id);

    _log('Authenticated: ${_user!.name} (${_user!.id})');
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE NAME / EMAIL / PHONE
  //
  // Called by ProfileController after successful edit.
  // notifyListeners() causes DashboardScreen greeting to
  // rebuild immediately with the new name.
  // ─────────────────────────────────────────────────────────

  Future<void> updateUserProfile(
    String name,
    String email,
    String phone,
  ) async {
    if (_user == null) return;

    _log('Updating user: name=$name email=$email phone=$phone');

    _user = User(
      id: _user!.id,
      name: name,
      email: email,
      phone: phone,
      profile: _user!.profile,
    );

    // Persist to SharedPreferences so it survives app restart
    await StorageService.saveUser(_user!.toMap());

    notifyListeners(); // ← dashboard greeting rebuilds ✅
    _log('User updated and saved to SharedPreferences ✅');
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE PROFILE PICTURE
  // ─────────────────────────────────────────────────────────

  Future<void> updateUserProfilePicture(String profilePictureUrl) async {
    if (_user == null) return;

    _log('Updating profile picture: $profilePictureUrl');

    _user = User(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      phone: _user!.phone,
      profile: profilePictureUrl,
    );

    await StorageService.saveUser(_user!.toMap());
    notifyListeners();
    _log('Profile picture updated ✅');
  }

  // ─────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────

  Future<void> logout(
    GroupProvider groupProvider,
    ExpenseProvider expenseProvider,
  ) async {
    _log('Logging out user: ${_user?.name}');

    await groupProvider.clearForLogout();
    expenseProvider.clearForLogout();

    _user = null;
    _token = null;
    await StorageService.clearAll();
    await fb.FirebaseAuth.instance.signOut();

    notifyListeners();
    _log('Logout complete ✅');
  }
}

// // lib/features/Profile_page/profile_controller.dart
// import 'package:flutter/material.dart';
// import 'package:path/path.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:splitzon/features/Profile_page/profile_model.dart';
// import 'dart:convert';

// import 'package:splitzon/provider/user_providers.dart';
// import 'package:splitzon/services/storage_service.dart';
// import 'package:splitzon/api/api_controller.dart';

// class ProfileController extends ChangeNotifier {
//   late UserModel _user;
//   bool _isLoading = false;
//   String _lastError = '';

//   UserModel get user => _user;
//   bool get isLoading => _isLoading;
//   String get lastError => _lastError;

//   void init(BuildContext context) {
//     final userProvider = Provider.of<UserProviders>(context, listen: false);
//     if (userProvider.user != null) {
//       _user = UserModel.fromMap(userProvider.user!.toMap());
//     } else {
//       _user = UserModel(
//         id: '',
//         name: 'Guest User',
//         email: '',
//         phone: '',
//         profilePicture: '',
//       );
//     }
//     notifyListeners();
//   }

//   // Update Personal Information
//   Future<bool> updatePersonalInfo({
//     required String name,
//     required String email,
//     required String phone,
//   }) async {
//     _isLoading = true;
//     _lastError = '';
//     notifyListeners();

//     try {
//       final token = await StorageService.getToken();
//       if (token == null) throw Exception("Not authenticated");

//       final response = await http.put(
//         Uri.parse(
//           "${ApiService.baseUrl.replaceAll('/auth', '/auth')}/users/profile",
//         ),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({"name": name, "email": email, "phone": phone}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['success'] == true) {
//           _user.name = name;
//           _user.email = email;
//           _user.phone = phone;

//           final userProvider = Provider.of<UserProviders>(
//             context as BuildContext,
//             listen: false,
//           );
//           await userProvider.updateUserProfile(name, email, phone);

//           notifyListeners();
//           return true;
//         }
//       }
//       _lastError = "Failed to update profile";
//       return false;
//     } catch (e) {
//       _lastError = "Network error: $e";
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void signOut() {
//     // Handled in FirebaseAuthMethods
//   }
// }

// // lib/controllers/profile_controller.dart
// import 'package:flutter/material.dart';
// import 'package:splitzon/features/Profile_page/profile_model.dart';

// class ProfileController extends ChangeNotifier {
//   UserModel user = UserModel(
//     name: 'P Madhavan',
//     email: 'madhavan@gmail.com',
//     phone: '+91 9876543210',
//   );

//   bool isPremium = true;

//   void toggleDarkMode(bool value) {
//     user.darkMode = value;
//     notifyListeners();
//   }

//   void updatePersonalInfo(String name, String email, String phone) {
//     user.name = name;
//     user.email = email;
//     user.phone = phone;
//     notifyListeners();
//   }

//   void updateLanguage(String lang) {
//     user.language = lang;
//     notifyListeners();
//   }

//   void upgradeToPlatinum() {
//     isPremium = true;
//     notifyListeners();
//   }

//   void signOut() {
//     // Add your sign-out logic e.g., FirebaseAuth.instance.signOut();
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // FILE: lib/provider/user_providers.dart
// // ════════════════════════════════════════════════════════════════

// import 'package:firebase_auth/firebase_auth.dart' as fb;
// import 'package:flutter/material.dart';
// import 'package:splitzon/model/user.dart';
// import 'package:splitzon/providers/expense_provider.dart';
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

//   // ── INIT ON APP START ─────────────────────────────────────
//   Future<bool> initAuth(
//     GroupProvider groupProvider,
//     ExpenseProvider expenseProvider,
//   ) async {
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
//             groupProvider.setUserId(_user!.id);
//             // ← also set on expense provider
//             expenseProvider.setAuthToken(savedToken);
//             expenseProvider.setUserId(_user!.id);
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

//   // ── SET AFTER LOGIN / SIGNUP ──────────────────────────────
//   Future<void> setAuthenticated(
//     Map<String, dynamic> userMap,
//     String token,
//     GroupProvider groupProvider,
//     ExpenseProvider expenseProvider,
//   ) async {
//     _user = User.fromMap(userMap);
//     _token = token;

//     await StorageService.saveUser(userMap);
//     await StorageService.saveToken(token);

//     groupProvider.setAuthToken(token);
//     groupProvider.setUserId(_user!.id);
//     // ← also set on expense provider
//     expenseProvider.setAuthToken(token);
//     expenseProvider.setUserId(_user!.id);

//     debugPrint('✅ Authenticated user: ${_user!.id}');
//     notifyListeners();
//   }

//   // ── LOGOUT ────────────────────────────────────────────────
//   Future<void> logout(
//     GroupProvider groupProvider,
//     ExpenseProvider expenseProvider,
//   ) async {
//     await groupProvider.clearForLogout();
//     expenseProvider.clearForLogout(); // ← clear expense data too

//     _user = null;
//     _token = null;
//     await StorageService.clearAll();
//     await fb.FirebaseAuth.instance.signOut();

//     notifyListeners();
//   }
// }
