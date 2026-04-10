import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../data/models/group_model.dart';
import '../data/local/database_helper.dart';
import '../data/repositories/group_repository.dart';

class SyncService {
  static String baseUrl =
      "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/groups";

  static void setBaseUrl(String url) {
    baseUrl = url;
    debugPrint('🔧 SyncService Base URL set to: $baseUrl');
  }

  final GroupRepository _groupRepository;
  final DatabaseHelper _dbHelper;
  final String? userId;

  final Function(String message)? onMessage;
  final Function(String error)? onError;

  SyncService({
    GroupRepository? groupRepository,
    DatabaseHelper? dbHelper,
    this.onMessage,
    this.onError,
    this.userId,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  void _log(String message) {
    debugPrint('🔄 SyncService: $message');
    onMessage?.call(message);
  }

  void _logError(String error) {
    debugPrint('❌ SyncService Error: $error');
    onError?.call(error);
  }

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── SYNC ALL PENDING LOCAL GROUPS → BACKEND ───────────────
  Future<void> syncPendingGroups(String authToken) async {
    try {
      if (!await _isConnected()) {
        _log('No internet. Will sync when online.');
        return;
      }
      if (userId == null || userId!.isEmpty) {
        _logError('No userId — skipping pending sync');
        return;
      }

      _log('Checking for pending groups...');
      final groups = await _groupRepository.fetchGroups(userId!);
      final pending = groups.where((g) => g.syncStatus == 'PENDING').toList();

      if (pending.isEmpty) {
        _log('No pending groups.');
        return;
      }

      _log('Found ${pending.length} pending group(s) to sync.');
      for (final group in pending) {
        await _syncGroupToBackend(group, authToken);
      }
      _log('Sync process completed.');
    } catch (e) {
      _logError('syncPendingGroups error: $e');
    }
  }

  // ── PUSH ONE GROUP TO BACKEND ─────────────────────────────
  Future<Map<String, dynamic>> _syncGroupToBackend(
      Group group, String authToken) async {
    try {
      _log('Syncing group: ${group.name} (localId: ${group.id})');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/create'),
      );

      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['groupName'] = group.name;
      request.fields['groupDescription'] = group.description ?? '';
      request.fields['groupType'] = group.groupType;
      request.fields['currency'] = group.currency;
      request.fields['overallBudget'] = (group.overallBudget ?? 0).toString();
      request.fields['myShare'] = (group.myShare ?? 0).toString();
      request.fields['members'] = jsonEncode(group.members);

      if (group.bannerImagePath != null &&
          group.bannerImagePath!.isNotEmpty) {
        final file = File(group.bannerImagePath!);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'banner',
            group.bannerImagePath!,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseData.body);
        if (result['success'] == true) {
          // ✅ Backend saved successfully.
          // The backend created a NEW MongoDB _id for this group.
          // We must DELETE the local uuid version from SQLite now.
          // Otherwise when fetchAndSyncGroups runs, it will INSERT
          // the MongoDB version (new _id) AND keep the old uuid
          // version → duplicate in UI.
          await _dbHelper.deleteGroup(group.id);
          _log('Deleted local PENDING copy: ${group.id}');

          // The correct SYNCED version with MongoDB _id will be
          // inserted by fetchAndSyncGroups right after this.
          _log('Synced successfully. MongoDB will return correct version.');
          return {'success': true};
        } else {
          final msg = result['message'] ?? 'Unknown error';
          _logError('Sync failed: $msg');
          return {'success': false, 'message': msg};
        }
      } else {
        final msg = 'HTTP ${response.statusCode}: ${responseData.body}';
        _logError('HTTP error: $msg');
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      _logError('_syncGroupToBackend exception: $e');
      return {'success': false, 'message': '$e'};
    }
  }

  // ── FETCH ALL USER GROUPS FROM BACKEND → SAVE TO SQLITE ──
  Future<List<Group>> fetchAndSyncGroups(String authToken) async {
    try {
      if (!await _isConnected()) {
        _log('No internet. Cannot fetch from backend.');
        return [];
      }
      if (userId == null || userId!.isEmpty) {
        _logError('No userId — skipping fetch');
        return [];
      }

      _log('Fetching groups from backend...');
      final response = await http.get(
        Uri.parse('$baseUrl/my-groups'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final backendGroups = result['data'] as List;
          _log('Found ${backendGroups.length} groups in backend');

          final synced = <Group>[];
          for (final bg in backendGroups) {
            try {
              final group = Group(
                id: bg['_id'] ?? bg['id'],   // ← MongoDB _id
                userId: userId!,
                name: bg['groupName'],
                description: bg['groupDescription'] ?? '',
                groupType: bg['groupType'] ?? 'Other',
                currency: bg['currency'] ?? 'INR',
                overallBudget: (bg['overallBudget'] is num)
                    ? (bg['overallBudget'] as num).toDouble()
                    : 0.0,
                myShare: (bg['myShare'] is num)
                    ? (bg['myShare'] as num).toDouble()
                    : 0.0,
                members: List<String>.from(bg['members'] ?? []),
                createdBy: bg['createdBy'] ?? '',
                bannerImageUrl: bg['bannerImage'] ?? '',
                createdAt: bg['createdAt'] != null
                    ? DateTime.parse(bg['createdAt'])
                    : DateTime.now(),
                syncStatus: 'SYNCED',
              );

              // insertOrUpdate: insert if new, replace if exists
              await _dbHelper.insertOrUpdateGroup(group);
              synced.add(group);
            } catch (e) {
              _logError('Error processing group: $e');
            }
          }

          _log('Fetched and synced ${synced.length} groups');
          return synced;
        }
      }

      _logError('Fetch failed: HTTP ${response.statusCode}');
      return [];
    } catch (e) {
      _logError('fetchAndSyncGroups error: $e');
      return [];
    }
  }

  // ── SYNC SINGLE GROUP IMMEDIATELY (called on createGroup) ─
  // For immediate sync we follow the same pattern:
  // 1. Push to backend
  // 2. Delete local PENDING copy
  // 3. Return success so GroupProvider knows to reload from SQLite
  Future<Map<String, dynamic>> syncGroupImmediately(
      Group group, String authToken) async {
    return await _syncGroupToBackend(group, authToken);
  }

  // ── DELETE FROM BACKEND ───────────────────────────────────
  Future<bool> deleteGroupFromBackend(
      String groupId, String authToken) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$groupId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _log('Deleted from backend: $groupId');
        return true;
      }
      _logError('Delete failed: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      _logError('deleteGroupFromBackend error: $e');
      return false;
    }
  }
}

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../data/models/group_model.dart';
// import '../data/local/database_helper.dart';
// import '../data/repositories/group_repository.dart';

