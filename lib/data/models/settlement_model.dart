// lib/data/models/settlement_model.dart
import 'package:flutter/foundation.dart';

class Settlement {
  final String id;
  final String groupId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;
  final String notes;
  final DateTime date;
  final String syncStatus;

  Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    this.notes = '',
    required this.date,
    this.syncStatus = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
      'notes': notes,
      'date': date.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  factory Settlement.fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserId: map['toUserId'] ?? '',
      toUserName: map['toUserName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      notes: map['notes'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      syncStatus: map['syncStatus'] ?? 'PENDING',
    );
  }

  Settlement copyWith({String? syncStatus}) {
    return Settlement(
      id: id,
      groupId: groupId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      amount: amount,
      notes: notes,
      date: date,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
