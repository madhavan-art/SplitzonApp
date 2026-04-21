// ════════════════════════════════════════════════════════════════
// FILE: lib/providers/group_provider.dart
// ════════════════════════════════════════════════════════════════
//
// OFFLINE-FIRST FLOW:
//  loadGroups()
//    Step 1 → SQLite → show UI immediately (server irrelevant)
//    Step 2 → Background backend sync (silent fail if offline)
//
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/group_model.dart';
import '../data/models/member_model.dart';
import '../services/sync_service.dart';
import '../features/commentActivity/activity_controller.dart';
import '../provider/user_providers.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _groupRepository;
  final ExpenseRepository _expenseRepository;
  final UserProviders _userProviders;

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _authToken;
  String? _userId;
  String _lastError = '';
  SyncService? _syncService;

  GroupProvider({
    GroupRepository? groupRepository,
    ExpenseRepository? expenseRepository,
    required UserProviders userProviders,
  }) : _groupRepository = groupRepository ?? GroupRepository(),
       _expenseRepository = expenseRepository ?? ExpenseRepository(),
       _userProviders = userProviders;

  // ─────────────────────────────────────────────────────────
  void _log(String m) => debugPrint('📦 GroupProvider: $m');
  void _err(String m) => debugPrint('❌ GroupProvider: $m');

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String get lastError => _lastError;

  // ─────────────────────────────────────────────────────────
  // AUTH SETUP
  // ─────────────────────────────────────────────────────────

  void setAuthToken(String token) {
    _authToken = token;
    _rebuildSyncService();
    _log('Auth token set ✅');
  }

  void setUserId(String userId) {
    _userId = userId;
    _rebuildSyncService();
    _log('UserId set: $userId ✅');
  }

  void _rebuildSyncService() {
    if (_userId != null && _userId!.isNotEmpty) {
      _syncService = SyncService(userId: _userId);
      _log('SyncService ready for user: $_userId');
    }
  }

  // ─────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────

  Future<void> clearForLogout() async {
    _log('Clearing for logout...');
    _groups = [];
    _authToken = null;
    _userId = null;
    _syncService = null;
    notifyListeners();
    _log('Cleared ✅');
  }

  // ─────────────────────────────────────────────────────────
  // INITIALIZE
  // ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _log('initialize() called');
    if (_userId == null || _userId!.isEmpty) {
      _err('initialize skipped — userId not set');
      return;
    }
    await loadGroups();
  }

  // ─────────────────────────────────────────────────────────
  // LOAD GROUPS
  //
  // ✅ SQLite shown BEFORE any network call.
  // Server down / offline → data still shows immediately.
  // ─────────────────────────────────────────────────────────

  Future<void> loadGroups() async {
    if (_userId == null || _userId!.isEmpty) {
      _log('loadGroups skipped — no userId');
      return;
    }

    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('loadGroups() started for user: $_userId');

    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      // ── STEP 1: SQLite (instant, server-independent) ──────
      _log('[1/2] Loading from SQLite...');
      _groups = await _groupRepository.fetchGroups(_userId!);
      _isLoading = false;
      notifyListeners(); // ← UI shows data NOW
      _log(
        '[1/2] ✅ SQLite → ${_groups.length} groups → UI updated immediately',
      );

      // ── STEP 2: Background sync (non-blocking) ────────────
      _log('[2/2] Firing background backend sync...');
      _backgroundSync(); // NOT awaited
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      _err('loadGroups SQLite error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // BACKGROUND SYNC
  // ─────────────────────────────────────────────────────────

  void _backgroundSync() {
    if (_authToken == null || _syncService == null || _userId == null) {
      _log('[2/2] No auth/sync — offline mode, SQLite data shown ✅');
      return;
    }

    _syncFromBackend().catchError((e) {
      _err('[2/2] Background sync failed (offline is fine): $e');
    });
  }

  Future<void> _syncFromBackend() async {
    if (_syncService == null || _authToken == null || _userId == null) return;

    _log('[2/2] 🌐 Starting backend sync...');

    await _syncService!.syncPendingGroups(_authToken!);

    final backend = await _syncService!.fetchAndSyncGroups(_authToken!);
    _log('[2/2] 📥 Got ${backend.length} groups from backend');

    await _removeStaleGroups(backend);

    _groups = await _groupRepository.fetchGroups(_userId!);
    notifyListeners();
    _log('[2/2] ✅ UI refreshed → ${_groups.length} groups after backend sync');
  }

  Future<void> _removeStaleGroups(List<Group> backendGroups) async {
    final backendIds = backendGroups.map((g) => g.id).toSet();
    final local = await _groupRepository.fetchGroups(_userId!);
    int removed = 0;
    for (final g in local) {
      if (g.syncStatus == 'SYNCED' && !backendIds.contains(g.id)) {
        await _groupRepository.deleteGroup(g.id);
        removed++;
        _log('🗑️ Removed stale group: ${g.name}');
      }
    }
    if (removed > 0) _log('🗑️ Removed $removed stale group(s)');
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC SYNC — called by ConnectivityService
  // ─────────────────────────────────────────────────────────

  Future<void> syncWithBackend() async {
    _log('🔁 syncWithBackend() — connectivity restored');
    await _syncFromBackend();
  }

  Future<void> refreshGroups() async {
    _log('refreshGroups() called');
    await loadGroups();
  }

  // ─────────────────────────────────────────────────────────
  // CREATE GROUP
  // ─────────────────────────────────────────────────────────

  Future<Group?> createGroup({
    required String name,
    String? description,
    required String groupType,
    String currency = 'INR',
    double? overallBudget,
    double? myShare,
    required List<String> members,
    String? createdBy,
    String? bannerImagePath,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _err('createGroup skipped — no userId');
      return null;
    }

    _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log('createGroup(): "$name"');

    try {
      // ✅ AUTO POPULATE CURRENT USER DETAILS WHEN CREATING GROUP
      List<Member> memberList = [];

      for (final memberId in members) {
        if (memberId == _userId && _userProviders.user != null) {
          // ✅ THIS IS CURRENT USER - FILL ALL DETAILS AUTOMATICALLY
          memberList.add(
            Member(
              id: memberId,
              name: _userProviders.user!.name,
              email: _userProviders.user!.email,
              phone: _userProviders.user!.phone,
              photoUrl: _userProviders.user!.profile ?? '',
            ),
          );
          _log(
            '✅ Added CURRENT USER as member with full details: ${_userProviders.user!.name}',
          );
        } else {
          // Other members will be populated during sync
          memberList.add(Member(id: memberId, name: ''));
        }
      }

      final group = Group.create(
        userId: _userId!,
        name: name,
        description: description,
        groupType: groupType,
        currency: currency,
        overallBudget: overallBudget,
        myShare: myShare,
        members: memberList,
        createdBy: createdBy ?? _userId,
        bannerImagePath: bannerImagePath,
      );

      await _groupRepository.addGroup(group);
      _groups.insert(0, group);
      notifyListeners();

      // ✅ FULL DEBUG LOG OF EVERYTHING THAT IS BEING STORED
      debugPrint('');
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('  🟢 GROUP CREATED AND SAVED TO DATABASE - FULL DATA:');
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('  Group ID:        ${group.id}');
      debugPrint('  User ID:         ${group.userId}');
      debugPrint('  Name:            ${group.name}');
      debugPrint('  Description:     ${group.description ?? '(empty)'}');
      debugPrint('  Type:            ${group.groupType}');
      debugPrint('  Currency:        ${group.currency}');
      debugPrint('  Budget:          ${group.overallBudget}');
      debugPrint('  My Share:        ${group.myShare}');
      debugPrint('  Created By:      ${group.createdBy}');
      debugPrint('  Sync Status:     ${group.syncStatus}');
      debugPrint('  Created At:      ${group.createdAt}');
      debugPrint('  Banner Path:     ${group.bannerImagePath ?? '(none)'}');
      debugPrint('  Banner URL:      ${group.bannerImageUrl ?? '(none)'}');
      debugPrint('');
      debugPrint('  ➤ MEMBERS BEING SAVED (${group.members.length} total):');
      for (var i = 0; i < group.members.length; i++) {
        final member = group.members[i];
        debugPrint(
          '    [$i] ID: ${member.id} | Name: "${member.name}" | Email: "${member.email}" | Phone: "${member.phone}" | Photo: "${member.photoUrl}"',
        );
      }
      debugPrint(
        '═══════════════════════════════════════════════════════════════',
      );
      debugPrint('');

      _log('📱 Saved PENDING to SQLite → UI updated ✅');

      if (_authToken != null && _syncService != null) {
        final result = await _syncService!.syncGroupImmediately(
          group,
          _authToken!,
        );
        if (result['success'] == true) {
          _log('✅ Group pushed to backend → refreshing...');
          await _syncFromBackend();
        } else {
          _err('Backend push failed — stays PENDING: ${result['message']}');
        }
      } else {
        _log('📴 Offline — group stays PENDING, auto-syncs when online');
      }

      return group;
    } catch (e) {
      _err('createGroup error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DELETE / UPDATE
  // ─────────────────────────────────────────────────────────

  Future<bool> deleteGroup(String id) async {
    _log('🗑️ deleteGroup($id)');
    try {
      final group = _groups.firstWhere((g) => g.id == id);

      if (group.syncStatus == 'SYNCED') {
        // ✅ Already synced to server: mark as PENDING_DELETE
        final updatedGroup = group.copyWith(syncStatus: 'PENDING_DELETE');
        await _groupRepository.updateGroup(updatedGroup);
        _log('📱 Marked as PENDING_DELETE for background sync ✅');
      } else {
        // ✅ Never synced: delete locally immediately
        await _groupRepository.deleteGroup(id);
        _log('📱 Deleted pending group locally immediately ✅');
      }

      // Remove from UI immediately
      _groups.removeWhere((g) => g.id == id);
      notifyListeners();

      // Always try to delete immediately first if online
      if (_authToken != null && _syncService != null) {
        try {
          final online = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 2))
              .then((r) => r.isNotEmpty)
              .catchError((_) => false);

          if (online) {
            _log('🌐 Online! Deleting from backend immediately...');
            final success = await _syncService!.deleteGroupFromBackend(
              id,
              _authToken!,
            );
            if (success) {
              // Delete all expenses for this group first
              await _expenseRepository.deleteExpensesByGroup(id);
              await _groupRepository.deleteGroup(id);
              _log('✅ DELETED GROUP + ALL RELATED EXPENSES ✅');
            } else {
              _log('⚠️ Backend delete failed, kept as PENDING_DELETE');
            }
          } else {
            _log('📴 Offline! Kept as PENDING_DELETE, will sync when online ✅');
          }
        } catch (e) {
          _err('⚠️ Delete failed, kept as PENDING_DELETE: $e');
        }
      }

      return true;
    } catch (e) {
      _err('deleteGroup error: $e');
      return false;
    }
  }

  Future<bool> updateGroup(Group updatedGroup) async {
    try {
      await _groupRepository.updateGroup(updatedGroup);
      final idx = _groups.indexWhere((g) => g.id == updatedGroup.id);
      if (idx != -1) {
        _groups[idx] = updatedGroup;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _err('updateGroup error: $e');
      return false;
    }
  }

  List<Group> getPendingGroups() =>
      _groups.where((g) => g.syncStatus == 'PENDING').toList();

  List<Group> getSyncedGroups() =>
      _groups.where((g) => g.syncStatus == 'SYNCED').toList();
}

// import 'package:flutter/material.dart';
// import '../data/repositories/group_repository.dart';
// import '../data/models/group_model.dart';
// import '../services/sync_service.dart';

// class GroupProvider with ChangeNotifier {
//   final GroupRepository _groupRepository;

//   List<Group> _groups = [];
//   bool _isLoading = false;

//   String? _authToken;
//   String? _userId;

//   String _lastError = '';
//   String _lastMessage = '';

//   SyncService? _syncService;

//   GroupProvider({GroupRepository? groupRepository})
//     : _groupRepository = groupRepository ?? GroupRepository();

//   // ───────────────── GETTERS ─────────────────
//   List<Group> get groups => _groups;
//   bool get isLoading => _isLoading;
//   String get lastError => _lastError;
//   String get lastMessage => _lastMessage;

//   // ───────────────── LOGGING ─────────────────
//   void _log(String message) {
//     debugPrint('📦 GroupProvider: $message');
//     _lastMessage = message;
//   }

//   void _logError(String error) {
//     debugPrint('❌ GroupProvider Error: $error');
//     _lastError = error;
//   }

//   // ───────────────── AUTH SETUP ─────────────────
//   void setAuthToken(String token) {
//     _authToken = token;
//     _rebuildSyncService();
//     _log('Auth token set');
//   }

//   void setUserId(String userId) {
//     _userId = userId;
//     _rebuildSyncService();
//     _log('UserId set: $userId');
//   }

//   void _rebuildSyncService() {
//     if (_userId != null && _userId!.isNotEmpty) {
//       _syncService = SyncService(userId: _userId);
//       _log('SyncService initialized');
//     }
//   }

//   // ───────────────── LOGOUT ─────────────────
//   Future<void> clearForLogout() async {
//     _groups = [];
//     _authToken = null;
//     _userId = null;
//     _syncService = null;
//     notifyListeners();
//     _log('Cleared provider on logout');
//   }

//   // ───────────────── REFRESH (Called from Add Members Screen) ─────────────────
//   Future<void> refreshGroups() async {
//     _log('refreshGroups() called from Add Members');
//     await loadGroups(); // This will show local data instantly
//   }

//   // ───────────────── INITIALIZE ─────────────────
//   Future<void> initialize() async {
//     _log("initialize() called");
//     if (_userId == null || _userId!.isEmpty) {
//       _logError("UserId not set");
//       return;
//     }
//     await loadGroups();
//   }

//   // ───────────────── LOAD GROUPS - OFFLINE FIRST ─────────────────
//   Future<void> loadGroups() async {
//     if (_userId == null || _userId!.isEmpty) {
//       _log('No userId — skipping load');
//       return;
//     }

//     _isLoading = true;
//     _lastError = '';
//     notifyListeners();

//     try {
//       // STEP 1: Load from local SQLite FIRST (fast + works offline)
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       _log('✅ Loaded ${_groups.length} groups from local SQLite');

//       // Show data to UI immediately
//       _isLoading = false;
//       notifyListeners();

//       // STEP 2: Background sync only (do not block UI)
//       _performBackgroundSync();
//     } catch (e) {
//       _logError('loadGroups SQLite error: $e');
//       _lastError = 'Failed to load local groups';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // ── Background Sync (never blocks the UI) ─────────────────────
//   void _performBackgroundSync() {
//     if (_authToken == null || _syncService == null || _userId == null) {
//       _log('📴 No auth or sync service — staying in offline mode');
//       return;
//     }

//     // Run in background without await in main flow
//     _fetchFromBackendAndRefresh().catchError((e) {
//       _logError('Background sync failed (offline is OK): $e');
//       // Do NOT change _isLoading or clear _groups here
//     });
//   }

//   // ───────────────── CORE SYNC (Background) ─────────────────
//   Future<void> _fetchFromBackendAndRefresh() async {
//     try {
//       _log('🌐 Starting background backend sync...');

//       await _syncService!.syncPendingGroups(_authToken!);

//       final backendGroups = await _syncService!.fetchAndSyncGroups(_authToken!);

//       _log('Got ${backendGroups.length} groups from backend');

//       await _removeStaleGroups(backendGroups);

//       // Reload latest from SQLite after sync
//       _groups = await _groupRepository.fetchGroups(_userId!);

//       notifyListeners();
//       _log('✅ UI updated with ${_groups.length} groups after backend sync');
//     } catch (e) {
//       _logError('Backend sync failed — continuing with local cache: $e');
//       // Silent fail - local data is already shown
//     }
//   }

//   // ───────────────── STALE CLEANUP ─────────────────
//   Future<void> _removeStaleGroups(List<Group> backendGroups) async {
//     try {
//       final backendIds = backendGroups.map((g) => g.id).toSet();

//       final localGroups = await _groupRepository.fetchGroups(_userId!);

//       final stale = localGroups.where((local) {
//         return local.syncStatus == 'SYNCED' && !backendIds.contains(local.id);
//       }).toList();

//       if (stale.isEmpty) return;

//       _log('Removing ${stale.length} stale group(s)');

//       for (final group in stale) {
//         await _groupRepository.deleteGroup(group.id);
//         _log('Removed stale group: ${group.name}');
//       }
//     } catch (e) {
//       _logError('removeStaleGroups error: $e');
//     }
//   }

//   // ───────────────── PUBLIC SYNC (Pull to refresh) ─────────────────
//   Future<void> syncWithBackend() async {
//     if (_authToken == null || _syncService == null || _userId == null) return;
//     await _fetchFromBackendAndRefresh();
//   }

//   // ───────────────── CREATE / DELETE / UPDATE (keep as is) ─────────────────
//   Future<Group?> createGroup({
//     required String name,
//     String? description,
//     required String groupType,
//     String currency = 'INR',
//     double? overallBudget,
//     double? myShare,
//     required List<String> members,
//     String? createdBy,
//     String? bannerImagePath,
//   }) async {
//     if (_userId == null || _userId!.isEmpty) {
//       _logError('Cannot create group — no userId');
//       return null;
//     }

//     try {
//       _log('Creating group: $name');

//       final group = Group.create(
//         userId: _userId!,
//         name: name,
//         description: description,
//         groupType: groupType,
//         currency: currency,
//         overallBudget: overallBudget,
//         myShare: myShare,
//         members: members,
//         createdBy: createdBy ?? _userId,
//         bannerImagePath: bannerImagePath,
//       );

//       await _groupRepository.addGroup(group);
//       _groups.insert(0, group);
//       notifyListeners();

//       _log('Saved to SQLite as PENDING: ${group.id}');

//       if (_authToken != null && _syncService != null) {
//         final result = await _syncService!.syncGroupImmediately(
//           group,
//           _authToken!,
//         );
//         if (result['success'] == true) {
//           await _fetchFromBackendAndRefresh();
//         }
//       }

//       return group;
//     } catch (e) {
//       _logError('createGroup error: $e');
//       return null;
//     }
//   }

//   Future<bool> deleteGroup(String id) async {
//     try {
//       final group = _groups.firstWhere((g) => g.id == id);

//       await _groupRepository.deleteGroup(id);
//       _groups.removeWhere((g) => g.id == id);
//       notifyListeners();

//       if (group.syncStatus == 'SYNCED' &&
//           _authToken != null &&
//           _syncService != null) {
//         await _syncService!.deleteGroupFromBackend(id, _authToken!);
//       }
//       return true;
//     } catch (e) {
//       _logError('deleteGroup error: $e');
//       return false;
//     }
//   }

//   Future<bool> updateGroup(Group updatedGroup) async {
//     try {
//       await _groupRepository.updateGroup(updatedGroup);

//       final index = _groups.indexWhere((g) => g.id == updatedGroup.id);
//       if (index != -1) {
//         _groups[index] = updatedGroup;
//         notifyListeners();
//       }
//       return true;
//     } catch (e) {
//       _logError('updateGroup error: $e');
//       return false;
//     }
//   }

//   List<Group> getPendingGroups() =>
//       _groups.where((g) => g.syncStatus == 'PENDING').toList();

//   List<Group> getSyncedGroups() =>
//       _groups.where((g) => g.syncStatus == 'SYNCED').toList();
// }