// class SyncService {
//   static String baseUrl =
//       "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/groups";

//   static void setBaseUrl(String url) {
//     baseUrl = url;
//     debugPrint('🔧 SyncService Base URL set to: $baseUrl');
//   }

//   final GroupRepository _groupRepository;
//   final DatabaseHelper _dbHelper;
//   final String? userId;

//   final Function(String message)? onMessage;
//   final Function(String error)? onError;

//   SyncService({
//     GroupRepository? groupRepository,
//     DatabaseHelper? dbHelper,
//     this.onMessage,
//     this.onError,
//     this.userId,
//   })  : _groupRepository = groupRepository ?? GroupRepository(),
//         _dbHelper = dbHelper ?? DatabaseHelper.instance;

//   void _log(String message) {
//     debugPrint('🔄 SyncService: $message');
//     onMessage?.call(message);
//   }

//   void _logError(String error) {
//     debugPrint('❌ SyncService Error: $error');
//     onError?.call(error);
//   }

//   Future<bool> _isConnected() async {
//     try {
//       final result = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 5));
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }

//   // ── SYNC PENDING LOCAL → BACKEND ─────────────────────────
//   Future<void> syncPendingGroups(String authToken) async {
//     try {
//       if (!await _isConnected()) {
//         _log('No internet. Will sync when online.');
//         return;
//       }
//       if (userId == null || userId!.isEmpty) {
//         _logError('No userId — skipping pending sync');
//         return;
//       }

//       _log('Checking for pending groups...');
//       final groups = await _groupRepository.fetchGroups(userId!);
//       final pending = groups.where((g) => g.syncStatus == 'PENDING').toList();

//       if (pending.isEmpty) {
//         _log('No pending groups.');
//         return;
//       }

//       _log('Found ${pending.length} pending group(s) to sync.');
//       for (final group in pending) {
//         await _syncGroupToBackend(group, authToken);
//       }
//       _log('Sync process completed.');
//     } catch (e) {
//       _logError('syncPendingGroups error: $e');
//     }
//   }

