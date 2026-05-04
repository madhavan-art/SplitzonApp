// ════════════════════════════════════════════════════════════════
// FILE: lib/features/add_expense/add_expenses_controller.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/features/commentActivity/activity_controller.dart';

enum SplitType { equal, percentage, share }

class MemberModel {
  final String id;
  final String name;
  final String avatar;
  bool isSelected;
  double percentage;
  double shareAmount;

  MemberModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.isSelected = true,
    this.percentage = 0,
    this.shareAmount = 0,
  });
}

class AddExpenseController extends ChangeNotifier {
  final Group group;
  final Expense? existingExpense;

  bool get isEditMode => existingExpense != null;

  AddExpenseController({required this.group, this.existingExpense}) {
    debugPrint(
      '🚀 AddExpenseController CREATED - Group: ${group.id} | Edit Mode: $isEditMode',
    );
    _loadMembers();

    if (isEditMode) {
      _loadExistingExpenseData();
    }
  }

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  SplitType splitType = SplitType.equal;
  String selectedCategory = 'Food';
  bool isSaving = false;

  String paidByUserId = '';
  String paidByName = 'You';

  List<MemberModel> members = [];

  double get totalAmount =>
      double.tryParse(amountController.text.trim()) ?? 0.0;

  List<MemberModel> get selectedMembers =>
      members.where((m) => m.isSelected).toList();

  int get totalSelected => selectedMembers.length;

  double get totalPercentage =>
      members.fold(0.0, (sum, m) => sum + m.percentage);
  double get totalShareAmount =>
      members.fold(0.0, (sum, m) => sum + m.shareAmount);

  bool get canSave {
    if (titleController.text.trim().isEmpty) return false;
    if (totalAmount <= 0) return false;

    switch (splitType) {
      case SplitType.equal:
        return totalSelected >= 1;
      case SplitType.percentage:
        return (totalPercentage - 100.0).abs() < 0.01;
      case SplitType.share:
        return totalAmount > 0 && (totalShareAmount - totalAmount).abs() < 0.01;
    }
  }

  String get validationHint {
    if (titleController.text.trim().isEmpty) return 'Enter a title';
    if (totalAmount <= 0) return 'Enter a valid amount';

    switch (splitType) {
      case SplitType.equal:
        if (totalSelected == 0) return 'Select at least one member';
        return '';
      case SplitType.percentage:
        final diff = (totalPercentage - 100.0).abs();
        if (diff >= 0.01) return 'Percentages must total 100%';
        return '';
      case SplitType.share:
        final diff = (totalShareAmount - totalAmount).abs();
        if (diff >= 0.01)
          return 'Amounts must total ₹${totalAmount.toStringAsFixed(2)}';
        return '';
    }
  }

  void _log(String message) => debugPrint('💰 [AddExpense] $message');

  void _loadMembers() {
    members = group.members.map((member) {
      String memberId = member.id?.toString().trim() ?? '';
      String memberName = member.name?.isNotEmpty == true
          ? member.name!
          : (memberId.isNotEmpty ? memberId : 'Unknown');

      return MemberModel(
        id: memberId,
        name: memberName,
        avatar: memberId.isNotEmpty
            ? 'https://i.pravatar.cc/150?u=$memberId'
            : 'https://i.pravatar.cc/150?u=unknown',
        isSelected: true,
      );
    }).toList();

    _setEqualPercentage();
    notifyListeners();
  }

  void _loadExistingExpenseData() {
    if (existingExpense == null) return;

    titleController.text = existingExpense!.title;
    amountController.text = existingExpense!.amount.toStringAsFixed(2);
    selectedCategory = existingExpense!.category;
    paidByUserId = existingExpense!.paidByUserId;
    paidByName = existingExpense!.paidByName;

    _log('Loaded existing expense for editing: ${existingExpense!.title}');
    notifyListeners();
  }

  void _setEqualPercentage() {
    if (selectedMembers.isEmpty) return;
    final p = 100 / selectedMembers.length;
    for (var m in members) {
      m.percentage = m.isSelected ? p : 0;
    }
  }

