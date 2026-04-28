// // ════════════════════════════════════════════════════════════════
// // FILE: lib/features/group_detail/group_detail_controller.dart
// // ════════════════════════════════════════════════════════════════

// import 'package:flutter/material.dart';
// import 'package:splitzon/data/models/group_model.dart';

// // ─────────────────────────────────────────────────────────────
// // MODELS
// // ─────────────────────────────────────────────────────────────

// class ExpenseItem {
//   final String title;
//   final String date;
//   final String paidBy;
//   final double amount;
//   final int splitCount;
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;

//   const ExpenseItem({
//     required this.title,
//     required this.date,
//     required this.paidBy,
//     required this.amount,
//     required this.splitCount,
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//   });
// }

// class MemberBalance {
//   final String name;
//   final double amount; // negative = you owe them, positive = they owe you
//   final String avatar;

//   const MemberBalance({
//     required this.name,
//     required this.amount,
//     required this.avatar,
//   });
// }

// // ─────────────────────────────────────────────────────────────
// // CONTROLLER
// // ─────────────────────────────────────────────────────────────

// class GroupDetailController extends ChangeNotifier {
//   final Group group;

//   GroupDetailController({required this.group}) {
//     _loadData();
//   }

//   void addExpenseItem(ExpenseItem item) {
//     expenses = [item, ...expenses];

//     notifyListeners();
//   }

//   bool isLoading = false;

//   // Mock data — replace with real API calls later
//   List<ExpenseItem> expenses = const [
//     ExpenseItem(
//       title: 'Flight Tickets',
//       date: 'Oct 12',
//       paidBy: 'Alex',
//       amount: 1240.00,
//       splitCount: 4,
//       icon: Icons.flight_rounded,
//       iconColor: Color(0xFF4A90D9),
//       iconBg: Color(0xFFEAF3FC),
//     ),

//     ExpenseItem(
//       title: 'Sushi Dinner',
//       date: 'Oct 13',
//       paidBy: 'Jordan',
//       amount: 320.50,
//       splitCount: 4,
//       icon: Icons.restaurant_rounded,
//       iconColor: Color(0xFFE8834A),
//       iconBg: Color(0xFFFDF1EA),
//     ),
//     ExpenseItem(
//       title: 'Museum Entry',
//       date: 'Oct 14',
//       paidBy: 'You',
//       amount: 185.00,
//       splitCount: 4,
//       icon: Icons.museum_rounded,
//       iconColor: Color(0xFF4CAF50),
//       iconBg: Color(0xFFEAF7EA),
//     ),
//     ExpenseItem(
//       title: 'Hotel Night 1',
//       date: 'Oct 15',
//       paidBy: 'Alex',
//       amount: 520.00,
//       splitCount: 4,
//       icon: Icons.hotel_rounded,
//       iconColor: Color(0xFF9C6FDE),
//       iconBg: Color(0xFFF3EDFB),
//     ),
//   ];

//   List<MemberBalance> balances = const [
//     MemberBalance(name: 'Jordan', amount: -100.0, avatar: 'J'),
//     MemberBalance(name: 'Evans', amount: -42.50, avatar: 'E'),
//     MemberBalance(name: 'Alex', amount: 75.0, avatar: 'A'),
//   ];

//   // ── COMPUTED PROPERTIES ───────────────────────────────────

//   double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);

//   double get youOweTotal =>
//       balances.where((b) => b.amount < 0).fold(0.0, (sum, b) => sum + b.amount);

//   bool get isOwing => youOweTotal < 0;

//   /// The biggest debt — used for the "Settle Up" button
//   MemberBalance? get topDebt {
//     final owing = balances.where((b) => b.amount < 0).toList()
//       ..sort((a, b) => a.amount.compareTo(b.amount));
//     return owing.isEmpty ? null : owing.first;
//   }

//   String getCurrencySymbol(String code) {
//     switch (code.toUpperCase()) {
//       case 'INR':
//         return '₹';
//       case 'USD':
//         return '\$';
//       case 'EUR':
//         return '€';
//       case 'GBP':
//         return '£';
//       default:
//         return code;
//     }
//   }

//   String get symbol => getCurrencySymbol(group.currency);

//   // ── ACTIONS ───────────────────────────────────────────────

//   /// Called on init — replace body with real API call later
//   Future<void> _loadData() async {
//     isLoading = true;
//     notifyListeners();

//     // TODO: replace with real API call
//     // final result = await ExpenseService.getExpenses(group.id);
//     // expenses = result.expenses;
//     // balances = result.balances;

//     await Future.delayed(const Duration(milliseconds: 300)); // simulate load
//     isLoading = false;
//     notifyListeners();
//   }

//   /// Refresh — called on pull-to-refresh
//   Future<void> refresh() async => await _loadData();

//   /// Add expense — replace with real API call later
//   Future<bool> addExpense({
//     required String title,
//     required double amount,
//     required String paidBy,
//   }) async {
//     try {
//       // TODO: POST to /api/expenses/create
//       debugPrint('➕ Adding expense: $title — $symbol$amount paid by $paidBy');
//       await _loadData(); // refresh after adding
//       return true;
//     } catch (e) {
//       debugPrint('❌ Add expense error: $e');
//       return false;
//     }
//   }

//   /// Settle up — replace with real API call later
//   Future<bool> settleUp(MemberBalance balance) async {
//     try {
//       // TODO: POST to /api/settlements/create
//       debugPrint(
//         '💸 Settling with ${balance.name}: $symbol${balance.amount.abs()}',
//       );
//       await _loadData();
//       return true;
//     } catch (e) {
//       debugPrint('❌ Settle up error: $e');
//       return false;
//     }
//   }
// }