//   // ── PUSH ONE GROUP TO BACKEND ─────────────────────────────
//   Future<Map<String, dynamic>> _syncGroupToBackend(
//       Group group, String authToken) async {
//     try {
//       _log('Syncing group: ${group.name} (ID: ${group.id})');

//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/create'),
//       );

//       request.headers['Authorization'] = 'Bearer $authToken';
//       request.fields['groupName'] = group.name;
//       request.fields['groupDescription'] = group.description ?? '';
//       request.fields['groupType'] = group.groupType;
//       request.fields['currency'] = group.currency;
//       request.fields['overallBudget'] = (group.overallBudget ?? 0).toString();
//       request.fields['myShare'] = (group.myShare ?? 0).toString();
//       request.fields['members'] = jsonEncode(group.members);

//       if (group.bannerImagePath != null &&
//           group.bannerImagePath!.isNotEmpty) {
//         final file = File(group.bannerImagePath!);
//         if (await file.exists()) {
//           request.files.add(await http.MultipartFile.fromPath(
//             'banner',
//             group.bannerImagePath!,
//             contentType: MediaType('image', 'jpeg'),
//           ));
//         }
//       }

//       final response = await request.send();
//       final responseData = await http.Response.fromStream(response);
//       _log('Response status: ${response.statusCode}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final result = jsonDecode(responseData.body);
//         if (result['success'] == true) {
//           final synced = group.copyWith(
//             syncStatus: 'SYNCED',
//             bannerImageUrl: result['data']?['bannerImage'],
//           );
//           // Use insertOrUpdate so it works whether row exists or not
//           await _dbHelper.insertOrUpdateGroup(synced);
//           _log('Synced successfully: ${group.id}');
//           return {'success': true};
//         } else {
//           final msg = result['message'] ?? 'Unknown error';
//           _logError('Sync failed: $msg');
//           return {'success': false, 'message': msg};
//         }
//       } else {
//         final msg = 'HTTP ${response.statusCode}: ${responseData.body}';
//         _logError('HTTP error: $msg');
//         return {'success': false, 'message': msg};
//       }
//     } catch (e) {
//       _logError('_syncGroupToBackend exception: $e');
//       return {'success': false, 'message': '$e'};
//     }
//   }

//   // ── FETCH ALL USER GROUPS FROM BACKEND → SAVE TO SQLITE ──
//   Future<List<Group>> fetchAndSyncGroups(String authToken) async {
//     try {
//       if (!await _isConnected()) {
//         _log('No internet. Cannot fetch from backend.');
//         return [];
//       }
//       if (userId == null || userId!.isEmpty) {
//         _logError('No userId — skipping fetch');
//         return [];
//       }

//       _log('Fetching groups from backend...');
//       final response = await http.get(
//         Uri.parse('$baseUrl/my-groups'),
//         headers: {
//           'Authorization': 'Bearer $authToken',
//           'Content-Type': 'application/json',
//         },
//       );

//       _log('Response status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         if (result['success'] == true) {
//           final backendGroups = result['data'] as List;
//           _log('Found ${backendGroups.length} groups in backend');

//           final synced = <Group>[];
//           for (final bg in backendGroups) {
//             try {
//               final group = Group(
//                 id: bg['_id'] ?? bg['id'],
//                 userId: userId!,
//                 name: bg['groupName'],
//                 description: bg['groupDescription'] ?? '',
//                 groupType: bg['groupType'] ?? 'Other',
//                 currency: bg['currency'] ?? 'INR',
//                 overallBudget: (bg['overallBudget'] is num)
//                     ? (bg['overallBudget'] as num).toDouble()
//                     : 0.0,
//                 myShare: (bg['myShare'] is num)
//                     ? (bg['myShare'] as num).toDouble()
//                     : 0.0,
//                 members: List<String>.from(bg['members'] ?? []),
//                 createdBy: bg['createdBy'] ?? '',
//                 bannerImageUrl: bg['bannerImage'] ?? '',
//                 createdAt: bg['createdAt'] != null
//                     ? DateTime.parse(bg['createdAt'])
//                     : DateTime.now(),
//                 syncStatus: 'SYNCED',
//               );

//               // ✅ insertOrUpdate — works for BOTH new and existing rows
//               // This was the bug: updateGroup was silently skipping
//               // groups that didn't exist in SQLite yet
//               await _dbHelper.insertOrUpdateGroup(group);
//               synced.add(group);
//             } catch (e) {
//               _logError('Error processing group from backend: $e');
//             }
//           }

