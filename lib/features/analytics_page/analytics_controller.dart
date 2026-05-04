// lib/features/analytics/analytics_controller.dart
import 'package:flutter/material.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/providers/expense_provider.dart';

class AnalyticsController extends ChangeNotifier {
  final ExpenseProvider expenseProvider;
  final String? groupId;
  final String currentUserId;

  final Map<String, String> _groupNames = {};

  AnalyticsController({
    required this.expenseProvider,
    this.groupId,
    required this.currentUserId,
  }) {
    expenseProvider.addListener(_onExpensesChanged);
    _initializeData();
  }

  void _onExpensesChanged() => notifyListeners();

  Future<void> _initializeData() async {
    if (groupId != null) {
      await expenseProvider.loadExpenses(groupId!);
    } else {
      final allExpenses = expenseProvider.getAllExpenses();
      final groupIds = allExpenses.map((e) => e.groupId).toSet();
      for (var gid in groupIds) {
        await expenseProvider.loadExpenses(gid);
      }
    }
    notifyListeners();
  }

  void setGroupName(String groupId, String name) {
    _groupNames[groupId] = name;
    notifyListeners();
  }

  String getGroupName(String groupId) {
    return _groupNames[groupId] ?? "Group $groupId";
  }

  List<Expense> get _relevantExpenses {
    return groupId != null
        ? expenseProvider.getExpenses(groupId!)
        : expenseProvider.getAllExpenses();
  }

  double get totalSpending =>
      _relevantExpenses.fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> getGroupComparisonData() {
    final Map<String, double> data = {};
    for (var exp in expenseProvider.getAllExpenses()) {
      data[exp.groupId] = (data[exp.groupId] ?? 0) + exp.amount;
    }
    return data;
  }

  Map<String, double> getCategoryData() {
    final Map<String, double> data = {};
    for (var exp in _relevantExpenses) {
      final cat = exp.category.isEmpty ? 'Other' : exp.category;
      data[cat] = (data[cat] ?? 0) + exp.amount;
    }
    return data;
  }

  Map<String, Map<String, double>> getMyDetailedSpendingPerGroup() {
    final Map<String, Map<String, double>> result = {};

    for (var exp in expenseProvider.getAllExpenses()) {
      final groupId = exp.groupId;

      if (!result.containsKey(groupId)) {
        result[groupId] = {'paid': 0.0, 'owedToMe': 0.0, 'iOwe': 0.0};
      }

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
        if (exp.paidByUserId == currentUserId) {
          // Fixed: paidByUserId
          result[groupId]!['paid'] =
              (result[groupId]!['paid'] ?? 0) + exp.amount;
          result[groupId]!['owedToMe'] =
              (result[groupId]!['owedToMe'] ?? 0) +
              (exp.amount - myShare.shareAmount);
        } else {
          result[groupId]!['iOwe'] =
              (result[groupId]!['iOwe'] ?? 0) + myShare.shareAmount;
        }
      }
    }
    return result;
  }

  Map<String, double> getMemberContributions() {
    final Map<String, double> data = {};
    for (var exp in _relevantExpenses) {
      final name = exp.paidByName.isNotEmpty ? exp.paidByName : 'Unknown';
      data[name] = (data[name] ?? 0) + exp.amount;
    }
    return data;
  }

  @override
  void dispose() {
    expenseProvider.removeListener(_onExpensesChanged);
    super.dispose();
  }
}
