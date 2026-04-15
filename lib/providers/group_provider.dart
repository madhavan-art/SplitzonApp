import 'package:flutter/material.dart';
import '../data/repositories/group_repository.dart';
import '../data/models/group_model.dart';
import '../services/sync_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupRepository _groupRepository;

  List<Group> _groups = [];
  bool _isLoading = false;

  String? _authToken;
  String? _userId;

  String _lastError = '';
  String _lastMessage = '';

  SyncService? _syncService;

  GroupProvider({GroupRepository? groupRepository})
    : _groupRepository = groupRepository ?? GroupRepository();

  // ───────────────── GETTERS ─────────────────

  List<Group> get groups => _groups;

  bool get isLoading => _isLoading;

  String get lastError => _lastError;

  String get lastMessage => _lastMessage;

  // ───────────────── LOGGING ─────────────────

  void _log(String message) {
    debugPrint('📦 GroupProvider: $message');
    _lastMessage = message;
  }

  void _logError(String error) {
    debugPrint('❌ GroupProvider Error: $error');
    _lastError = error;
  }

  // ───────────────── AUTH SETUP ─────────────────

  void setAuthToken(String token) {
    _authToken = token;
    _rebuildSyncService();
    _log('Auth token set');
  }

  void setUserId(String userId) {
    _userId = userId;
    _rebuildSyncService();
    _log('UserId set: $userId');
  }

  void clearAuthToken() {
    _authToken = null;
  }

  void _rebuildSyncService() {
    if (_userId != null && _userId!.isNotEmpty) {
      _syncService = SyncService(userId: _userId);
      _log('SyncService initialized');
    }
  }

  // ───────────────── LOGOUT ─────────────────

  /// Clears RAM only
  /// SQLite data remains safe
  Future<void> clearForLogout() async {
    _groups = [];
    _authToken = null;
    _userId = null;
    _syncService = null;

    notifyListeners();

    _log('Cleared provider on logout');
  }

  // ───────────────── INITIALIZE ─────────────────

  Future<void> initialize() async {
    try {
      _log("initialize() called");

      if (_userId == null || _userId!.isEmpty) {
        _logError("UserId not set");
        return;
      }

      await loadGroups();
    } catch (e) {
      _logError("initialize error: $e");
    }
  }

  // ───────────────── LOAD GROUPS ─────────────────

  Future<void> loadGroups() async {
    if (_userId == null || _userId!.isEmpty) {
      _log('No userId — skipping load');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // STEP 1 — LOAD SQLITE FIRST (FAST / OFFLINE)

      _groups = await _groupRepository.fetchGroups(_userId!);

      _isLoading = false;
      notifyListeners();

      _log('SQLite has ${_groups.length} groups');

      // STEP 2 — SYNC BACKEND

      if (_authToken != null &&
          _authToken!.isNotEmpty &&
          _syncService != null) {
        await _fetchFromBackendAndRefresh();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      _logError('loadGroups error: $e');
    }
  }

  // ───────────────── CORE SYNC ─────────────────

  Future<void> _fetchFromBackendAndRefresh() async {
    if (_syncService == null || _authToken == null || _userId == null) {
      return;
    }

    try {
      _log('Fetching groups from backend...');

      /// 1 — PUSH PENDING GROUPS

      await _syncService!.syncPendingGroups(_authToken!);

      /// 2 — FETCH FROM BACKEND

      final backendGroups = await _syncService!.fetchAndSyncGroups(_authToken!);

      _log('Got ${backendGroups.length} groups from backend');

      /// 3 — REMOVE STALE GROUPS

      await _removeStaleGroups(backendGroups);

      /// 4 — RELOAD SQLITE

      _groups = await _groupRepository.fetchGroups(_userId!);

      notifyListeners();

      _log('UI updated with ${_groups.length} groups');
    } catch (e) {
      _logError('Backend sync failed — using cache: $e');
    }
  }

  // ───────────────── STALE CLEANUP ─────────────────

  Future<void> _removeStaleGroups(List<Group> backendGroups) async {
    try {
      final backendIds = backendGroups.map((g) => g.id).toSet();

      final localGroups = await _groupRepository.fetchGroups(_userId!);

      final stale = localGroups.where((local) {
        final isSynced = local.syncStatus == 'SYNCED';

        final missingFromBackend = !backendIds.contains(local.id);

        return isSynced && missingFromBackend;
      }).toList();

      if (stale.isEmpty) return;

      _log('Removing ${stale.length} stale group(s)');

      for (final group in stale) {
        await _groupRepository.deleteGroup(group.id);

        _log('Removed stale group: ${group.name}');
      }
    } catch (e) {
      _logError('removeStaleGroups error: $e');
    }
  }

  // ───────────────── PUBLIC SYNC ─────────────────

  Future<void> syncWithBackend() async {
    if (_authToken == null || _syncService == null || _userId == null) {
      return;
    }

    await _fetchFromBackendAndRefresh();
  }

  // ───────────────── CREATE GROUP ─────────────────

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
      _logError('Cannot create group — no userId');
      return null;
    }

    try {
      _log('Creating group: $name');

      final group = Group.create(
        userId: _userId!,
        name: name,
        description: description,
        groupType: groupType,
        currency: currency,
        overallBudget: overallBudget,
        myShare: myShare,
        members: members,
        createdBy: createdBy ?? _userId,
        bannerImagePath: bannerImagePath,
      );

      /// SAVE SQLITE

      await _groupRepository.addGroup(group);

      _groups.insert(0, group);

      notifyListeners();

      _log('Saved to SQLite as PENDING: ${group.id}');

      /// TRY IMMEDIATE SYNC

      if (_authToken != null &&
          _authToken!.isNotEmpty &&
          _syncService != null) {
        final result = await _syncService!.syncGroupImmediately(
          group,
          _authToken!,
        );

        if (result['success'] == true) {
          await _fetchFromBackendAndRefresh();

          _log('Group created and synced');
        } else {
          _logError('Sync failed — remains PENDING');
        }
      } else {
        _log('Offline — group will sync later');
      }

      return group;
    } catch (e) {
      _logError('createGroup error: $e');

      return null;
    }
  }

  // ───────────────── DELETE GROUP ─────────────────

  Future<bool> deleteGroup(String id) async {
    try {
      final group = _groups.firstWhere((g) => g.id == id);

      await _groupRepository.deleteGroup(id);

      _groups.removeWhere((g) => g.id == id);

      notifyListeners();

      if (group.syncStatus == 'SYNCED' &&
          _authToken != null &&
          _syncService != null) {
        await _syncService!.deleteGroupFromBackend(id, _authToken!);
      }

      return true;
    } catch (e) {
      _logError('deleteGroup error: $e');

      return false;
    }
  }

  // ───────────────── UPDATE GROUP ─────────────────

  Future<bool> updateGroup(Group updatedGroup) async {
    try {
      await _groupRepository.updateGroup(updatedGroup);

      final index = _groups.indexWhere((g) => g.id == updatedGroup.id);

      if (index != -1) {
        _groups[index] = updatedGroup;

        notifyListeners();
      }

      return true;
    } catch (e) {
      _logError('updateGroup error: $e');

      return false;
    }
  }

  // ───────────────── HELPERS ─────────────────

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