//           _log('Fetched and synced ${synced.length} groups');
//           return synced;
//         }
//       }

//       _logError('Fetch failed: HTTP ${response.statusCode}');
//       return [];
//     } catch (e) {
//       _logError('fetchAndSyncGroups error: $e');
//       return [];
//     }
//   }

//   // ── DELETE FROM BACKEND ───────────────────────────────────
//   Future<bool> deleteGroupFromBackend(
//       String groupId, String authToken) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/delete/$groupId'),
//         headers: {'Authorization': 'Bearer $authToken'},
//       );
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         _log('Deleted from backend: $groupId');
//         return true;
//       }
//       _logError('Delete failed: HTTP ${response.statusCode}');
//       return false;
//     } catch (e) {
//       _logError('deleteGroupFromBackend error: $e');
//       return false;
//     }
//   }

//   // ── SYNC SINGLE GROUP IMMEDIATELY ────────────────────────
//   Future<Map<String, dynamic>> syncGroupImmediately(
//       Group group, String authToken) async {
//     return await _syncGroupToBackend(group, authToken);
//   }
// }
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import '../data/models/group_model.dart';
// import '../data/local/database_helper.dart';
// import '../data/repositories/group_repository.dart';

// class SyncService {
//   static String baseUrl =
//       "https://nonsterile-smudgeless-candace.ngrok-free.dev/api/groups";

//   static void setBaseUrl(String url) {
//     baseUrl = url;
//     debugPrint('🔧 SyncService Base URL set to: $baseUrl');
//   }

//   final GroupRepository _groupRepository;
//   final DatabaseHelper _dbHelper;

//   final Function(String message)? onMessage;
//   final Function(String error)? onError;

//   // ✅ userId is now required so sync only touches the right user's data
//   final String? userId;

//   SyncService({
//     GroupRepository? groupRepository,
//     DatabaseHelper? dbHelper,
//     this.onMessage,
//     this.onError,
//     this.userId,
//   })  : _groupRepository = groupRepository ?? GroupRepository(),
//         _dbHelper = dbHelper ?? DatabaseHelper.instance;

//   void _log(String message) {
//     debugPrint('🔄 SyncService: $message');
//     onMessage?.call(message);
//   }

//   void _logError(String error) {
//     debugPrint('❌ SyncService Error: $error');
//     onError?.call(error);
//   }

//   Future<bool> _isConnected() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (e) {
//       _logError('No internet connection: $e');
//       return false;
//     }
//   }

//   /// Sync all PENDING groups for this user to backend
//   Future<void> syncPendingGroups(String authToken) async {
//     try {
//       if (!await _isConnected()) {
//         _log('No internet. Groups will sync when online.');
//         return;
//       }

//       if (userId == null || userId!.isEmpty) {
//         _logError('No userId set — skipping sync');
//         return;
//       }

//       _log('Checking for pending groups...');

//       // ✅ Fetch only THIS user's groups
//       final groups = await _groupRepository.fetchGroups(userId!);
//       final pendingGroups =
//           groups.where((g) => g.syncStatus == 'PENDING').toList();

//       if (pendingGroups.isEmpty) {
//         _log('No pending groups to sync.');
//         return;
//       }

//       _log('Found ${pendingGroups.length} pending group(s) to sync.');

//       for (final group in pendingGroups) {
//         await _syncGroupToBackend(group, authToken);
//       }

//       _log('Sync process completed.');
//     } catch (e) {
//       _logError('Sync error: $e');
//     }
//   }

//   /// Sync a single group to backend
//   Future<Map<String, dynamic>> _syncGroupToBackend(
//       Group group, String authToken) async {
//     try {
//       _log('Syncing group: ${group.name} (ID: ${group.id})');

//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/create'),
//       );

//       request.headers['Authorization'] = 'Bearer $authToken';

//       request.fields['groupName'] = group.name;
//       request.fields['groupDescription'] = group.description ?? '';
//       request.fields['groupType'] = group.groupType;
//       request.fields['currency'] = group.currency;
//       request.fields['overallBudget'] = (group.overallBudget ?? 0).toString();
//       request.fields['myShare'] = (group.myShare ?? 0).toString();
//       request.fields['members'] = jsonEncode(group.members);

