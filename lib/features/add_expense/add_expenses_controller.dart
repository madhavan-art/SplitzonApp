// ════════════════════════════════════════════════════════════════
// FILE: lib/features/add_expense/add_expenses_controller.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';

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
    _loadMembers();
  }

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  SplitType splitType = SplitType.equal;
  String selectedCategory = 'General';
  bool isSaving = false;

  // paidBy will be set to current user on init
  String paidByUserId = '';
  String paidByName = 'You';

  List<MemberModel> members = [];

  double get totalAmount => double.tryParse(amountController.text.trim()) ?? 0;

  List<MemberModel> get selectedMembers =>
      members.where((m) => m.isSelected).toList();

  double get equalAmount {
    if (selectedMembers.isEmpty) return 0;
    return totalAmount / selectedMembers.length;
  }

  void _loadMembers() {
    members = group.members.map((name) {
      return MemberModel(
        id: name,
        name: name,
        avatar: 'https://i.pravatar.cc/150?u=$name',
        isSelected: true,
        percentage: 0,
        shareAmount: 0,
      );
    }).toList();
    _setEqualPercentage();
    notifyListeners();
  }

  void setPaidBy(String userId, String name) {
    paidByUserId = userId;
    paidByName = name;
    notifyListeners();
  }

  void changeSplitType(SplitType type) {
    splitType = type;
    if (type == SplitType.equal) {
      for (var m in members) m.isSelected = true;
    }
    if (type == SplitType.percentage) _setEqualPercentage();
    notifyListeners();
  }

  void toggleMember(String id) {
    members.firstWhere((m) => m.id == id).isSelected ^= true;
    notifyListeners();
  }

  void updatePercentage(String id, String value) {
    members.firstWhere((m) => m.id == id).percentage =
        double.tryParse(value) ?? 0;
    notifyListeners();
  }

  void updateShareAmount(String id, String value) {
    members.firstWhere((m) => m.id == id).shareAmount =
        double.tryParse(value) ?? 0;
    notifyListeners();
  }

  void _setEqualPercentage() {
    if (members.isEmpty) return;
    final p = 100 / members.length;
    for (var m in members) m.percentage = p;
  }

  /// Build MemberShare list from current state
  List<MemberShare> buildMemberShares() {
    return members.map((m) {
      double share = 0;
      double pct = 0;
      bool involved = false;

      if (splitType == SplitType.equal && m.isSelected) {
        share = equalAmount;
        pct = selectedMembers.isEmpty ? 0 : 100 / selectedMembers.length;
        involved = true;
      } else if (splitType == SplitType.percentage) {
        share = (m.percentage / 100) * totalAmount;
        pct = m.percentage;
        involved = m.percentage > 0;
      } else if (splitType == SplitType.share) {
        share = m.shareAmount;
        pct = totalAmount > 0 ? (share / totalAmount) * 100 : 0;
        involved = share > 0;
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

  // ── VALIDATION ────────────────────────────────────────────
  bool validate(BuildContext context) {
    if (titleController.text.trim().isEmpty) {
      _snack(context, 'Enter a title');
      return false;
    }
    if (totalAmount <= 0) {
      _snack(context, 'Enter a valid amount');
      return false;
    }
    if (splitType == SplitType.equal && selectedMembers.isEmpty) {
      _snack(context, 'Select at least one member');
      return false;
    }
    if (splitType == SplitType.percentage) {
      final total = members.fold(0.0, (s, m) => s + m.percentage);
      if ((total - 100).abs() > 0.5) {
        _snack(context, 'Percentages must add up to 100%');
        return false;
      }
    }
    if (splitType == SplitType.share) {
      final total = members.fold(0.0, (s, m) => s + m.shareAmount);
      if ((total - totalAmount).abs() > 0.5) {
        _snack(context, 'Share amounts must add up to total');
        return false;
      }
    }
    return true;
  }

  // ── SAVE — goes through ExpenseProvider ──────────────────
  Future<void> saveExpense(BuildContext context) async {
    if (!validate(context)) return;

    isSaving = true;
    notifyListeners();

    try {
      final expenseProvider = context.read<ExpenseProvider>();

      final expense = await expenseProvider.createExpense(
        groupId: group.id,
        title: titleController.text.trim(),
        amount: totalAmount,
        category: _mapCategory(selectedCategory),
        paidByUserId: paidByUserId,
        paidByName: paidByName,
        splitType: _mapSplitType(splitType),
        memberShares: buildMemberShares(),
      );

      isSaving = false;
      notifyListeners();

      if (expense != null && context.mounted) {
        _snack(context, 'Expense saved successfully ✅', color: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();
      _snack(context, 'Failed to save: $e');
    }
  }

  String _mapCategory(String c) {
    switch (c.toLowerCase()) {
      case 'food':
        return 'Food';
      case 'travel':
        return 'Travel';
      case 'shopping':
        return 'Shopping';
      default:
        return 'Other';
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

// import 'package:flutter/material.dart';
// import 'package:splitzon/data/models/group_model.dart';

// enum SplitType { equal, percentage, share }

// class MemberModel {
//   final String id;
//   final String name;
//   final String avatar;

//   bool isSelected;
//   double percentage;
//   double shareAmount;

//   MemberModel({
//     required this.id,
//     required this.name,
//     required this.avatar,
//     this.isSelected = true,
//     this.percentage = 0,
//     this.shareAmount = 0,
//   });
// }

// class AddExpenseController extends ChangeNotifier {
//   final Group group;

//   AddExpenseController({required this.group}) {
//     loadMembers();
//     _setEqualPercentage();
//   }

//   // void loadMembers() {
//   //   members = group.members.map((name) {
//   //     return MemberModel(
//   //       id: name,
//   //       name: name,
//   //       avatar: '',
//   //       isSelected: true,
//   //       percentage: 0,
//   //       shareAmount: 0,
//   //     );
//   //   }).toList();

//   //   notifyListeners();
//   // }
//   void loadMembers() {
//     members = group.members.map((name) {
//       return MemberModel(
//         id: name,
//         name: name,
//         avatar: "https://i.pravatar.cc/150?u=$name",
//         isSelected: true,
//         percentage: 0,
//         shareAmount: 0,
//       );
//     }).toList();

//     notifyListeners();
//   }

//   final titleController = TextEditingController();
//   final amountController = TextEditingController();

//   SplitType splitType = SplitType.equal;

//   String paidBy = "You";

//   List<MemberModel> members = [];
//   double get totalAmount => double.tryParse(amountController.text) ?? 0;

//   List<MemberModel> get selectedMembers =>
//       members.where((m) => m.isSelected).toList();

//   double get equalAmount {
//     if (selectedMembers.isEmpty) return 0;
//     return totalAmount / selectedMembers.length;
//   }

//   /// -------------------------

//   void changeSplitType(SplitType type) {
//     splitType = type;

//     if (type == SplitType.equal) {
//       for (var m in members) {
//         m.isSelected = true;
//       }
//     }

//     if (type == SplitType.percentage) {
//       _setEqualPercentage();
//     }

//     notifyListeners();
//   }

//   void toggleMember(String id) {
//     final member = members.firstWhere((m) => m.id == id);

//     member.isSelected = !member.isSelected;

//     notifyListeners();
//   }

//   void changePaidBy(String name) {
//     paidBy = name;
//     notifyListeners();
//   }

//   void updatePercentage(String id, String value) {
//     final member = members.firstWhere((m) => m.id == id);

//     member.percentage = double.tryParse(value) ?? 0;

//     notifyListeners();
//   }

//   void updateShareAmount(String id, String value) {
//     final member = members.firstWhere((m) => m.id == id);

//     member.shareAmount = double.tryParse(value) ?? 0;

//     notifyListeners();
//   }

//   void _setEqualPercentage() {
//     if (members.isEmpty) return;

//     double percent = 100 / members.length;

//     for (var m in members) {
//       m.percentage = percent;
//     }
//   }

//   /// -------------------------

//   bool validateAll(BuildContext context) {
//     if (titleController.text.trim().isEmpty) {
//       _showError(context, "Enter title");
//       return false;
//     }

//     if (totalAmount <= 0) {
//       _showError(context, "Enter amount");
//       return false;
//     }

//     if (splitType == SplitType.equal) {
//       if (selectedMembers.isEmpty) {
//         _showError(context, "Select at least one member");
//         return false;
//       }
//     }

//     if (splitType == SplitType.percentage) {
//       double total = 0;

//       for (var m in members) {
//         total += m.percentage;
//       }

//       if (total.round() != 100) {
//         _showError(context, "Total percentage must equal 100%");
//         return false;
//       }
//     }

//     if (splitType == SplitType.share) {
//       double total = 0;

//       for (var m in members) {
//         total += m.shareAmount;
//       }

//       if (total != totalAmount) {
//         _showError(context, "Split amount must equal total amount");
//         return false;
//       }
//     }

//     return true;
//   }

//   void saveExpense(BuildContext context) {
//     if (!validateAll(context)) return;

//     debugPrint("Expense Saved");

//     for (var m in members) {
//       double amount = 0;

//       if (splitType == SplitType.equal) {
//         amount = m.isSelected ? equalAmount : 0;
//       }

//       if (splitType == SplitType.percentage) {
//         amount = (m.percentage / 100) * totalAmount;
//       }

//       if (splitType == SplitType.share) {
//         amount = m.shareAmount;
//       }

//       debugPrint("${m.name} -> $amount");
//     }

//     final expense = {
//       "title": titleController.text,
//       "amount": totalAmount,
//       "paidBy": paidBy,
//       "splitCount": selectedMembers.length,
//     };

//     Navigator.pop(context, expense);

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Expense Saved Successfully")));
//   }

//   void _showError(BuildContext context, String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }
// }