//   GroupProvider({
//     GroupRepository? groupRepository,
//   }) : _groupRepository = groupRepository ?? GroupRepository();

//   List<Group> get groups => _groups;
//   bool get isLoading => _isLoading;
//   String get lastError => _lastError;
//   String get lastMessage => _lastMessage;

//   void _log(String message) {
//     debugPrint('📦 GroupProvider: $message');
//     _lastMessage = message;
//   }

//   void _logError(String error) {
//     debugPrint('❌ GroupProvider Error: $error');
//     _lastError = error;
//   }

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
//     }
//   }

//   void clearAuthToken() {
//     _authToken = null;
//   }

//   // ── LOGOUT — clear RAM only, SQLite stays ─────────────────
//   Future<void> clearForLogout() async {
//     _groups = [];
//     _authToken = null;
//     _userId = null;
//     _syncService = null;
//     notifyListeners();
//     _log('Cleared on logout');
//   }

//   // ── LOAD GROUPS ───────────────────────────────────────────
//   // Step 1: show SQLite instantly
//   // Step 2: fetch from MongoDB in background → update SQLite → refresh UI
//   Future<void> loadGroups() async {
//     if (_userId == null || _userId!.isEmpty) {
//       _log('No userId — skipping load');
//       return;
//     }

//     _isLoading = true;
//     notifyListeners();

//     try {
//       // Step 1 — SQLite (instant, works offline)
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       _isLoading = false;
//       notifyListeners();
//       _log('SQLite has ${_groups.length} groups');

//       // Step 2 — Backend sync in background
//       if (_authToken != null && _authToken!.isNotEmpty) {
//         await _fetchFromBackendAndRefresh();
//       }
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       _logError('loadGroups error: $e');
//     }
//   }

//   // ── CORE: fetch from MongoDB → save to SQLite → reload UI ─
//   Future<void> _fetchFromBackendAndRefresh() async {
//     if (_syncService == null || _userId == null) return;

