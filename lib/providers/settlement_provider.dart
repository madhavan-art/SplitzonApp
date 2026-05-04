// lib/providers/settlement_provider.dart
import 'package:flutter/material.dart';
import 'package:splitzon/data/models/expense_model.dart';
import '../data/models/settlement_model.dart';
import '../data/local/database_helper.dart';
import 'expense_provider.dart';

class SettlementProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ExpenseProvider expenseProvider;

  List<Settlement> _settlements = [];
  bool _isLoading = false;

  SettlementProvider({required this.expenseProvider});

  List<Settlement> get settlements => List.unmodifiable(_settlements);
  bool get isLoading => _isLoading;

  void _log(String msg) => debugPrint('💰 SettlementProvider: $msg');

  // Load all settlements for a group
  Future<void> loadSettlements(String groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _settlements = await _dbHelper.getSettlementsByGroup(groupId);
      _log('Loaded ${_settlements.length} settlements for group $groupId');
    } catch (e) {
      _log('Error loading settlements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record a new settlement (Offline-first)
  Future<bool> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required double amount,
    String notes = '',
  }) async {
    try {
      final settlement = Settlement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: groupId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        amount: amount,
        notes: notes,
        date: DateTime.now(),
        syncStatus: 'PENDING',
      );

      await _dbHelper.insertSettlement(settlement);

      // Add to local list
      _settlements.insert(0, settlement);
      notifyListeners();

      _log('Settlement recorded: $fromUserName → $toUserName ₹$amount');

      return true;
    } catch (e) {
      _log('Failed to record settlement: $e');
      return false;
    }
  }

  // Get net balances for a group (combining expenses + settlements)
  Future<Map<String, double>> getNetBalances(
    String groupId,
    String currentUserId,
  ) async {
    // This is a simplified version. In future we can make it more advanced.
    final expenses = await _dbHelper.getExpensesByGroup(groupId);
    final settlements = await _dbHelper.getSettlementsByGroup(groupId);

    final Map<String, double> balances = {};

    // Calculate from expenses
    for (var exp in expenses) {
      if (exp.paidByUserId == currentUserId) {
        // I paid → others owe me
        for (var share in exp.memberShares) {
          if (share.userId != currentUserId && share.isInvolved) {
            balances[share.userId] =
                (balances[share.userId] ?? 0) + share.shareAmount;
          }
        }
      } else {
        // Someone else paid → I owe them
        final myShare = exp.memberShares.firstWhere(
          (s) => s.userId == currentUserId,
          orElse: () => MemberShare(
            userId: '',
            name: '',
            shareAmount: 0,
            percentage: 0,
            isInvolved: false,
          ),
        );
        if (myShare.isInvolved) {
          balances[exp.paidByUserId] =
              (balances[exp.paidByUserId] ?? 0) - myShare.shareAmount;
        }
      }
    }

    // Adjust balances from settlements
    for (var st in settlements) {
      if (st.fromUserId == currentUserId) {
        // I paid someone → reduce what they owe me
        balances[st.toUserId] = (balances[st.toUserId] ?? 0) - st.amount;
      } else if (st.toUserId == currentUserId) {
        // Someone paid me → reduce what I owe them
        balances[st.fromUserId] = (balances[st.fromUserId] ?? 0) + st.amount;
      }
    }

    return balances;
  }

  // Get suggested settlements (simple version)
  List<Map<String, dynamic>> getSuggestedSettlements(
    String groupId,
    String currentUserId,
  ) {
    // TODO: Implement proper debt simplification algorithm in future
    // For now returning dummy
    return [];
  }
}