  void changeSplitType(SplitType type) {
    splitType = type;
    if (type == SplitType.equal) {
      for (var m in members) m.isSelected = true;
      _setEqualPercentage();
    } else if (type == SplitType.percentage) {
      for (var m in members) m.percentage = 0;
    } else if (type == SplitType.share) {
      for (var m in members) m.shareAmount = 0;
    }
    notifyListeners();
  }

  void toggleMember(String id) {
    final member = members.firstWhere((m) => m.id == id);
    member.isSelected = !member.isSelected;
    if (splitType == SplitType.equal) _setEqualPercentage();
    notifyListeners();
  }

  void updatePercentage(String id, String value) {
    final member = members.firstWhere((m) => m.id == id);
    member.percentage = double.tryParse(value) ?? 0;
    notifyListeners();
  }

  void updateShareAmount(String id, String value) {
    final member = members.firstWhere((m) => m.id == id);
    member.shareAmount = double.tryParse(value) ?? 0;
    notifyListeners();
  }

  List<MemberShare> buildMemberShares() {
    return members.map((m) {
      double share = 0.0;
      double pct = 0.0;
      bool involved = false;

      if (splitType == SplitType.equal) {
        involved = m.isSelected;
        if (involved && totalSelected > 0) {
          share = totalAmount / totalSelected;
          pct = 100 / totalSelected;
        }
      } else if (splitType == SplitType.percentage) {
        involved = m.percentage > 0;
        share = (m.percentage / 100) * totalAmount;
        pct = m.percentage;
      } else if (splitType == SplitType.share) {
        involved = m.shareAmount > 0;
        share = m.shareAmount;
        pct = totalAmount > 0 ? (share / totalAmount) * 100 : 0;
      }

      return MemberShare(
        userId: m.id,
        name: m.name,
        shareAmount: share,
        percentage: pct,
        isInvolved: involved,
      );
    }).toList();
  }

  bool validate(BuildContext context) {
    if (titleController.text.trim().isEmpty) {
      _snack(context, 'Enter a title');
      return false;
    }
    if (totalAmount <= 0) {
      _snack(context, 'Enter a valid amount');
      return false;
    }
    // ... rest of your validation
    return true;
  }

  Future<void> saveExpense(BuildContext context) async {
    if (!validate(context)) return;

    final shares = buildMemberShares();
    isSaving = true;
    notifyListeners();

    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final activityController = context.read<ActivityController>();

      Expense? result;

      if (isEditMode) {
        // Update existing expense
        final updatedExpense = existingExpense!.copyWith(
          title: titleController.text.trim(),
          amount: totalAmount,
          category: selectedCategory,
          splitType: _mapSplitType(splitType),
          memberShares: shares,
        );
        result = await expenseProvider.updateExpense(updatedExpense);

        if (result != null) {
          await activityController.logExpenseUpdated(
            result.title,
            group.id,
            group.name,
            result.paidByName,
          );
        }
      } else {
        // Create new expense
        result = await expenseProvider.createExpense(
          groupId: group.id,
          title: titleController.text.trim(),
          amount: totalAmount,
          category: selectedCategory,
          paidByUserId: paidByUserId,
          paidByName: paidByName,
          splitType: _mapSplitType(splitType),
          memberShares: shares,
        );

        if (result != null) {
          await activityController.logExpenseAdded(
            result.title,
            group.id,
            group.name,
            paidByName,
            totalAmount,
          );
        }
      }

      isSaving = false;
      notifyListeners();

      if (result != null && context.mounted) {
        await expenseProvider.loadExpenses(group.id);
        _snack(
          context,
          isEditMode
              ? 'Expense updated successfully'
              : 'Expense saved successfully',
          color: Colors.green,
        );
        Navigator.pop(
          context,
          result,
        ); // Return the expense for refresh in detail screen
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();
      _log('❌ ERROR: $e');
      _snack(
        context,
        'Failed to ${isEditMode ? "update" : "save"} expense: $e',
      );
    }
  }

  String _mapSplitType(SplitType t) {
    switch (t) {
      case SplitType.equal:
        return 'equal';
      case SplitType.percentage:
        return 'percentage';
      case SplitType.share:
        return 'custom';
    }
  }

  void _snack(BuildContext context, String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
