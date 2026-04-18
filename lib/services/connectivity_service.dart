import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../providers/group_provider.dart';
import 'profilesyncservice.dart';

/// Watches internet connectivity.
/// When internet comes BACK, automatically syncs all PENDING groups.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  ConnectivityService._init();

  Timer? _timer;
  bool _wasOffline = false;
  GroupProvider? _groupProvider;

  /// Start watching. Call this once after login, pass GroupProvider.
  void startWatching(GroupProvider groupProvider) {
    _groupProvider = groupProvider;
    _timer?.cancel();

    // Check every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final online = await _isConnected();

      if (!online) {
        // We are offline — remember this
        if (!_wasOffline) {
          _wasOffline = true;
          debugPrint('📡 ConnectivityService: went OFFLINE');
        }
      } else {
        // We are online now
        if (_wasOffline) {
          // Just came back online — trigger sync!
          _wasOffline = false;
          debugPrint(
            '📡 ConnectivityService: back ONLINE — syncing pending...',
          );
          await _syncPending();
        }
      }
    });

    debugPrint('📡 ConnectivityService: started watching');
  }

  /// Stop watching. Call this on logout.
  void stopWatching() {
    _timer?.cancel();
    _timer = null;
    _groupProvider = null;
    _wasOffline = false;
    debugPrint('📡 ConnectivityService: stopped');
  }

  Future<void> _syncPending() async {
    final provider = _groupProvider;
    if (provider == null) return;

    // ✅ ALWAYS sync when coming online! Don't check pending count
    // Because PENDING_DELETE groups are not in getPendingGroups()
    debugPrint(
      '📡 Going online! Triggering full sync for ALL pending operations...',
    );
    await provider.syncWithBackend();

    // Sync pending profile changes
    debugPrint('📡 Syncing pending profile changes...');
    await ProfileSyncService().onConnectivityRestored();
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
}
