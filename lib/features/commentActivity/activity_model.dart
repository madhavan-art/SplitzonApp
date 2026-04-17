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
  });

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
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    dynamic metadataValue = map['metadata'];
    Map<String, dynamic>? parsedMetadata;

    try {
      if (metadataValue != null) {
        if (metadataValue is String) {
          // Proper JSON string - decode it
          parsedMetadata = jsonDecode(metadataValue);
        } else if (metadataValue is Map) {
          // Already a Map (rare case)
          parsedMetadata = Map<String, dynamic>.from(metadataValue);
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️  Metadata parse failed, ignoring: $metadataValue | Error: $e',
      );
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
      timestamp: DateTime.parse(map['timestamp']),
      metadata: parsedMetadata,
    );
  }

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
    );
  }
}