//     try {
//       _log('Fetching groups from MongoDB...');

//       // Push PENDING groups first
//       await _syncService!.syncPendingGroups(_authToken!);

//       // Pull all groups from MongoDB → saved to SQLite by SyncService
//       final backendGroups =
//           await _syncService!.fetchAndSyncGroups(_authToken!);
//       _log('Got ${backendGroups.length} groups from MongoDB');

//       // Reload from SQLite — this is the single source of truth
//       // After syncPendingGroups deleted local uuid copies, and
//       // fetchAndSyncGroups inserted MongoDB versions, SQLite now
//       // has exactly the right set with no duplicates
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       notifyListeners();
//       _log('UI updated with ${_groups.length} groups ✅');
//     } catch (e) {
//       _logError('Backend fetch failed (showing cache): $e');
//     }
//   }

//   // ── PUBLIC SYNC (called by ConnectivityService) ───────────
//   Future<void> syncWithBackend() async {
//     if (_authToken == null || _syncService == null || _userId == null) return;
//     await _fetchFromBackendAndRefresh();
//   }

//   // ── CREATE GROUP ──────────────────────────────────────────
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

//       // Save to SQLite immediately — UI shows it right away
//       await _groupRepository.addGroup(group);
//       _groups.insert(0, group);
//       notifyListeners();
//       _log('Saved to SQLite as PENDING: ${group.id}');

//       if (_authToken != null &&
//           _authToken!.isNotEmpty &&
//           _syncService != null) {
//         // Push to backend — SyncService will DELETE the local uuid copy
//         final result =
//             await _syncService!.syncGroupImmediately(group, _authToken!);

//         if (result['success'] == true) {
//           // ✅ Local uuid copy deleted by SyncService.
//           // Now fetch from MongoDB so we get the correct MongoDB _id version.
//           // This prevents the duplicate (local uuid + MongoDB _id) in UI.
//           await _fetchFromBackendAndRefresh();
//           _log('Group created and synced ✅');
//         } else {
//           _logError('Sync failed — group stays PENDING until internet returns');
//           // Group stays in UI as PENDING — ConnectivityService will retry
//         }
//       } else {
//         _log('Offline — group is PENDING, syncs when internet returns');
//       }

//       return group;
//     } catch (e) {
//       _logError('createGroup error: $e');
//       return null;
//     }
//   }

//   // ── DELETE ────────────────────────────────────────────────
//   Future<bool> deleteGroup(String id) async {
//     try {
//       final group = _groups.firstWhere(
//         (g) => g.id == id,
//         orElse: () => throw Exception('Group not found'),
//       );

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

//   // ── UPDATE ────────────────────────────────────────────────
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

//   Future<void> initialize() async => await loadGroups();
// }

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

//   GroupProvider({
//     GroupRepository? groupRepository,
//   }) : _groupRepository = groupRepository ?? GroupRepository();

//   List<Group> get groups => _groups;
//   bool get isLoading => _isLoading;
//   String get lastError => _lastError;
//   String get lastMessage => _lastMessage;

//   void _log(String message) {
//     debugPrint('📦 GroupProvider: $message');
//     _lastMessage = message;
//   }

//   void _logError(String error) {
//     debugPrint('❌ GroupProvider Error: $error');
//     _lastError = error;
//   }

//   // ─────────────────────────────────────────────────────────
//   // SET AUTH — called right after login/signup
//   // ─────────────────────────────────────────────────────────
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
//     }
//   }

//   void clearAuthToken() {
//     _authToken = null;
//     _log('Auth token cleared');
//   }

//   // ─────────────────────────────────────────────────────────
//   // LOGOUT — only clear RAM, keep SQLite
//   // SQLite is safe because every query filters by userId
//   // ─────────────────────────────────────────────────────────
//   Future<void> clearForLogout() async {
//     _groups = [];
//     _authToken = null;
//     _userId = null;
//     _syncService = null;
//     notifyListeners();
//     _log('Cleared RAM on logout (SQLite kept for offline re-login)');
//   }

//   // ─────────────────────────────────────────────────────────
//   // LOAD GROUPS
//   // Flow:
//   //   1. Show SQLite data instantly (works offline, no flash)
//   //   2. Fetch from MongoDB in background
//   //   3. Save fresh data to SQLite
//   //   4. Reload from SQLite → update UI
//   // ─────────────────────────────────────────────────────────
//   Future<void> loadGroups() async {
//     if (_userId == null || _userId!.isEmpty) {
//       _log('No userId — skipping load');
//       return;
//     }

