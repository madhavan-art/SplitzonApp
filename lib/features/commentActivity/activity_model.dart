// ════════════════════════════════════════════════════════════════
// FILE: lib/features/commentActivity/activity_model.dart
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';

class ActivityModel {
  final String id;
  final String type; // create, update, delete, add_member, add_expense, settle
  final String title;
  final String description;
  final String groupId;
  final String groupName;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String syncStatus; // ← NEW: 'PENDING', 'SYNCED', 'PENDING_DELETE'

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.groupId,
    required this.groupName,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.metadata,
    this.syncStatus = 'PENDING', // Default to PENDING for offline-first
  });

  // Convert to SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'groupId': groupId,
      'groupName': groupName,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'syncStatus': syncStatus, // ← Added
    };
  }

  // Convert from SQLite Map
  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    dynamic metadataValue = map['metadata'];
    Map<String, dynamic>? parsedMetadata;

    try {
      if (metadataValue != null) {
        if (metadataValue is String) {
          parsedMetadata = jsonDecode(metadataValue);
        } else if (metadataValue is Map) {
          parsedMetadata = Map<String, dynamic>.from(metadataValue);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Metadata parse failed: $e');
      parsedMetadata = null;
    }

    return ActivityModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: parsedMetadata,
      syncStatus: map['syncStatus'] ?? 'PENDING', // ← Added
    );
  }

  // Copy with method for updating syncStatus
  ActivityModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? groupId,
    String? groupName,
    String? userId,
    String? userName,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? syncStatus,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Helper to check if activity is synced
  bool get isSynced => syncStatus == 'SYNCED';

  // Helper to check if activity needs syncing
  bool get isPending =>
      syncStatus == 'PENDING' || syncStatus == 'PENDING_DELETE';
}
