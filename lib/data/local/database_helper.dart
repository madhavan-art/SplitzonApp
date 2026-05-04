// ════════════════════════════════════════════════════════════════
// FILE: lib/data/local/database_helper.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:splitzon/data/models/settlement_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../model/user.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../../features/commentActivity/activity_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('splitzon.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 10, // ← bumped to 8 for bannerPublicId column
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ── GROUPS TABLE ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL DEFAULT "",
        name TEXT NOT NULL,
        description TEXT DEFAULT "",
        groupType TEXT DEFAULT "Other",
        currency TEXT DEFAULT "INR",
        overallBudget REAL DEFAULT 0.0,
        myShare REAL DEFAULT 0.0,
        members TEXT NOT NULL,
        createdBy TEXT DEFAULT "",
        bannerImagePath TEXT DEFAULT "",
        bannerImageUrl TEXT DEFAULT "",
        bannerPublicId TEXT DEFAULT "",
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL
      )
    ''');

    // ── EXPENSES TABLE ────────────────────────────────────────
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        userId TEXT NOT NULL DEFAULT "",
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT DEFAULT "Other",
        notes TEXT DEFAULT "",
        date TEXT NOT NULL,
        paidByUserId TEXT DEFAULT "",
        paidByName TEXT DEFAULT "",
        splitType TEXT DEFAULT "equal",
        memberShares TEXT DEFAULT "[]",
        syncStatus TEXT NOT NULL DEFAULT "PENDING"
      )
    ''');

    // ── USERS TABLE ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        profile TEXT DEFAULT "",
        syncStatus TEXT NOT NULL DEFAULT "SYNCED"
      )
    ''');

    // ── ACTIVITIES TABLE ───────────────────────────────────────
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        groupId TEXT NOT NULL DEFAULT "",
        groupName TEXT NOT NULL DEFAULT "",
        userId TEXT NOT NULL DEFAULT "",
        userName TEXT NOT NULL DEFAULT "",
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // SETTLEMENTS TABLE - NEW
    await db.execute('''
    CREATE TABLE settlements (
      id TEXT PRIMARY KEY,
      groupId TEXT NOT NULL,
      fromUserId TEXT NOT NULL,
      fromUserName TEXT NOT NULL,
      toUserId TEXT NOT NULL,
      toUserName TEXT NOT NULL,
      amount REAL NOT NULL,
      notes TEXT DEFAULT "",
      date TEXT NOT NULL,
      syncStatus TEXT NOT NULL DEFAULT "PENDING"
    )
  ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE groups ADD COLUMN description TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN groupType TEXT DEFAULT "Other"',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN currency TEXT DEFAULT "INR"',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN overallBudget REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN myShare REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN createdBy TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN bannerImagePath TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE groups ADD COLUMN bannerImageUrl TEXT DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE groups ADD COLUMN userId TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 4) {
      // Add expenses table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id TEXT PRIMARY KEY,
          groupId TEXT NOT NULL,
          userId TEXT NOT NULL DEFAULT "",
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT DEFAULT "Other",
          notes TEXT DEFAULT "",
          date TEXT NOT NULL,
          paidByUserId TEXT DEFAULT "",
          paidByName TEXT DEFAULT "",
          splitType TEXT DEFAULT "equal",
          memberShares TEXT DEFAULT "[]",
          syncStatus TEXT NOT NULL DEFAULT "PENDING"
        )
      ''');
    }

    if (oldVersion < 5) {
      // Add users table for profile sync
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          phone TEXT NOT NULL,
          profile TEXT DEFAULT "",
          syncStatus TEXT NOT NULL DEFAULT "SYNCED"
        )
      ''');
    }

    if (oldVersion < 6) {
      // Add activities table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activities (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          groupId TEXT NOT NULL DEFAULT "",
          groupName TEXT NOT NULL DEFAULT "",
          userId TEXT NOT NULL DEFAULT "",
          userName TEXT NOT NULL DEFAULT "",
          timestamp TEXT NOT NULL,
          metadata TEXT
        )
      ''');
    }

    if (oldVersion < 7) {
      // Recreate activities table properly
      await db.execute('DROP TABLE IF EXISTS activities');
      await db.execute('''
        CREATE TABLE activities (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          groupId TEXT NOT NULL DEFAULT "",
          groupName TEXT NOT NULL DEFAULT "",
          userId TEXT NOT NULL DEFAULT "",
          userName TEXT NOT NULL DEFAULT "",
          timestamp TEXT NOT NULL,
          metadata TEXT
        )
      ''');
      // Removed debug print
    }

    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE groups ADD COLUMN bannerPublicId TEXT DEFAULT ""',
      );
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE activities ADD COLUMN syncStatus TEXT NOT NULL DEFAULT "PENDING"',
      );
    }
    // Version 10: Settlements Table
    if (oldVersion < 10) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS settlements (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        fromUserId TEXT NOT NULL,
        fromUserName TEXT NOT NULL,
        toUserId TEXT NOT NULL,
        toUserName TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT DEFAULT "",
        date TEXT NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT "PENDING"
      )
    ''');
    }
  }

  // ════════════════════════════════════════════════════════════
  // GROUP METHODS
  // ════════════════════════════════════════════════════════════

  Future<Group> insertGroup(Group group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return group;
  }

  Future<void> insertOrUpdateGroup(Group group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Group>> getGroupsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'groups',
      where: 'userId = ? AND syncStatus != ?',
      whereArgs: [userId, 'PENDING_DELETE'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Group.fromMap(map)).toList();
  }

  Future<int> updateGroup(Group group) async {
    final db = await database;
    return db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(String id) async {
    final db = await database;
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllGroupsForUser(String userId) async {
    final db = await database;
    await db.delete('groups', where: 'userId = ?', whereArgs: [userId]);
  }

  // ════════════════════════════════════════════════════════════
  // EXPENSE METHODS
  // ════════════════════════════════════════════════════════════

  /// Insert new expense — skip if id already exists
  Future<Expense> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return expense;
  }

  /// Insert OR replace (used when syncing from backend)
  Future<void> insertOrUpdateExpense(Expense expense) async {
    final db = await database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all expenses for a specific group
  Future<List<Expense>> getExpensesByGroup(String groupId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// Get all PENDING expenses for a user (for offline sync)
  Future<List<Expense>> getPendingExpensesByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'userId = ? AND syncStatus = ?',
      whereArgs: [userId, 'PENDING'],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all expenses for a group (called when group is deleted)
  Future<void> deleteExpensesByGroup(String groupId) async {
    final db = await database;
    await db.delete('expenses', where: 'groupId = ?', whereArgs: [groupId]);
  }

  // ════════════════════════════════════════════════════════════
  // USER METHODS
  // ════════════════════════════════════════════════════════════

  Future<void> insertOrUpdateUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ════════════════════════════════════════════════════════════
  // ACTIVITY METHODS
  // ════════════════════════════════════════════════════════════

  Future<void> insertActivity(ActivityModel activity) async {
    final db = await database;
    debugPrint(
      '💾 DB: Inserting activity: ${activity.title} | ID: ${activity.id}',
    );
    final result = await db.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('💾 DB: Insert result: $result');
  }

  Future<List<ActivityModel>> getAllActivities() async {
    final db = await database;
    debugPrint('💾 DB: Fetching all activities...');
    final maps = await db.query('activities', orderBy: 'timestamp DESC');
    debugPrint('💾 DB: Found ${maps.length} activities in database');

    for (var i = 0; i < maps.length; i++) {
      debugPrint(
        '💾 DB Activity $i: ${maps[i]['title']} | ${maps[i]['timestamp']}',
      );
    }

    return maps.map((m) => ActivityModel.fromMap(m)).toList();
  }

  Future<void> clearAllActivities() async {
    final db = await database;
    debugPrint(
      '⚠️  DB: CLEARING ALL ACTIVITIES!!! Stack trace: ${StackTrace.current}',
    );
    final count = await db.delete('activities');
    debugPrint('⚠️  DB: Deleted $count activities');
  }

  /// Get all activities filtered for a specific groupId only
  Future<List<ActivityModel>> getActivitiesByGroupId(String groupId) async {
    final db = await database;
    debugPrint('💾 DB: Fetching activities for group: $groupId');
    final maps = await db.query(
      'activities',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'timestamp DESC',
    );
    debugPrint('💾 DB: Found ${maps.length} activities for this group');
    return maps.map((m) => ActivityModel.fromMap(m)).toList();
  }

  Future close() async {
    final db = await database;
    db.close();
  }

  // ====================== SETTLEMENT METHODS ======================

  /// Insert a new settlement
  Future<Settlement> insertSettlement(Settlement settlement) async {
    final db = await database;
    await db.insert(
      'settlements',
      settlement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return settlement;
  }

  /// Get all settlements for a specific group
  Future<List<Settlement>> getSettlementsByGroup(String groupId) async {
    final db = await database;
    final maps = await db.query(
      'settlements',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Settlement.fromMap(m)).toList();
  }

  /// Get all pending settlements (for sync)
  Future<List<Settlement>> getPendingSettlements() async {
    final db = await database;
    final maps = await db.query(
      'settlements',
      where: 'syncStatus = ?',
      whereArgs: ['PENDING'],
    );
    return maps.map((m) => Settlement.fromMap(m)).toList();
  }

  /// Mark a settlement as synced after successful backend sync
  Future<int> markSettlementAsSynced(String id) async {
    final db = await database;
    return await db.update(
      'settlements',
      {'syncStatus': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a settlement (optional)
  Future<int> deleteSettlement(String id) async {
    final db = await database;
    return await db.delete('settlements', where: 'id = ?', whereArgs: [id]);
  }
}
