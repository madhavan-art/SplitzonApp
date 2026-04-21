import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/services/storage_service.dart';

import '../local/database_helper.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';

class GroupRepository {
  final DatabaseHelper _databaseHelper;

  GroupRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // Existing methods (unchanged)
  // ─────────────────────────────────────────────────────────────
  Future<Group> addGroup(Group group) async {
    return await _databaseHelper.insertGroup(group);
  }

  Future<List<Group>> fetchGroups(String userId) async {
    return await _databaseHelper.getGroupsByUser(userId);
  }

  Future<int> updateGroup(Group group) async {
    return await _databaseHelper.updateGroup(group);
  }

  Future<int> deleteGroup(String id) async {
    return await _databaseHelper.deleteGroup(id);
  }

  Future<void> clearUserGroups(String userId) async {
    return await _databaseHelper.deleteAllGroupsForUser(userId);
  }

  // ─────────────────────────────────────────────────────────────
  // FIXED: ADD MEMBER (now sends correct payload)
  // ─────────────────────────────────────────────────────────────
  Future<void> addMembers({
    required String groupId,
    required List<Map<String, dynamic>> members,
  }) async {
    try {
      final token = await StorageService.getToken();

      final url = Uri.parse(
        "${ApiService.baseUrl.replaceAll('/auth', '')}/groups/add-member/$groupId",
      );

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        // ✅ NOW SENDING FULL MEMBER OBJECTS
        body: jsonEncode({"members": members}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'Unknown error';
        throw Exception(
          "Failed to add members (${response.statusCode}): $errorBody",
        );
      }

      debugPrint('✅ ${members.length} members added to group $groupId');
    } catch (e) {
      debugPrint("❌ Add members error: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FIXED: SYNC GROUP MEMBERS (correct parsing + handles 404 gracefully)
  // ─────────────────────────────────────────────────────────────
  Future<void> syncGroupMembers(String groupId) async {
    try {
      final token = await StorageService.getToken();

      final url = Uri.parse(
        "${ApiService.baseUrl.replaceAll('/auth', '')}/groups/$groupId",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ Sync group failed: ${response.statusCode} ${response.body}',
        );
        return; // Don't crash the UI
      }

      final data = jsonDecode(response.body);
      final groupJson = data["data"];

      if (groupJson == null) return;

      // ✅ FIXED: Use exact field names from backend
      final group = Group(
        id: groupJson["_id"] ?? groupJson["id"],
        // Backend uses createdBy, not userId → use it (or fallback)
        userId: groupJson["createdBy"] ?? groupJson["userId"] ?? "",
        name: groupJson["groupName"] ?? groupJson["name"] ?? "",
        description: groupJson["groupDescription"] ?? "",
        groupType: groupJson["groupType"] ?? "Other",
        currency: groupJson["currency"] ?? "INR",
        overallBudget: (groupJson["overallBudget"] is num)
            ? (groupJson["overallBudget"] as num).toDouble()
            : 0.0,
        myShare: (groupJson["myShare"] is num)
            ? (groupJson["myShare"] as num).toDouble()
            : 0.0,
        members: Member.fromJsonList(groupJson["members"] ?? []),
        createdBy: groupJson["createdBy"] ?? "",
        bannerImagePath: null, // not needed here
        bannerImageUrl: groupJson["bannerImage"] ?? "",
        createdAt: groupJson["createdAt"] != null
            ? DateTime.parse(groupJson["createdAt"])
            : DateTime.now(),
        syncStatus: "SYNCED",
      );

      await _databaseHelper.insertOrUpdateGroup(group);
      debugPrint(
        '✅ Group $groupId synced to local SQLite with ${group.members.length} members',
      );
    } catch (e) {
      debugPrint("❌ Sync group members error: $e");
      // Do NOT rethrow – we don't want to break the "Add Members" flow
    }
  }
}

// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:splitzon/api/api_controller.dart';
// import 'package:splitzon/services/storage_service.dart';

// import '../local/database_helper.dart';
// import '../models/group_model.dart';

// class GroupRepository {
//   final DatabaseHelper _databaseHelper;

//   GroupRepository({DatabaseHelper? databaseHelper})
//     : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

//   Future<Group> addGroup(Group group) async {
//     return await _databaseHelper.insertGroup(group);
//   }

//   // ─────────────────────────────────────────
//   // ADD MEMBER TO GROUP (API)
//   // ─────────────────────────────────────────

//   Future<void> addMember({
//     required String groupId,
//     required String memberId,
//   }) async {
//     try {
//       final token = await StorageService.getToken();

//       final url = Uri.parse(
//         "${ApiService.baseUrl.replaceAll('/auth', '')}/groups/add-member/$groupId",
//       );

//       final response = await http.put(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode({"memberId": memberId}),
//       );

//       if (response.statusCode != 200) {
//         throw Exception("Failed to add member: ${response.body}");
//       }
//     } catch (e) {
//       throw Exception("Add member error: $e");
//     }
//   }

//   // ← NOW requires userId — no more fetching everyone's groups
//   Future<List<Group>> fetchGroups(String userId) async {
//     return await _databaseHelper.getGroupsByUser(userId);
//   }

//   Future<int> updateGroup(Group group) async {
//     return await _databaseHelper.updateGroup(group);
//   }

//   Future<int> deleteGroup(String id) async {
//     return await _databaseHelper.deleteGroup(id);
//   }

//   // ← Called on logout to wipe local data for this user
//   Future<void> clearUserGroups(String userId) async {
//     return await _databaseHelper.deleteAllGroupsForUser(userId);
//   }

//   Future<void> syncGroupMembers(String groupId) async {
//     try {
//       final token = await StorageService.getToken();

//       final url = Uri.parse(
//         "${ApiService.baseUrl.replaceAll('/auth', '')}/groups/$groupId",
//       );

//       final response = await http.get(
//         url,
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final groupJson = data["data"];

//         final group = Group(
//           id: groupJson["_id"],
//           userId: groupJson["userId"],
//           name: groupJson["name"],
//           groupType: groupJson["groupType"],
//           members: List<String>.from(groupJson["members"]),
//           createdAt: DateTime.parse(groupJson["createdAt"]),
//           syncStatus: "SYNCED",
//         );

//         await _databaseHelper.insertOrUpdateGroup(group);
//       }
//     } catch (e) {
//       print("Sync group members error:");
//       print(e);
//     }
//   }
// }