//     _isLoading = true;
//     notifyListeners();

//     try {
//       // STEP 1 — Load whatever is in SQLite right now (could be empty
//       // after first login, could have data if user logged in before)
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       _isLoading = false;
//       notifyListeners();
//       _log('SQLite has ${_groups.length} groups');

//       // STEP 2 — Fetch from backend and update SQLite + UI
//       if (_authToken != null && _authToken!.isNotEmpty) {
//         await _fetchFromBackendAndRefresh();
//       } else {
//         _log('No auth token — showing SQLite cache only');
//       }
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       _logError('loadGroups error: $e');
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // FETCH FROM BACKEND → SAVE TO SQLITE → REFRESH UI
//   // This is the core method that makes login "auto-load" work
//   // ─────────────────────────────────────────────────────────
//   Future<void> _fetchFromBackendAndRefresh() async {
//     if (_syncService == null || _userId == null) return;

//     try {
//       _log('Fetching groups from MongoDB...');

//       // Push any local PENDING groups to backend first
//       await _syncService!.syncPendingGroups(_authToken!);

//       // Pull all groups for this user from MongoDB
//       // SyncService saves each one to SQLite internally
//       final backendGroups =
//           await _syncService!.fetchAndSyncGroups(_authToken!);

//       _log('Got ${backendGroups.length} groups from MongoDB');

//       // Reload from SQLite — now has the fresh backend data
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       notifyListeners();

//       _log('UI updated with ${_groups.length} groups ✅');
//     } catch (e) {
//       // Network error — that's fine, SQLite data already showing
//       _logError('Backend fetch failed (using cache): $e');
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // PUBLIC SYNC — called by ConnectivityService when
//   // internet comes back
//   // ─────────────────────────────────────────────────────────
//   Future<void> syncWithBackend() async {
//     if (_authToken == null || _authToken!.isEmpty) {
//       _logError('No auth token for sync');
//       return;
//     }
//     if (_syncService == null || _userId == null) {
//       _logError('SyncService not ready');
//       return;
//     }

//     try {
//       await _fetchFromBackendAndRefresh();
//     } catch (e) {
//       _logError('syncWithBackend error: $e');
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // CREATE GROUP
//   // ─────────────────────────────────────────────────────────
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

//       // Save locally first — UI updates instantly
//       await _groupRepository.addGroup(group);
//       _groups.insert(0, group);
//       notifyListeners();
//       _log('Saved to SQLite: ${group.id}');

//       // Try backend sync immediately
//       if (_authToken != null &&
//           _authToken!.isNotEmpty &&
//           _syncService != null) {
//         final result =
//             await _syncService!.syncGroupImmediately(group, _authToken!);

//         if (result['success'] == true) {
//           final synced = group.copyWith(syncStatus: 'SYNCED');
//           final index = _groups.indexWhere((g) => g.id == group.id);
//           if (index != -1) {
//             _groups[index] = synced;
//             await _groupRepository.updateGroup(synced);
//             notifyListeners();
//           }
//           _log('Synced to backend ✅');
//         } else {
//           _logError('Backend sync failed — will retry when online');
//         }
//       } else {
//         _log('Offline — group is PENDING, syncs when internet returns');
//       }

//       return group;
//     } catch (e) {
//       _logError('createGroup error: $e');
//       return null;
//     }
//   }

//   // ─────────────────────────────────────────────────────────
//   // DELETE GROUP
//   // ─────────────────────────────────────────────────────────
//   Future<bool> deleteGroup(String id) async {
//     try {
//       final group = _groups.firstWhere(
//         (g) => g.id == id,
//         orElse: () => throw Exception('Group not found'),
//       );

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

//   // ─────────────────────────────────────────────────────────
//   // UPDATE GROUP
//   // ─────────────────────────────────────────────────────────
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

//   Future<void> initialize() async => await loadGroups();
// }

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

//   // ✅ SyncService is created lazily once we have userId
//   SyncService? _syncService;

//   GroupProvider({
//     GroupRepository? groupRepository,
//   }) : _groupRepository = groupRepository ?? GroupRepository();

//   List<Group> get groups => _groups;
//   bool get isLoading => _isLoading;
//   String get lastError => _lastError;
//   String get lastMessage => _lastMessage;

//   void _log(String message) {
//     debugPrint('📦 GroupProvider: $message');
//     _lastMessage = message;
//   }

//   void _logError(String error) {
//     debugPrint('❌ GroupProvider Error: $error');
//     _lastError = error;
//   }

