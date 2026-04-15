// ════════════════════════════════════════════════════════════════
// FILE: lib/data/models/expense_model.dart
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:uuid/uuid.dart';

class MemberShare {
  final String userId;
  final String name;
  final double shareAmount;
  final double percentage;
  final bool isInvolved;

  const MemberShare({
    required this.userId,
    required this.name,
    required this.shareAmount,
    required this.percentage,
    required this.isInvolved,
  });

  factory MemberShare.fromMap(Map<String, dynamic> map) => MemberShare(
    userId: map['userId'] ?? '',
    name: map['name'] ?? '',
    shareAmount: (map['shareAmount'] is num)
        ? (map['shareAmount'] as num).toDouble()
        : 0.0,
    percentage: (map['percentage'] is num)
        ? (map['percentage'] as num).toDouble()
        : 0.0,
    isInvolved: map['isInvolved'] == true || map['isInvolved'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'shareAmount': shareAmount,
    'percentage': percentage,
    'isInvolved': isInvolved,
  };
}

class Expense {
  final String id;
  final String groupId;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final String notes;
  final DateTime date;
  final String paidByUserId;
  final String paidByName;
  final String splitType;
  final List<MemberShare> memberShares;
  final String syncStatus;

  const Expense({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.title,
    required this.amount,
    this.category = 'Other',
    this.notes = '',
    required this.date,
    required this.paidByUserId,
    required this.paidByName,
    required this.splitType,
    required this.memberShares,
    required this.syncStatus,
  });

  factory Expense.create({
    required String groupId,
    required String userId,
    required String title,
    required double amount,
    String category = 'Other',
    String notes = '',
    DateTime? date,
    required String paidByUserId,
    required String paidByName,
    required String splitType,
    required List<MemberShare> memberShares,
  }) => Expense(
    id: const Uuid().v4(),
    groupId: groupId,
    userId: userId,
    title: title,
    amount: amount,
    category: category,
    notes: notes,
    date: date ?? DateTime.now(),
    paidByUserId: paidByUserId,
    paidByName: paidByName,
    splitType: splitType,
    memberShares: memberShares,
    syncStatus: 'PENDING',
  );

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] as String,
    groupId: map['groupId'] as String,
    userId: map['userId'] as String? ?? '',
    title: map['title'] as String,
    amount: (map['amount'] as num).toDouble(),
    category: map['category'] as String? ?? 'Other',
    notes: map['notes'] as String? ?? '',
    date: DateTime.parse(map['date'] as String),
    paidByUserId: map['paidByUserId'] as String? ?? '',
    paidByName: map['paidByName'] as String? ?? '',
    splitType: map['splitType'] as String? ?? 'equal',
    memberShares: (jsonDecode(map['memberShares'] as String? ?? '[]') as List)
        .map((e) => MemberShare.fromMap(e as Map<String, dynamic>))
        .toList(),
    syncStatus: map['syncStatus'] as String? ?? 'PENDING',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'userId': userId,
    'title': title,
    'amount': amount,
    'category': category,
    'notes': notes,
    'date': date.toIso8601String(),
    'paidByUserId': paidByUserId,
    'paidByName': paidByName,
    'splitType': splitType,
    'memberShares': jsonEncode(memberShares.map((s) => s.toMap()).toList()),
    'syncStatus': syncStatus,
  };

  Expense copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? title,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
    String? paidByUserId,
    String? paidByName,
    String? splitType,
    List<MemberShare>? memberShares,
    String? syncStatus,
  }) => Expense(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    notes: notes ?? this.notes,
    date: date ?? this.date,
    paidByUserId: paidByUserId ?? this.paidByUserId,
    paidByName: paidByName ?? this.paidByName,
    splitType: splitType ?? this.splitType,
    memberShares: memberShares ?? this.memberShares,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
