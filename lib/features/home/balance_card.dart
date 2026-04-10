import 'package:flutter/material.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/widgets/primary_button.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Assign values here
    final double youOwe = 0.00;
    final double youAreOwed = 0.00;

    // ✅ Auto-calculated
    final double totalBalance = youAreOwed - youOwe;
    final bool isPositive = totalBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient.withOpacity(.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
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
                  SizedBox(width: 6),
                  const Text(
                    "Total Balance",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              // ✅ Dynamic +/- indicator
              Text(
                "${isPositive ? '+' : '-'}₹${totalBalance.abs().toStringAsFixed(2)}",
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 36),
              ),
              SizedBox(width: 5),
              // ✅ Dynamic total balance amount
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BalanceItem(
                  title: "You owe",
                  amount: "₹${youOwe.toStringAsFixed(2)}", // ✅ dynamic
                  color: Colors.red,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BalanceItem(
                  title: "You are owed",
                  amount: "₹${youAreOwed.toStringAsFixed(2)}", // ✅ dynamic
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
      mainAxisAlignment: MainAxisAlignment.start,
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
