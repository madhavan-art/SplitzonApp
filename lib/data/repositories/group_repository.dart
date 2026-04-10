// import '../local/database_helper.dart';
// import '../models/group_model.dart';

// class GroupRepository {
//   final DatabaseHelper _databaseHelper;

//   GroupRepository({DatabaseHelper? databaseHelper})
//       : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

//   // Add a new group
//   Future<Group> addGroup(Group group) async {
//     return await _databaseHelper.insertGroup(group);
//   }

//   // Fetch all groups
//   Future<List<Group>> fetchGroups() async {
//     return await _databaseHelper.getAllGroups();
//   }

//   // Update a group
//   Future<int> updateGroup(Group group) async {
//     return await _databaseHelper.updateGroup(group);
//   }

//   // Delete a group
//   Future<int> deleteGroup(String id) async {
//     return await _databaseHelper.deleteGroup(id);
//   }
// }


import '../local/database_helper.dart';
import '../models/group_model.dart';

class GroupRepository {
  final DatabaseHelper _databaseHelper;

  GroupRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<Group> addGroup(Group group) async {
    return await _databaseHelper.insertGroup(group);
  }

  // ← NOW requires userId — no more fetching everyone's groups
  Future<List<Group>> fetchGroups(String userId) async {
    return await _databaseHelper.getGroupsByUser(userId);
  }

  Future<int> updateGroup(Group group) async {
    return await _databaseHelper.updateGroup(group);
  }

  Future<int> deleteGroup(String id) async {
    return await _databaseHelper.deleteGroup(id);
  }

  // ← Called on logout to wipe local data for this user
  Future<void> clearUserGroups(String userId) async {
    return await _databaseHelper.deleteAllGroupsForUser(userId);
  }
}