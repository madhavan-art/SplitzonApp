import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api_controller.dart';
import '../data/local/database_helper.dart';
import '../model/user.dart';
import 'storage_service.dart';

class ProfileSyncService {
  static final ProfileSyncService _instance = ProfileSyncService._internal();
  factory ProfileSyncService() => _instance;
  ProfileSyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  void _log(String message) {
    // debugPrint('👤 ProfileSyncService: $message');
  }

  void _logError(String error) {
    // debugPrint('❌ ProfileSyncService Error: $error');
  }

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── MARK PROFILE AS PENDING WHEN OFFLINE ─────────────────
  Future<void> markProfilePending(User user) async {
    try {
      final pendingUser = user.copyWith(syncStatus: 'PENDING');
      await _dbHelper.insertOrUpdateUser(pendingUser);
      _log('Profile marked as PENDING for sync');
    } catch (e) {
      _logError('Failed to mark profile pending: $e');
    }
  }

  // ── SYNC PENDING PROFILE WHEN ONLINE ─────────────────────
  Future<void> syncPendingProfile() async {
    try {
      if (!await _isConnected()) {
        _log('No internet. Will sync profile when online.');
        return;
      }

      final token = await StorageService.getToken();
      if (token == null) {
        _logError('No auth token available');
        return;
      }

      // Get current user from local DB
      final user = await _dbHelper.getCurrentUser();
      if (user == null) {
        _log('No user found in local DB');
        return;
      }

      // Only sync if profile is pending
      if (user.syncStatus != 'PENDING') {
        _log('Profile is already synced');
        return;
      }

      _log('Found pending profile changes. Syncing to backend...');

      // Send update to MongoDB backend
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
        }),
      );

      _log('Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // ✅ Sync successful - mark as SYNCED
          final syncedUser = user.copyWith(syncStatus: 'SYNCED');
          await _dbHelper.insertOrUpdateUser(syncedUser);
          _log('Profile synced successfully with MongoDB ✅');
        } else {
          _logError('Backend sync failed: ${result['message']}');
        }
      } else {
        _logError('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logError('syncPendingProfile exception: $e');
    }
  }

  // ── ATTEMPT IMMEDIATE SYNC ON UPDATE ─────────────────────
  Future<Map<String, dynamic>> syncProfileImmediately(User user) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      if (!await _isConnected()) {
        // Offline - mark as pending and return success for local
        await markProfilePending(user);
        return {
          'success': true,
          'offline': true,
          'message': 'Profile updated locally. Will sync when online.',
        };
      }

      // Online - sync immediately
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final syncedUser = user.copyWith(syncStatus: 'SYNCED');
          await _dbHelper.insertOrUpdateUser(syncedUser);
          return {'success': true, 'message': 'Profile updated successfully'};
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Sync failed',
          };
        }
      } else {
        // Server error - still mark as pending for later retry
        await markProfilePending(user);
        return {
          'success': true,
          'offline': true,
          'message': 'Server unavailable. Will retry later.',
        };
      }
    } catch (e) {
      // Network error - mark as pending
      await markProfilePending(user);
      return {
        'success': true,
        'offline': true,
        'message': 'Offline mode. Profile will sync when online.',
      };
    }
  }

  // ── BACKGROUND SYNC TRIGGER ──────────────────────────────
  // Call this when connectivity is restored
  Future<void> onConnectivityRestored() async {
    _log('Connectivity restored - checking for pending profile changes');
    await syncPendingProfile();
  }

  // ── SCHEDULE PERIODIC SYNC ───────────────────────────────
  // Call this periodically or on app resume
  Future<void> runSyncCheck() async {
    await syncPendingProfile();
  }
}