// ════════════════════════════════════════════════════════════════
// FILE: lib/features/group_detail/group_detail_controller.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/group_model.dart';

// ─────────────────────────────────────────────────────────────
// RE-EXPORT expense model types so screen can import one file
// ─────────────────────────────────────────────────────────────
export 'package:splitzon/data/models/expense_model.dart'
    show Expense, MemberShare;

// ─────────────────────────────────────────────────────────────
// MEMBER BALANCE MODEL
// ─────────────────────────────────────────────────────────────

class MemberBalance {
  final String userId;
  final String name;
  final double amount; // negative = you owe them, positive = they owe you

  const MemberBalance({
    required this.userId,
    required this.name,
    required this.amount,
  });

  String get avatar => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ─────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────

class GroupDetailController extends ChangeNotifier {
  final Group group;
  final String currentUserId;

  GroupDetailController({required this.group, required this.currentUserId});

  bool isLoading = false;

  // Expenses are injected from ExpenseProvider — no mock data
  List<Expense> expenses = [];

  // ── COMPUTED ──────────────────────────────────────────────

  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Calculate balances from real expense data (local SQLite — persists across refreshes)
  ///
  /// For each expense:
  ///   - payer gets credited the full amount
  ///   - each involved member gets debited their share
  ///
  /// Net per user = totalPaid - totalOwed
  ///
  /// From currentUser's perspective vs another user X:
  ///   currentUser.net - X.net > 0  → X owes currentUser
  ///   currentUser.net - X.net < 0  → currentUser owes X
  List<MemberBalance> get balances {
    // net[userId] = totalPaid - totalOwed  (positive = net creditor)
    final Map<String, double> net = {};
    final Map<String, String> names = {};

    for (final expense in expenses) {
      final payer = expense.paidByUserId;
      if (payer.isNotEmpty) {
        net[payer] = (net[payer] ?? 0) + expense.amount;
        names[payer] = expense.paidByName;
      }

      for (final share in expense.memberShares) {
        if (!share.isInvolved || share.shareAmount <= 0) continue;
        final uid = share.userId;
        net[uid] = (net[uid] ?? 0) - share.shareAmount;
        if (names[uid] == null && share.name.isNotEmpty) {
          names[uid] = share.name;
        }
      }
    }

    // currentUser's net balance
    final myNet = net[currentUserId] ?? 0.0;

    // Build per-person balance relative to current user
    final result = <MemberBalance>[];
    net.forEach((uid, theirNet) {
      if (uid == currentUserId) return; // skip self

      // Simplified two-party settlement:
      // If I paid for them → they owe me → positive
      // If they paid for me → I owe them → negative
      // We compute this as: myNet - theirNet projected onto the pair
      // But the simplest correct approach: look at each expense directly.
      // We'll use the direct pairwise approach below.
    });

    // ── PAIRWISE APPROACH (most accurate) ─────────────────────
    // For each other member, compute how much currentUser owes them (negative)
    // or they owe currentUser (positive).
    final Map<String, double> pairwise = {};

    for (final expense in expenses) {
      final payer = expense.paidByUserId;
      if (payer.isEmpty) continue;

      for (final share in expense.memberShares) {
        if (!share.isInvolved || share.shareAmount <= 0) continue;
        final debtor = share.userId;
        if (debtor == payer) continue; // payer doesn't owe themselves

        // debtor owes payer share.shareAmount
        if (debtor == currentUserId) {
          // I owe payer → negative for payer entry
          pairwise[payer] = (pairwise[payer] ?? 0) - share.shareAmount;
          if (names[payer] == null) names[payer] = expense.paidByName;
        } else if (payer == currentUserId) {
          // payer (me) is owed by debtor → positive for debtor entry
          pairwise[debtor] = (pairwise[debtor] ?? 0) + share.shareAmount;
          if (names[debtor] == null && share.name.isNotEmpty) {
            names[debtor] = share.name;
          }
        }
      }
    }

    // Only show members with non-zero balance
    pairwise.forEach((uid, amount) {
      if (amount.abs() < 0.01) return; // ignore dust
      result.add(
        MemberBalance(userId: uid, name: names[uid] ?? uid, amount: amount),
      );
    });

    return result;
  }

  /// Total amount currentUser owes (sum of negative balances)
  double get youOweTotal =>
      balances.where((b) => b.amount < 0).fold(0.0, (s, b) => s + b.amount);

  bool get isOwing => youOweTotal < 0;

  MemberBalance? get topDebt {
    final owing = balances.where((b) => b.amount < 0).toList()
      ..sort((a, b) => a.amount.compareTo(b.amount));
    return owing.isEmpty ? null : owing.first;
  }

  String getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return code;
    }
  }

  String get symbol => getCurrencySymbol(group.currency);

  // ── ACTIONS ───────────────────────────────────────────────

  Future<void> refresh() async {
    // GroupDetailScreen calls ExpenseProvider.loadExpenses(groupId)
    // and passes updated list here via setExpenses
    notifyListeners();
  }

  /// Called by GroupDetailScreen when ExpenseProvider updates
  void setExpenses(List<Expense> newExpenses) {
    expenses = newExpenses;
    notifyListeners();
  }

  /// Settle up — replace with real API call later
  Future<bool> settleUp(MemberBalance balance) async {
    debugPrint(
      '💸 Settling with ${balance.name}: $symbol${balance.amount.abs()}',
    );
    // TODO: POST to /api/settlements/create
    return true;
  }
}
