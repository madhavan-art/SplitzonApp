import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/data/repositories/group_repository.dart';
import 'package:splitzon/services/storage_service.dart';

class SearchedUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profilePicture;

  SearchedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePicture,
  });

  factory SearchedUser.fromJson(Map<String, dynamic> json) {
    return SearchedUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
    );
  }
}

class AddMembersController extends ChangeNotifier {
  final String groupId;
  final GroupRepository _groupRepository = GroupRepository();

  String searchQuery = '';
  bool isSearching = false;
  SearchedUser? searchedUser;

  // Temporary list to hold selected users before final add
  List<SearchedUser> selectedUsers = [];
  bool isSelected = false; // for current searched user

  AddMembersController({required this.groupId});

  Future<void> searchUsers(String query) async {
    searchQuery = query.trim();
    debugPrint('🔍 SEARCH: Query = "$searchQuery"');

    if (searchQuery.length < 3) {
      searchedUser = null;
      isSelected = false;
      notifyListeners();
      return;
    }

    isSearching = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        debugPrint('❌ No token found');
        searchedUser = null;
        return;
      }

      final base = ApiService.baseUrl.replaceAll('/auth', '');
      final url = Uri.parse("$base/friends/search-users?query=$searchQuery");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = (data['users'] ?? data['data'] ?? []) as List;

        if (users.isNotEmpty) {
          searchedUser = SearchedUser.fromJson(users.first);
          isSelected = selectedUsers.any((u) => u.id == searchedUser!.id);
          debugPrint('✅ FOUND USER: ${searchedUser!.name}');
        } else {
          searchedUser = null;
        }
      } else {
        searchedUser = null;
      }
    } catch (e) {
      debugPrint('💥 Search exception: $e');
      searchedUser = null;
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void toggleSelection() {
    if (searchedUser == null) return;

    isSelected = !isSelected;

    if (isSelected) {
      if (!selectedUsers.any((u) => u.id == searchedUser!.id)) {
        selectedUsers.add(searchedUser!);
        debugPrint('➕ Added to temporary list: ${searchedUser!.name}');
      }
    } else {
      selectedUsers.removeWhere((u) => u.id == searchedUser!.id);
      debugPrint('➖ Removed from temporary list: ${searchedUser!.name}');
    }

    notifyListeners();
  }

  void removeFromSelected(int index) {
    final removed = selectedUsers.removeAt(index);
    debugPrint('🗑 Removed from selected: ${removed.name}');
    // If currently searched user is removed, update its state
    if (searchedUser?.id == removed.id) {
      isSelected = false;
    }
    notifyListeners();
  }

  Future<bool> addAllSelectedMembers() async {
    if (selectedUsers.isEmpty) return false;

    debugPrint('🚀 Adding ${selectedUsers.length} members to group...');

    try {
      for (final user in selectedUsers) {
        await _groupRepository.addMember(groupId: groupId, memberId: user.id);
        debugPrint('✅ Added: ${user.name}');
      }

      await _groupRepository.syncGroupMembers(groupId);
      debugPrint('✅ Group synced successfully');

      return true;
    } catch (e) {
      debugPrint('💥 Failed to add members: $e');
      return false;
    }
  }
}

// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:splitzon/api/api_controller.dart';
// import 'package:splitzon/data/repositories/group_repository.dart';
// import 'package:splitzon/services/storage_service.dart';

// class SearchedUser {
//   final String id;
//   final String name;
//   final String email;
//   final String phone;
//   final String profilePicture;

//   SearchedUser({
//     required this.id,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.profilePicture,
//   });

//   factory SearchedUser.fromJson(Map<String, dynamic> json) {
//     return SearchedUser(
//       id: json['_id'] ?? json['id'] ?? '',
//       name: json['name'] ?? 'Unknown',
//       email: json['email'] ?? '',
//       phone: json['phone'] ?? '',
//       profilePicture: json['profilePicture'] ?? '',
//     );
//   }
// }

// class AddMembersController extends ChangeNotifier {
//   final String groupId;
//   final GroupRepository _groupRepository = GroupRepository();

//   String searchQuery = '';
//   bool isSearching = false;
//   SearchedUser? searchedUser;
//   bool isSelected = false;

//   AddMembersController({required this.groupId});

//   Future<void> searchUsers(String query) async {
//     searchQuery = query.trim();
//     debugPrint('🔍 SEARCH: Query = "$searchQuery"');

//     if (searchQuery.length < 3) {
//       searchedUser = null;
//       debugPrint('⚠️ Query too short. Cleared result.');
//       notifyListeners();
//       return;
//     }

//     isSearching = true;
//     notifyListeners();

//     try {
//       final token = await StorageService.getToken();
//       if (token == null) {
//         debugPrint('❌ No token found');
//         searchedUser = null;
//         return;
//       }

//       final base = ApiService.baseUrl.replaceAll('/auth', '');
//       final url = Uri.parse("$base/friends/search-users?query=$searchQuery");

//       debugPrint('📡 GET → $url');

//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );

//       debugPrint('📥 Status: ${response.statusCode}');
//       debugPrint('📥 Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final users = (data['users'] ?? data['data'] ?? []) as List;

//         debugPrint('📊 Received ${users.length} user(s)');

//         if (users.isNotEmpty) {
//           searchedUser = SearchedUser.fromJson(users.first);
//           debugPrint(
//             '✅ FOUND USER: ${searchedUser!.name} (${searchedUser!.email})',
//           );
//         } else {
//           searchedUser = null;
//           debugPrint('⚠️ No matching users');
//         }
//       } else {
//         debugPrint('❌ Backend error: ${response.statusCode}');
//         searchedUser = null;
//       }
//     } catch (e, stack) {
//       debugPrint('💥 EXCEPTION in searchUsers: $e');
//       debugPrint('Stack: $stack');
//       searchedUser = null;
//     } finally {
//       isSearching = false;
//       notifyListeners();
//     }
//   }

//   void toggleSelection() {
//     isSelected = !isSelected;
//     debugPrint('🔘 Checkbox changed → selected = $isSelected');
//     notifyListeners();
//   }

//   Future<bool> addMemberToGroup() async {
//     if (searchedUser == null || !isSelected) {
//       debugPrint('❌ Cannot add: user null or not selected');
//       return false;
//     }

//     debugPrint(
//       '🚀 Adding user "${searchedUser!.name}" (ID: ${searchedUser!.id}) to group $groupId',
//     );

//     try {
//       await _groupRepository.addMember(
//         groupId: groupId,
//         memberId: searchedUser!.id,
//       );
//       debugPrint('✅ addMember API succeeded');

//       await _groupRepository.syncGroupMembers(groupId);
//       debugPrint('✅ Group synced to local SQLite');

//       return true;
//     } catch (e, stack) {
//       debugPrint('💥 Add failed: $e');
//       debugPrint('Stack: $stack');
//       return false;
//     }
//   }
// }
