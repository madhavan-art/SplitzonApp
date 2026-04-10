import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/group_model.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE groups ADD COLUMN description TEXT DEFAULT ""');
      await db.execute('ALTER TABLE groups ADD COLUMN groupType TEXT DEFAULT "Other"');
      await db.execute('ALTER TABLE groups ADD COLUMN currency TEXT DEFAULT "INR"');
      await db.execute('ALTER TABLE groups ADD COLUMN overallBudget REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE groups ADD COLUMN myShare REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE groups ADD COLUMN createdBy TEXT DEFAULT ""');
      await db.execute('ALTER TABLE groups ADD COLUMN bannerImagePath TEXT DEFAULT ""');
      await db.execute('ALTER TABLE groups ADD COLUMN bannerImageUrl TEXT DEFAULT ""');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE groups ADD COLUMN userId TEXT NOT NULL DEFAULT ""');
    }
  }

  // ── INSERT (new group) ────────────────────────────────────
  Future<Group> insertGroup(Group group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // skip if id already exists
    );
    return group;
  }

  // ── INSERT OR REPLACE ─────────────────────────────────────
  // ✅ This is what fetchAndSyncGroups should use.
  // If the group already exists → update it.
  // If it doesn't exist yet    → insert it.
  // This is why 2 backend groups were becoming 1 — updateGroup
  // was silently doing nothing for rows that didn't exist yet.
  Future<void> insertOrUpdateGroup(Group group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // ← insert OR update
    );
  }

  // ── GET ALL GROUPS FOR A USER ─────────────────────────────
  Future<List<Group>> getGroupsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'groups',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Group.fromMap(map)).toList();
  }

  // ── UPDATE (existing group only) ──────────────────────────
  Future<int> updateGroup(Group group) async {
    final db = await database;
    return db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  // ── DELETE ONE ────────────────────────────────────────────
  Future<int> deleteGroup(String id) async {
    final db = await database;
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // ── DELETE ALL FOR USER ───────────────────────────────────
  Future<void> deleteAllGroupsForUser(String userId) async {
    final db = await database;
    await db.delete('groups', where: 'userId = ?', whereArgs: [userId]);
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
//       version: 3, // ← bumped from 2 to 3
//       onCreate: _createDB,
//       onUpgrade: _upgradeDB,
//     );
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
//       await db.execute('ALTER TABLE groups ADD COLUMN description TEXT DEFAULT ""');
//       await db.execute('ALTER TABLE groups ADD COLUMN groupType TEXT DEFAULT "Other"');
//       await db.execute('ALTER TABLE groups ADD COLUMN currency TEXT DEFAULT "INR"');
//       await db.execute('ALTER TABLE groups ADD COLUMN overallBudget REAL DEFAULT 0.0');
//       await db.execute('ALTER TABLE groups ADD COLUMN myShare REAL DEFAULT 0.0');
//       await db.execute('ALTER TABLE groups ADD COLUMN createdBy TEXT DEFAULT ""');
//       await db.execute('ALTER TABLE groups ADD COLUMN bannerImagePath TEXT DEFAULT ""');
//       await db.execute('ALTER TABLE groups ADD COLUMN bannerImageUrl TEXT DEFAULT ""');
//     }
//     if (oldVersion < 3) {
//       // ← NEW: add userId column to existing installs
//       await db.execute('ALTER TABLE groups ADD COLUMN userId TEXT NOT NULL DEFAULT ""');
//     }
//   }

//   // ── INSERT ────────────────────────────────────────────────
//   Future<Group> insertGroup(Group group) async {
//     final db = await database;
//     await db.insert('groups', group.toMap());
//     return group;
//   }

//   // ── GET ALL GROUPS FOR A SPECIFIC USER ───────────────────
//   // ← was fetchAll with no filter, now filters by userId
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

//   // ── UPDATE ────────────────────────────────────────────────
//   Future<int> updateGroup(Group group) async {
//     final db = await database;
//     return db.update(
//       'groups',
//       group.toMap(),
//       where: 'id = ?',
//       whereArgs: [group.id],
//     );
//   }

//   // ── DELETE ────────────────────────────────────────────────
//   Future<int> deleteGroup(String id) async {
//     final db = await database;
//     return db.delete(
//       'groups',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }

//   // ── DELETE ALL GROUPS FOR A USER (called on logout) ───────
//   Future<void> deleteAllGroupsForUser(String userId) async {
//     final db = await database;
//     await db.delete(
//       'groups',
//       where: 'userId = ?',
//       whereArgs: [userId],
//     );
//   }

//   Future close() async {
//     final db = await database;
//     db.close();
//   }
// }