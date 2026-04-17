import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../commentActivity/activity_model.dart';
import '../../data/local/database_helper.dart';

class ActivityController with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<ActivityModel> _activities = [];
  bool _isLoading = false;

  List<ActivityModel> get activities => List.unmodifiable(_activities);
  bool get isLoading => _isLoading;

  void _log(String message) {
    debugPrint('📋 ActivityController: $message');
  }

  // Initialize and load all activities
  Future<void> initialize() async {
    _log('🔄 initialize() CALLED - Starting load activities');
    _isLoading = true;
    notifyListeners();

    try {
      _log('📥 Calling dbHelper.getAllActivities()');
      // Load from SQLite
      _activities = await _dbHelper.getAllActivities();
      _log(
        '✅ FINISHED: Loaded ${_activities.length} activities into controller',
      );

      for (var i = 0; i < _activities.length; i++) {
        _log('📋 Controller Activity $i: ${_activities[i].title}');
      }
    } catch (e) {
      debugPrint('❌ Failed to load activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _log('🏁 initialize() COMPLETED');
    }
  }

  // Add new activity
  Future<void> addActivity({
    required String type,
    required String title,
    required String description,
    required String groupId,
    required String groupName,
    required String userId,
    required String userName,
    Map<String, dynamic>? metadata,
  }) async {
    _log('➕ addActivity() called for: $title');
    try {
      final activity = ActivityModel(
        id: _uuid.v4(),
        type: type,
        title: title,
        description: description,
        groupId: groupId,
        groupName: groupName,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      _log('💾 Saving to database...');
      await _dbHelper.insertActivity(activity);

      _log('✅ Saved! Adding to in-memory list');
      _activities.insert(0, activity);
      notifyListeners();

      _log('✅ Activity added successfully: $title');
    } catch (e) {
      debugPrint('❌ Failed to add activity: $e');
    }
  }

  // Clear all activities
  Future<void> clearAll() async {
    try {
      await _dbHelper.clearAllActivities();
      _activities.clear();
      notifyListeners();
      _log('Cleared all activities');
    } catch (e) {
      debugPrint('❌ Failed to clear activities: $e');
    }
  }

  // Get activities for a specific group only
  Future<List<ActivityModel>> getActivitiesForGroup(String groupId) async {
    _log('📋 Loading activities for group: $groupId');
    try {
      return await _dbHelper.getActivitiesByGroupId(groupId);
    } catch (e) {
      debugPrint('❌ Failed to load group activities: $e');
      return [];
    }
  }

  // Load group activities directly into the controller state
  Future<void> loadGroupActivities(String groupId) async {
    _log('🔄 loadGroupActivities() CALLED for group: $groupId');
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await getActivitiesForGroup(groupId);
      _log('✅ FINISHED: Loaded ${_activities.length} activities for group');
    } catch (e) {
      debugPrint('❌ Failed to load group activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for common activity types
  Future<void> logExpenseAdded(
    String expenseTitle,
    String groupId,
    String groupName,
    String userName,
    double amount,
  ) {
    return addActivity(
      type: 'add_expense',
      title: 'Expense Added',
      description:
          '$userName added "$expenseTitle" - ₹${amount.toStringAsFixed(2)}',
      groupId: groupId,
      groupName: groupName,
      userId: '',
      userName: userName,
      metadata: {'amount': amount},
    );
  }

  Future<void> logExpenseUpdated(
    String expenseTitle,
    String groupId,
    String groupName,
    String userName,
  ) {
    return addActivity(
      type: 'update',
      title: 'Expense Updated',
      description: '$userName updated expense "$expenseTitle"',
      groupId: groupId,
      groupName: groupName,
      userId: '',
      userName: userName,
    );
  }

  Future<void> logExpenseDeleted(
    String expenseTitle,
    String groupId,
    String groupName,
    String userName,
  ) {
    return addActivity(
      type: 'delete',
      title: 'Expense Deleted',
      description: '$userName deleted expense "$expenseTitle"',
      groupId: groupId,
      groupName: groupName,
      userId: '',
      userName: userName,
    );
  }

  Future<void> logMemberAdded(
    String memberName,
    String groupId,
    String groupName,
    String addedBy,
  ) {
    return addActivity(
      type: 'add_member',
      title: 'Member Added',
      description: '$addedBy added $memberName to the group',
      groupId: groupId,
      groupName: groupName,
      userId: '',
      userName: addedBy,
    );
  }

  Future<void> logGroupCreated(
    String groupId,
    String groupName,
    String createdBy,
  ) {
    return addActivity(
      type: 'create',
      title: 'Group Created',
      description: '$createdBy created group "$groupName"',
      groupId: groupId,
      groupName: groupName,
      userId: '',
      userName: createdBy,
    );
  }
}