//       if (group.bannerImagePath != null &&
//           group.bannerImagePath!.isNotEmpty) {
//         final file = File(group.bannerImagePath!);
//         if (await file.exists()) {
//           request.files.add(
//             await http.MultipartFile.fromPath(
//               'banner',
//               group.bannerImagePath!,
//               contentType: MediaType('image', 'jpeg'),
//             ),
//           );
//         }
//       }

//       final response = await request.send();
//       final responseData = await http.Response.fromStream(response);

//       _log('Response status: ${response.statusCode}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final result = jsonDecode(responseData.body);
//         if (result['success'] == true) {
//           final syncedGroup = group.copyWith(
//             syncStatus: 'SYNCED',
//             bannerImageUrl: result['data']?['bannerImage'],
//           );
//           await _dbHelper.updateGroup(syncedGroup);
//           _log('Group synced successfully: ${group.id}');
//           return {'success': true, 'message': 'Group synced'};
//         } else {
//           final errorMsg = result['message'] ?? 'Unknown error';
//           _logError('Sync failed: $errorMsg');
//           return {'success': false, 'message': errorMsg};
//         }
//       } else {
//         final errorMsg = 'HTTP ${response.statusCode}: ${responseData.body}';
//         _logError('HTTP error: $errorMsg');
//         return {'success': false, 'message': errorMsg};
//       }
//     } catch (e, stackTrace) {
//       _logError('Sync exception: $e\n$stackTrace');
//       return {'success': false, 'message': 'Exception: $e'};
//     }
//   }

//   /// Fetch user's groups from backend and sync to local DB
//   Future<List<Group>> fetchAndSyncGroups(String authToken) async {
//     try {
//       if (!await _isConnected()) {
//         _log('No internet. Cannot fetch groups from backend.');
//         return [];
//       }

//       if (userId == null || userId!.isEmpty) {
//         _logError('No userId set — skipping fetch');
//         return [];
//       }

//       _log('Fetching groups from backend...');

//       final response = await http.get(
//         Uri.parse('$baseUrl/my-groups'),
//         headers: {
//           'Authorization': 'Bearer $authToken',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         if (result['success'] == true) {
//           final backendGroups = result['data'] as List;
//           _log('Found ${backendGroups.length} groups in backend');

//           final syncedGroups = <Group>[];
//           for (final bg in backendGroups) {
//             try {
//               // ✅ userId is now stamped on every group from backend
//               final localGroup = Group(
//                 id: bg['_id'] ?? bg['id'],
//                 userId: userId!,          // ← stamp current user as owner
//                 name: bg['groupName'],
//                 description: bg['groupDescription'],
//                 groupType: bg['groupType'],
//                 currency: bg['currency'] ?? 'INR',
//                 overallBudget: (bg['overallBudget'] is num)
//                     ? (bg['overallBudget'] as num).toDouble()
//                     : 0.0,
//                 myShare: (bg['myShare'] is num)
//                     ? (bg['myShare'] as num).toDouble()
//                     : 0.0,
//                 members: List<String>.from(bg['members'] ?? []),
//                 createdBy: bg['createdBy'],
//                 bannerImageUrl: bg['bannerImage'],
//                 createdAt: bg['createdAt'] != null
//                     ? DateTime.parse(bg['createdAt'])
//                     : DateTime.now(),
//                 syncStatus: 'SYNCED',
//               );

//               await _dbHelper.updateGroup(localGroup);
//               syncedGroups.add(localGroup);
//             } catch (e) {
//               _logError('Error processing group: $e');
//             }
//           }

//           _log('Fetched and synced ${syncedGroups.length} groups');
//           return syncedGroups;
//         }
//       }

//       _logError('Fetch failed: HTTP ${response.statusCode}');
//       return [];
//     } catch (e) {
//       _logError('Fetch error: $e');
//       return [];
//     }
//   }

//   /// Delete group from backend
//   Future<bool> deleteGroupFromBackend(
//       String groupId, String authToken) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/delete/$groupId'),
//         headers: {'Authorization': 'Bearer $authToken'},
//       );

//       if (response.statusCode == 200 || response.statusCode == 204) {
//         _log('Group deleted from backend: $groupId');
//         return true;
//       }
//       _logError('Delete failed: HTTP ${response.statusCode}');
//       return false;
//     } catch (e) {
//       _logError('Delete error: $e');
//       return false;
//     }
//   }

//   /// Sync a single group immediately (called after creating a group)
//   Future<Map<String, dynamic>> syncGroupImmediately(
//       Group group, String authToken) async {
//     return await _syncGroupToBackend(group, authToken);
//   }
// }