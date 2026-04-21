// import 'dart:convert';
// import 'package:uuid/uuid.dart';

// class Group {
//   final String id;
//   final String name;              // groupName
//   final String? description;      // groupDescription
//   final String groupType;         // Trip, Food, Home, Office, Shopping, Other
//   final String currency;          // INR, USD, etc.
//   final double? overallBudget;    // Overall budget
//   final double? myShare;          // My share amount
//   final List<String> members;     // Member user IDs
//   final String? createdBy;        // User ID who created
//   final String? bannerImagePath;  // Local file path for banner image
//   final String? bannerImageUrl;   // URL after upload to Cloudinary
//   final DateTime createdAt;
//   final String syncStatus;        // PENDING, SYNCED

//   Group({
//     required this.id,
//     required this.name,
//     this.description,
//     required this.groupType,
//     this.currency = 'INR',
//     this.overallBudget,
//     this.myShare,
//     required this.members,
//     this.createdBy,
//     this.bannerImagePath,
//     this.bannerImageUrl,
//     required this.createdAt,
//     required this.syncStatus,
//   });

//   // Factory constructor to create a new Group with all fields
//   factory Group.create({
//     required String name,
//     String? description,
//     required String groupType,
//     String currency = 'INR',
//     double? overallBudget,
//     double? myShare,
//     required List<Member> members,
//     String? createdBy,
//     String? bannerImagePath,
//   }) {
//     return Group(
//       id: const Uuid().v4(),
//       name: name,
//       description: description,
//       groupType: groupType,
//       currency: currency,
//       overallBudget: overallBudget,
//       myShare: myShare,
//       members: members,
//       createdBy: createdBy,
//       bannerImagePath: bannerImagePath,
//       createdAt: DateTime.now(),
//       syncStatus: 'PENDING',
//     );
//   }

//   // Convert Group to Map for database storage
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description ?? '',
//       'groupType': groupType,
//       'currency': currency,
//       'overallBudget': overallBudget ?? 0.0,
//       'myShare': myShare ?? 0.0,
//       'members': jsonEncode(members),
//       'createdBy': createdBy ?? '',
//       'bannerImagePath': bannerImagePath ?? '',
//       'bannerImageUrl': bannerImageUrl ?? '',
//       'createdAt': createdAt.toIso8601String(),
//       'syncStatus': syncStatus,
//     };
//   }

//   // Create Group from Map (database row)
//   factory Group.fromMap(Map<String, dynamic> map) {
//     return Group(
//       id: map['id'],
//       name: map['name'],
//       description: map['description'] ?? '',
//       groupType: map['groupType'] ?? 'Other',
//       currency: map['currency'] ?? 'INR',
//       overallBudget: (map['overallBudget'] is num)
//           ? (map['overallBudget'] as num).toDouble()
//           : double.tryParse(map['overallBudget']?.toString() ?? '0') ?? 0.0,
//       myShare: (map['myShare'] is num)
//           ? (map['myShare'] as num).toDouble()
//           : double.tryParse(map['myShare']?.toString() ?? '0') ?? 0.0,
//       members: map['members'] != null
//           ? List<String>.from(jsonDecode(map['members']))
//           : <String>[],
//       createdBy: map['createdBy'] ?? '',
//       bannerImagePath: map['bannerImagePath'] ?? '',
//       bannerImageUrl: map['bannerImageUrl'] ?? '',
//       createdAt: DateTime.parse(map['createdAt']),
//       syncStatus: map['syncStatus'] ?? 'PENDING',
//     );
//   }

//   // Convert Group to JSON for API
//   Map<String, dynamic> toApiJson() {
//     return {
//       'groupName': name,
//       'groupDescription': description,
//       'groupType': groupType,
//       'currency': currency,
//       'overallBudget': overallBudget,
//       'myShare': myShare,
//       'members': members,
//     };
//   }

//   // Get display image path (for UI to use)
//   String? getDisplayImagePath() {
//     if (bannerImagePath != null && bannerImagePath!.isNotEmpty) {
//       return bannerImagePath;
//     }
//     return null;
//   }