//   // ── Called right after login/signup ──────────────────────
//   void setAuthToken(String token) {
//     _authToken = token;
//     _rebuildSyncService();
//     _log('Auth token set');
//   }

//   // ── Called right after login/signup ──────────────────────
//   void setUserId(String userId) {
//     _userId = userId;
//     _rebuildSyncService();
//     _log('UserId set: $userId');
//   }

//   // ── Rebuild SyncService whenever token or userId changes ─
//   void _rebuildSyncService() {
//     if (_userId != null && _userId!.isNotEmpty) {
//       _syncService = SyncService(userId: _userId);
//     }
//   }

//   // ── Clear on logout ───────────────────────────────────────
//   void clearAuthToken() {
//     _authToken = null;
//     _log('Auth token cleared');
//   }

//   Future<void> clearForLogout() async {
//     if (_userId != null) {
//       await _groupRepository.clearUserGroups(_userId!);
//     }
//     _groups = [];
//     _authToken = null;
//     _userId = null;
//     _syncService = null;
//     notifyListeners();
//     _log('GroupProvider cleared for logout');
//   }

//   // ── Load only this user's groups ─────────────────────────
//   Future<void> loadGroups() async {
//     if (_userId == null || _userId!.isEmpty) {
//       _log('No userId — skipping group load');
//       return;
//     }

//     _isLoading = true;
//     notifyListeners();

//     try {
//       _log('Loading groups for user: $_userId');
//       _groups = await _groupRepository.fetchGroups(_userId!);
//       _log('Loaded ${_groups.length} groups');

//       if (_authToken != null && _authToken!.isNotEmpty) {
//         await syncWithBackend();
//       }
//     } catch (e) {
//       _logError('Error loading groups: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // ── Sync pending local → backend, then backend → local ───
//   Future<void> syncWithBackend() async {
//     if (_authToken == null || _authToken!.isEmpty) {
//       _logError('No auth token for sync');
//       return;
//     }
//     if (_syncService == null) {
//       _logError('SyncService not ready');
//       return;
//     }

//     try {
//       await _syncService!.syncPendingGroups(_authToken!);
//       final backendGroups =
//           await _syncService!.fetchAndSyncGroups(_authToken!);

//       if (backendGroups.isNotEmpty) {
//         _groups = await _groupRepository.fetchGroups(_userId!);
//         _log('Sync done. Total groups: ${_groups.length}');
//         notifyListeners();
//       }
//     } catch (e) {
//       _logError('Sync error: $e');
//     }
//   }

//   // ── Create a new group ────────────────────────────────────
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
//       _logError('Cannot create group — no userId set');
//       return null;
//     }

//     try {
//       _log('Creating group: $name for user: $_userId');

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

//       // 1. Save to SQLite first — works offline
//       await _groupRepository.addGroup(group);
//       _groups.insert(0, group);
//       notifyListeners();
//       _log('Group saved locally: ${group.id}');

//       // 2. Try to sync to backend immediately
//       if (_authToken != null &&
//           _authToken!.isNotEmpty &&
//           _syncService != null) {
//         final syncResult =
//             await _syncService!.syncGroupImmediately(group, _authToken!);

//         if (syncResult['success'] == true) {
//           _log('Group synced to backend ✅');
//           final updated = group.copyWith(syncStatus: 'SYNCED');
//           final index = _groups.indexWhere((g) => g.id == group.id);
//           if (index != -1) {
//             _groups[index] = updated;
//             await _groupRepository.updateGroup(updated);
//             notifyListeners();
//           }
//         } else {
//           _logError(
//               'Sync failed: ${syncResult['message']} — will retry later');
//         }
//       } else {
//         _log('No auth token — group stays PENDING until login');
//       }

//       return group;
//     } catch (e) {
//       _logError('Error creating group: $e');
//       return null;
//     }
//   }

//   // ── Delete ────────────────────────────────────────────────
//   Future<bool> deleteGroup(String id) async {
//     try {
//       final group = _groups.firstWhere(
//         (g) => g.id == id,
//         orElse: () => throw Exception('Group not found'),
//       );

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
//       _logError('Error deleting group: $e');
//       return false;
//     }
//   }

//   // ── Update ────────────────────────────────────────────────
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
//       _logError('Error updating group: $e');
//       return false;
//     }
//   }

//   List<Group> getPendingGroups() =>
//       _groups.where((g) => g.syncStatus == 'PENDING').toList();

//   List<Group> getSyncedGroups() =>
//       _groups.where((g) => g.syncStatus == 'SYNCED').toList();

//   Future<void> initialize() async => await loadGroups();
// }
