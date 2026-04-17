// ════════════════════════════════════════════════════════════════
// FILE: lib/data/local/database_helper.dart
// ════════════════════════════════════════════════════════════════

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
      version: 6, // ← bumped to 6 for activities table
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
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Group.fromMap(m)).toList();
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
    await db.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityModel>> getAllActivities() async {
    final db = await database;
    final maps = await db.query('activities', orderBy: 'timestamp DESC');
    return maps.map((m) => ActivityModel.fromMap(m)).toList();
  }

  Future<void> clearAllActivities() async {
    final db = await database;
    await db.delete('activities');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}


// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import '../models/group_model.dart';

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();
//   static Database? _database;

//   DatabaseHelper._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('splitzon.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);

//     return await openDatabase(
//       path,
//       version: 3,
//       onCreate: _createDB,
//       onUpgrade: _upgradeDB,
//     );
//   }

//   Future<void> debugPrintAllGroups() async {
//     final db = await database;

//     final rows = await db.query('groups');

//     print("===== SQLITE GROUPS DEBUG =====");

//     if (rows.isEmpty) {
//       print("No groups in SQLite");
//       return;
//     }

//     for (final row in rows) {
//       print("ID: ${row['id']}");
//       print("userId: ${row['userId']}");
//       print("name: ${row['name']}");
//       print("syncStatus: ${row['syncStatus']}");
//       print("----------------------------");
//     }
//   }

//   Future<void> _createDB(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE groups (
//         id TEXT PRIMARY KEY,
//         userId TEXT NOT NULL DEFAULT "",
//         name TEXT NOT NULL,
//         description TEXT DEFAULT "",
//         groupType TEXT DEFAULT "Other",
//         currency TEXT DEFAULT "INR",
//         overallBudget REAL DEFAULT 0.0,
//         myShare REAL DEFAULT 0.0,
//         members TEXT NOT NULL,
//         createdBy TEXT DEFAULT "",
//         bannerImagePath TEXT DEFAULT "",
//         bannerImageUrl TEXT DEFAULT "",
//         createdAt TEXT NOT NULL,
//         syncStatus TEXT NOT NULL
//       )
//     ''');
//   }

//   Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
//     if (oldVersion < 2) {
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN description TEXT DEFAULT ""',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN groupType TEXT DEFAULT "Other"',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN currency TEXT DEFAULT "INR"',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN overallBudget REAL DEFAULT 0.0',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN myShare REAL DEFAULT 0.0',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN createdBy TEXT DEFAULT ""',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN bannerImagePath TEXT DEFAULT ""',
//       );
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN bannerImageUrl TEXT DEFAULT ""',
//       );
//     }
//     if (oldVersion < 3) {
//       await db.execute(
//         'ALTER TABLE groups ADD COLUMN userId TEXT NOT NULL DEFAULT ""',
//       );
//     }
//   }

//   // ── INSERT (new group) ────────────────────────────────────
//   Future<Group> insertGroup(Group group) async {
//     final db = await database;
//     await db.insert(
//       'groups',
//       group.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.ignore, // skip if id already exists
//     );
//     return group;
//   }

//   // ── INSERT OR REPLACE ─────────────────────────────────────
//   // ✅ This is what fetchAndSyncGroups should use.
//   // If the group already exists → update it.
//   // If it doesn't exist yet    → insert it.
//   // This is why 2 backend groups were becoming 1 — updateGroup
//   // was silently doing nothing for rows that didn't exist yet.
//   Future<void> insertOrUpdateGroup(Group group) async {
//     final db = await database;
//     await db.insert(
//       'groups',
//       group.toMap(),
//       conflictAlgorithm: ConflictAlgorithm.replace, // ← insert OR update
//     );
//   }

//   // ── GET ALL GROUPS FOR A USER ─────────────────────────────
//   Future<List<Group>> getGroupsByUser(String userId) async {
//     final db = await database;
//     final maps = await db.query(
//       'groups',
//       where: 'userId = ?',
//       whereArgs: [userId],
//       orderBy: 'createdAt DESC',
//     );
//     return maps.map((map) => Group.fromMap(map)).toList();
//   }

//   // ── UPDATE (existing group only) ──────────────────────────
//   Future<int> updateGroup(Group group) async {
//     final db = await database;
//     return db.update(
//       'groups',
//       group.toMap(),
//       where: 'id = ?',
//       whereArgs: [group.id],
//     );
//   }

//   // ── DELETE ONE ────────────────────────────────────────────
//   Future<int> deleteGroup(String id) async {
//     final db = await database;
//     return db.delete('groups', where: 'id = ?', whereArgs: [id]);
//   }

//   // ── DELETE ALL FOR USER ───────────────────────────────────
//   Future<void> deleteAllGroupsForUser(String userId) async {
//     final db = await database;
//     await db.delete('groups', where: 'userId = ?', whereArgs: [userId]);
//   }

//   Future close() async {
//     final db = await database;
//     db.close();
//   }
// }

