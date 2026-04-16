// ════════════════════════════════════════════════════════════════
// FILE: lib/features/home/balance_card.dart
// ════════════════════════════════════════════════════════════════
//
// Reads ALL expenses from ExpenseProvider and calculates:
//  - youOwe:     total you owe others across all groups
//  - youAreOwed: total others owe you across all groups
//  - totalBalance = youAreOwed - youOwe
//
// Auto-updates when any expense is added/removed/synced.
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/widgets/primary_button.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/provider/user_providers.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final userProvider = context.watch<UserProviders>();
    final currentUserId = userProvider.user?.id ?? '';

    debugPrint('💳 BalanceCard rebuilding — userId: $currentUserId');

    double youOwe = 0.0;
    double youAreOwed = 0.0;

    // ── Calculate across ALL groups ───────────────────────
    final allExpenses = expenseProvider.getAllExpenses();
    debugPrint(
      '💳 BalanceCard: computing from ${allExpenses.length} total expenses',
    );

    for (final expense in allExpenses) {
      // Find current user's share in this expense
      MemberShare? userShare;
      try {
        userShare = expense.memberShares.firstWhere(
          (s) => s.userId == currentUserId,
        );
      } catch (_) {
        userShare = null;
      }

      if (userShare == null || !userShare.isInvolved) continue;

      if (expense.paidByUserId == currentUserId) {
        // I paid → others owe me their shares
        // My own share I don't owe to myself
        final othersShare = expense.memberShares
            .where((s) => s.isInvolved && s.userId != currentUserId)
            .fold(0.0, (sum, s) => sum + s.shareAmount);
        youAreOwed += othersShare;
        debugPrint(
          '💳   [${expense.title}] I paid → others owe me: ₹$othersShare',
        );
      } else {
        // Someone else paid → I owe my share
        youOwe += userShare.shareAmount;
        debugPrint(
          '💳   [${expense.title}] ${expense.paidByName} paid → I owe: ₹${userShare.shareAmount}',
        );
      }
    }

    final totalBalance = youAreOwed - youOwe;
    final isPositive = totalBalance >= 0;

    debugPrint(
      '💳 BalanceCard result → youOwe: ₹$youOwe | youAreOwed: ₹$youAreOwed | net: ₹$totalBalance',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Text(
                '${isPositive ? '+' : '-'}₹${totalBalance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ── Big amount ────────────────────────────────────
          Row(
            children: [
              Text(
                '₹',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 36),
              ),
              const SizedBox(width: 5),
              Text(
                totalBalance.abs().toStringAsFixed(2),
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ── You owe / You are owed ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BalanceItem(
                  title: 'You owe',
                  amount: '₹${youOwe.toStringAsFixed(2)}',
                  color: Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BalanceItem(
                  title: 'You are owed',
                  amount: '₹${youAreOwed.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            title: 'Settle All Debts',
            onPressed: () {},
            icon: Icons.arrow_outward_rounded,
          ),
        ],
      ),
    );
  }
}

class BalanceItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const BalanceItem({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/core/widgets/primary_button.dart';

// class BalanceCard extends StatelessWidget {
//   const BalanceCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Assign values here
//     final double youOwe = 0.00;
//     final double youAreOwed = 0.00;

//     // ✅ Auto-calculated
//     final double totalBalance = youAreOwed - youOwe;
//     final bool isPositive = totalBalance >= 0;

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: AppColors.backgroundGradient.withOpacity(.6),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     Icons.account_balance_wallet_outlined,
//                     color: AppColors.primary,
//                     size: 20,
//                   ),
//                   SizedBox(width: 6),
//                   const Text(
//                     "Total Balance",
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ],
//               ),
//               // ✅ Dynamic +/- indicator
//               Text(
//                 "${isPositive ? '+' : '-'}₹${totalBalance.abs().toStringAsFixed(2)}",
//                 style: TextStyle(
//                   color: isPositive ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 15),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               Text(
//                 '₹',
//                 style: TextStyle(color: AppColors.textSecondary, fontSize: 36),
//               ),
//               SizedBox(width: 5),
//               // ✅ Dynamic total balance amount
//               Text(
//                 totalBalance.abs().toStringAsFixed(2),
//                 style: TextStyle(
//                   color: isPositive ? Colors.green : Colors.red,
//                   fontSize: 28,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 15),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(.4),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: BalanceItem(
//                   title: "You owe",
//                   amount: "₹${youOwe.toStringAsFixed(2)}", // ✅ dynamic
//                   color: Colors.red,
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(.4),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: BalanceItem(
//                   title: "You are owed",
//                   amount: "₹${youAreOwed.toStringAsFixed(2)}", // ✅ dynamic
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           PrimaryButton(
//             title: 'Settle All Debts',
//             onPressed: () {},
//             icon: Icons.arrow_outward_rounded,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BalanceItem extends StatelessWidget {
//   final String title;
//   final String amount;
//   final Color color;

//   const BalanceItem({
//     super.key,
//     required this.title,
//     required this.amount,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           amount,
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }
// }
