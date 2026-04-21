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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/widgets/primary_button.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/services/storage_service.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  double _youOwe = 0.0;
  double _youAreOwed = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();

    // Auto refresh on any ExpenseProvider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().addListener(_onExpensesChanged);
    });
  }

  @override
  void dispose() {
    context.read<ExpenseProvider>().removeListener(_onExpensesChanged);
    super.dispose();
  }

  void _onExpensesChanged() {
    // Auto refresh balance whenever expenses change (add/edit/delete/sync)
    _fetchBalance();
    debugPrint('🔄 BalanceCard auto-refreshed after expense changes');
  }

  Future<void> _fetchBalance() async {
    // ✅ ALWAYS CALCULATE LOCALLY FIRST FOR INSTANT OFFLINE SUPPORT
    final expenseProvider = context.read<ExpenseProvider>();
    final userProvider = context.read<UserProviders>();
    final currentUserId = userProvider.user?.id ?? '';

    double localOwe = 0.0;
    double localOwed = 0.0;

    final allExpenses = expenseProvider.getAllExpenses();
    for (final expense in allExpenses) {
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
        localOwed += expense.memberShares
            .where((s) => s.isInvolved && s.userId != currentUserId)
            .fold(0.0, (sum, s) => sum + s.shareAmount);
      } else {
        localOwe += userShare.shareAmount;
      }
    }

    // Update UI immediately with local values (instant response)
    setState(() {
      _youOwe = localOwe;
      _youAreOwed = localOwed;
      _isLoading = false;
    });

    debugPrint(
      '🔵 💳 Balance calculated LOCALLY (offline ready): youOwe: ₹$localOwe | youAreOwed: ₹$localOwed',
    );

    // ✅ Then try to fetch from server in background if online
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        final balanceUrl = Uri.parse(
          '${ApiService.baseUrl.replaceAll('/auth', '')}/expenses/my-balance',
        );

        // Fast timeout for API call so we don't hang
        final response = await http
            .get(
              balanceUrl,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            )
            .timeout(const Duration(milliseconds: 3000));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final serverOwe = (data['paidToOthers'] ?? 0).toDouble();
            final serverOwed = (data['paidToMe'] ?? 0).toDouble();

            // Only update if server values are different
            if (serverOwe != _youOwe || serverOwed != _youAreOwed) {
              setState(() {
                _youOwe = serverOwe;
                _youAreOwed = serverOwed;
              });

              // Save for future offline
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('balance_youOwe', _youOwe);
              await prefs.setDouble('balance_youAreOwed', _youAreOwed);
              debugPrint('✅ 💳 Balance updated from SERVER');
            }
          }
        }
      }
    } catch (e) {
      // Ignore API errors - we already have local calculation displayed
      debugPrint('⚠️ 💳 API balance fetch failed, using local values: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final userProvider = context.watch<UserProviders>();
    final currentUserId = userProvider.user?.id ?? '';

    double youOwe = _youOwe;
    double youAreOwed = _youAreOwed;

    // Fallback calculation if no values
    if (youOwe == 0 && youAreOwed == 0) {
      final allExpenses = expenseProvider.getAllExpenses();
      for (final expense in allExpenses) {
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
          youAreOwed += expense.memberShares
              .where((s) => s.isInvolved && s.userId != currentUserId)
              .fold(0.0, (sum, s) => sum + s.shareAmount);
        } else {
          youOwe += userShare.shareAmount;
        }
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
