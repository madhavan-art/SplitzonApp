// lib/features/add_expense/add_expenses_controller.dart
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

  AddExpenseController({required this.group}) {
    debugPrint('🚀 AddExpenseController CREATED - Group: ${group.id}');
    _loadMembers();
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

  // ── VALIDATION GETTERS ────────────────────────────────────

  /// Total percentage entered across all members
  double get totalPercentage =>
      members.fold(0.0, (sum, m) => sum + m.percentage);

  /// Total custom share amount entered across all members
  double get totalShareAmount =>
      members.fold(0.0, (sum, m) => sum + m.shareAmount);

  /// Whether the save button should be enabled
  bool get canSave {
    if (titleController.text.trim().isEmpty) return false;
    if (totalAmount <= 0) return false;

    switch (splitType) {
      case SplitType.equal:
        // At least 1 member must be selected
        return totalSelected >= 1;
      case SplitType.percentage:
        // Percentages must sum to exactly 100%
        return (totalPercentage - 100.0).abs() < 0.01;
      case SplitType.share:
        // Custom amounts must sum to exactly the total expense amount
        return totalAmount > 0 && (totalShareAmount - totalAmount).abs() < 0.01;
    }
  }

  /// Hint text shown below the save button when validation fails
  String get validationHint {
    if (titleController.text.trim().isEmpty) return 'Enter a title';
    if (totalAmount <= 0) return 'Enter a valid amount';

    switch (splitType) {
      case SplitType.equal:
        if (totalSelected == 0) return 'Select at least one member';
        return '';
      case SplitType.percentage:
        final diff = (totalPercentage - 100.0).abs();
        if (diff >= 0.01) {
          return 'Percentages must total 100% (currently ${totalPercentage.toStringAsFixed(1)}%)';
        }
        return '';
      case SplitType.share:
        if (totalAmount <= 0) return 'Enter a valid amount first';
        final diff = (totalShareAmount - totalAmount).abs();
        if (diff >= 0.01) {
          return 'Amounts must total ₹${totalAmount.toStringAsFixed(2)} (currently ₹${totalShareAmount.toStringAsFixed(2)})';
        }
        return '';
    }
  }

  void _log(String message) {
    debugPrint('💰 [AddExpense] $message');
  }

  void _loadMembers() {
    _log('=== _loadMembers() START ===');
    _log('Group ID: ${group.id} | Members count: ${group.members.length}');

    members = group.members.map((member) {
      String memberId = '';

      if (member.id != null) {
        memberId = member.id.toString().trim();
      }

      final memberName = (member.name?.isNotEmpty == true)
          ? member.name!
          : (memberId.isNotEmpty ? memberId : 'Unknown');

      _log(
        'Loading member → Raw: ${member.id} | Clean ID: "$memberId" | Name: "$memberName"',
      );

      return MemberModel(
        id: memberId,
        name: memberName,
        avatar: memberId.isNotEmpty
            ? 'https://i.pravatar.cc/150?u=$memberId'
            : 'https://i.pravatar.cc/150?u=unknown',
        isSelected: true,
        percentage: 0,
        shareAmount: 0,
      );
    }).toList();

    for (var m in members) {
      m.isSelected = true;
    }

    _setEqualPercentage();
    _log('=== _loadMembers() END - ${members.length} members loaded ===');
    notifyListeners();
  }

  void _setEqualPercentage() {
    if (selectedMembers.isEmpty) return;
    final p = 100 / selectedMembers.length;
    for (var m in members) {
      m.percentage = m.isSelected ? p : 0;
    }
    _log(
      'Set equal percentage: $p% per selected member (${selectedMembers.length} selected)',
    );
  }

  void setPaidBy(String userId, String name) {
    paidByUserId = userId.trim();
    paidByName = name.isNotEmpty ? name : 'You';
    _log('Paid by set to: $paidByName ($paidByUserId)');
    notifyListeners();
  }

  void changeSplitType(SplitType type) {
    splitType = type;
    if (type == SplitType.equal) {
      // Reset all to selected when switching back to equal
      for (var m in members) {
        m.isSelected = true;
        m.shareAmount = 0;
      }
      _setEqualPercentage();
    } else if (type == SplitType.percentage) {
      // Reset percentages to 0 so user enters manually
      for (var m in members) {
        m.percentage = 0;
        m.isSelected = true;
      }
    } else if (type == SplitType.share) {
      // Reset share amounts to 0 so user enters manually
      for (var m in members) {
        m.shareAmount = 0;
        m.isSelected = true;
      }
    }
    _log('Split type changed to: $type');
    notifyListeners();
  }

  void toggleMember(String id) {
    final member = members.firstWhere((m) => m.id == id);
    member.isSelected = !member.isSelected;
    _log('Toggled member $id → selected: ${member.isSelected}');

    // Recalculate equal split when members are toggled
    if (splitType == SplitType.equal) {
      _setEqualPercentage();
    }

    notifyListeners();
  }

  void updatePercentage(String id, String value) {
    final member = members.firstWhere((m) => m.id == id);
    member.percentage = double.tryParse(value) ?? 0;
    _log('Updated percentage for $id → ${member.percentage}%');
    notifyListeners();
  }

  void updateShareAmount(String id, String value) {
    final member = members.firstWhere((m) => m.id == id);
    member.shareAmount = double.tryParse(value) ?? 0;
    _log('Updated share amount for $id → ₹${member.shareAmount}');
    notifyListeners();
  }

  List<MemberShare> buildMemberShares() {
    _log(
      '=== buildMemberShares() START - Type: $splitType | Amount: $totalAmount ===',
    );

    final shares = members.map((m) {
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

      final cleanUserId = m.id.isNotEmpty ? m.id.trim() : '';

      final shareData = MemberShare(
        userId: cleanUserId,
        name: m.name,
        shareAmount: share,
        percentage: pct,
        isInvolved: involved,
      );

      _log(
        'MemberShare → "${m.name}" | ID: "$cleanUserId" | ₹${share.toStringAsFixed(2)} | Involved: $involved',
      );

      return shareData;
    }).toList();

    _log('=== buildMemberShares() END - ${shares.length} shares ready ===');
    return shares;
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
    if (splitType == SplitType.equal && totalSelected == 0) {
      _snack(context, 'Select at least one member');
      return false;
    }
    if (splitType == SplitType.percentage) {
      final diff = (totalPercentage - 100.0).abs();
      if (diff >= 0.01) {
        _snack(
          context,
          'Percentages must total 100% (currently ${totalPercentage.toStringAsFixed(1)}%)',
        );
        return false;
      }
    }
    if (splitType == SplitType.share) {
      final diff = (totalShareAmount - totalAmount).abs();
      if (diff >= 0.01) {
        _snack(
          context,
          'Amounts must total ₹${totalAmount.toStringAsFixed(2)} (currently ₹${totalShareAmount.toStringAsFixed(2)})',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> saveExpense(BuildContext context) async {
    _log('saveExpense() called');

    if (!validate(context)) {
      _log('Validation failed');
      return;
    }

    final shares = buildMemberShares();

    isSaving = true;
    notifyListeners();

    try {
      final expenseProvider = context.read<ExpenseProvider>();

      _log('Sending ${shares.length} memberShares to backend...');

      final expense = await expenseProvider.createExpense(
        groupId: group.id,
        title: titleController.text.trim(),
        amount: totalAmount,
        category: selectedCategory,
        paidByUserId: paidByUserId,
        paidByName: paidByName,
        splitType: _mapSplitType(splitType),
        memberShares: shares,
      );

      isSaving = false;
      notifyListeners();

      if (expense != null && context.mounted) {
        _log('✅ Expense successfully saved!');
        await expenseProvider.loadExpenses(group.id);

        final activityController = context.read<ActivityController>();
        await activityController.logExpenseAdded(
          titleController.text.trim(),
          group.id,
          group.name,
          paidByName,
          totalAmount,
        );

        _snack(context, 'Expense saved successfully ✅', color: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();
      _log('❌ ERROR: $e');
      _snack(context, 'Failed to save: $e');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }
}