//   // Copy with method for updates
//   Group copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? groupType,
//     String? currency,
//     double? overallBudget,
//     double? myShare,
//     List<String>? members,
//     String? createdBy,
//     String? bannerImagePath,
//     String? bannerImageUrl,
//     DateTime? createdAt,
//     String? syncStatus,
//   }) {
//     return Group(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       groupType: groupType ?? this.groupType,
//       currency: currency ?? this.currency,
//       overallBudget: overallBudget ?? this.overallBudget,
//       myShare: myShare ?? this.myShare,
//       members: members ?? this.members,
//       createdBy: createdBy ?? this.createdBy,
//       bannerImagePath: bannerImagePath ?? this.bannerImagePath,
//       bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
//       createdAt: createdAt ?? this.createdAt,
//       syncStatus: syncStatus ?? this.syncStatus,
//     );
//   }

//   // Convert Group to JSON string
//   String toJson() => jsonEncode(toMap());

//   // Create Group from JSON string
//   factory Group.fromJson(String source) => Group.fromMap(jsonDecode(source));
// }

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'member_model.dart';

class Group {
  final String id;
  final String userId; // ← NEW: which user owns this group
  final String name;
  final String? description;
  final String groupType;
  final String currency;
  final double? overallBudget;
  final double? myShare;
  final List<Member> members;
  final String? createdBy;
  final String? bannerImagePath;
  final String? bannerImageUrl;
  final String? bannerPublicId;
  final DateTime createdAt;
  final String syncStatus;

  const Group({
    required this.id,
    required this.userId, // ← NEW
    required this.name,
    this.description,
    required this.groupType,
    this.currency = 'INR',
    this.overallBudget,
    this.myShare,
    required this.members,
    this.createdBy,
    this.bannerImagePath,
    this.bannerImageUrl,
    this.bannerPublicId,
    required this.createdAt,
    required this.syncStatus,
  });

  // Factory: create a brand new group
  factory Group.create({
    required String userId, // ← NEW
    required String name,
    String? description,
    required String groupType,
    String currency = 'INR',
    double? overallBudget,
    double? myShare,
    required List<Member> members,
    String? createdBy,
    String? bannerImagePath,
  }) {
    return Group(
      id: const Uuid().v4(),
      userId: userId, // ← NEW
      name: name,
      description: description,
      groupType: groupType,
      currency: currency,
      overallBudget: overallBudget,
      myShare: myShare,
      members: members,
      createdBy: createdBy,
      bannerImagePath: bannerImagePath,
      createdAt: DateTime.now(),
      syncStatus: 'PENDING',
    );
  }

  // From SQLite map
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '', // ← NEW
      name: map['name'] as String,
      description: map['description'] as String?,
      groupType: map['groupType'] as String? ?? 'Other',
      currency: map['currency'] as String? ?? 'INR',
      overallBudget: map['overallBudget'] as double?,
      myShare: map['myShare'] as double?,
      members: map['members'] != null
          ? Member.fromJsonList(jsonDecode(map['members'] as String))
          : <Member>[],
      createdBy: map['createdBy'] as String?,
      bannerImagePath: map['bannerImagePath'] as String?,
      bannerImageUrl: map['bannerImageUrl'] as String?,
      bannerPublicId: map['bannerPublicId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncStatus: map['syncStatus'] as String? ?? 'PENDING',
    );
  }

  // To SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // ← NEW
      'name': name,
      'description': description ?? '',
      'groupType': groupType,
      'currency': currency,
      'overallBudget': overallBudget ?? 0.0,
      'myShare': myShare ?? 0.0,
      'members': jsonEncode(Member.toMapList(members)),
      'createdBy': createdBy ?? '',
      'bannerImagePath': bannerImagePath ?? '',
      'bannerImageUrl': bannerImageUrl ?? '',
      'bannerPublicId': bannerPublicId ?? '',
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  // Get display image path (for UI to use)
  String? getDisplayImagePath() {
    if (bannerImagePath != null && bannerImagePath!.isNotEmpty) {
      return bannerImagePath;
    }
    if (bannerImageUrl != null && bannerImageUrl!.isNotEmpty) {
      return bannerImageUrl;
    }
    return null;
  }

  bool get hasBanner => getDisplayImagePath() != null;

  Group copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? groupType,
    String? currency,
    double? overallBudget,
    double? myShare,
    List<Member>? members,
    String? createdBy,
    String? bannerImagePath,
    String? bannerImageUrl,
    String? bannerPublicId,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return Group(
      id: id ?? this.id,
      userId: userId ?? this.userId, // ← NEW
      name: name ?? this.name,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      currency: currency ?? this.currency,
      overallBudget: overallBudget ?? this.overallBudget,
      myShare: myShare ?? this.myShare,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      bannerPublicId: bannerPublicId ?? this.bannerPublicId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
