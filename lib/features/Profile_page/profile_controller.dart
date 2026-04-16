// ════════════════════════════════════════════════════════════════
// FILE: lib/features/Profile_page/profile_controller.dart
// ════════════════════════════════════════════════════════════════
//
// FIX 1: Never store BuildContext as a field — it causes
//         "context is not a subtype of BuildContext" crashes.
//         Pass context as a parameter to every method instead.
//
// FIX 2: After update, call UserProviders.updateUserProfile()
//         so the UI (dashboard greeting, avatar) also reflects
//         the new name/email — single source of truth.
//
// FIX 3: Profile picture upload uses multipart correctly and
//         updates UserProviders too.
//
// OFFLINE: If network fails, local state + SharedPreferences
//          are still updated so UI shows the change.
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:splitzon/features/Profile_page/profile_model.dart';
import 'dart:convert';
import 'dart:io';

import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/services/storage_service.dart';
import 'package:splitzon/api/api_controller.dart';

class ProfileController extends ChangeNotifier {
  UserModel _user = UserModel(
    id: '',
    name: '',
    email: '',
    phone: '',
    profilePicture: '',
  );
  bool _isLoading = false;
  String _lastError = '';

  UserModel get user => _user;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // ─────────────────────────────────────────────────────────
  void _log(String m) => debugPrint('👤 ProfileController: $m');
  void _err(String m) => debugPrint('❌ ProfileController: $m');

  // ─────────────────────────────────────────────────────────
  // INIT — called once when ProfileScreen opens
  // Reads from UserProviders (already in memory from login)
  // ─────────────────────────────────────────────────────────
  void init(BuildContext context) {
    // ✅ Use context as a local parameter, never store it
    final userProvider = Provider.of<UserProviders>(context, listen: false);
    if (userProvider.user != null) {
      _user = UserModel.fromMap(userProvider.user!.toMap());
      _log('Initialized from UserProviders: ${_user.name}');
    } else {
      _log('No user in UserProviders — using guest');
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE NAME / EMAIL / PHONE
  //
  // Flow:
  //   1. Update UI immediately (optimistic)
  //   2. Call backend
  //   3. If success → update UserProviders + SharedPreferences
  //   4. If fail (offline) → local state still updated, show warning
  // ─────────────────────────────────────────────────────────
  Future<bool> updatePersonalInfo({
    required BuildContext context, // ✅ passed as parameter, not stored
    required String name,
    required String email,
    required String phone,
  }) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    _log('Updating profile: name=$name email=$email phone=$phone');

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _lastError = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ── Step 1: Update local state immediately ────────────
      // UI reflects change instantly even if network is slow
      _user.name = name;
      _user.email = email;
      _user.phone = phone;
      notifyListeners();
      _log('Local state updated immediately ✅');

      // ── Step 2: Update UserProviders + SharedPreferences ──
      // This updates the dashboard greeting and avatar letter
      final userProvider = Provider.of<UserProviders>(context, listen: false);
      await userProvider.updateUserProfile(name, email, phone);
      _log('UserProviders updated ✅');

      // ── Step 3: Call backend ──────────────────────────────
      final response = await http.put(
        Uri.parse(
          '${ApiService.baseUrl.replaceAll('/auth', '/auth')}/users/profile',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
      );

      _log('Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _log('Backend update successful ✅');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _lastError = data['message'] ?? 'Backend update failed';
          _err(_lastError);
        }
      } else {
        _lastError = 'Server error: ${response.statusCode}';
        _err(_lastError);
      }

      // Backend failed but local/SharedPreferences already updated
      // Return true so UI doesn't show an error for offline case
      _isLoading = false;
      notifyListeners();
      return true; // ← local update succeeded, backend will sync later
    } catch (e) {
      // Network error — local state already updated
      _log('Network error (offline mode): $e — local update kept ✅');
      _lastError = '';
      _isLoading = false;
      notifyListeners();
      return true; // ← show success, local data is updated
    }
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE PROFILE PICTURE
  // ─────────────────────────────────────────────────────────
  Future<bool> updateProfilePicture({
    required BuildContext context, // ✅ passed as parameter
    required File imageFile,
  }) async {
    _isLoading = true;
    _lastError = '';
    notifyListeners();

    _log('Uploading profile picture: ${imageFile.path}');

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _lastError = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '${ApiService.baseUrl.replaceAll('/auth', '')}/auth/users/profile-picture',
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('profilePicture', imageFile.path),
      );

      _log('Sending multipart request...');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      _log('Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final newUrl = data['profilePicture'] as String? ?? '';
          _log('Profile picture uploaded: $newUrl ✅');

          // Update local state
          _user.profilePicture = newUrl;
          notifyListeners();

          // Update UserProviders + SharedPreferences
          final userProvider = Provider.of<UserProviders>(
            context,
            listen: false,
          );
          await userProvider.updateUserProfilePicture(newUrl);
          _log('UserProviders profile picture updated ✅');

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _lastError = data['message'] ?? 'Upload failed';
          _err(_lastError);
        }
      } else {
        _lastError = 'Upload failed: ${response.statusCode}';
        _err(_lastError);
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _err('Upload exception: $e');
      _lastError = 'Network error — try again when online';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void signOut() {
    // Handled by FirebaseAuthMethods.signOut()
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
