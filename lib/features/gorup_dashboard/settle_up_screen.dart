// lib/features/group_detail/settle_up_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/providers/settlement_provider.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/provider/user_providers.dart';

class SettleUpScreen extends StatefulWidget {
  final Group group;
  const SettleUpScreen({super.key, required this.group});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final _amountController = TextEditingController();
  String? selectedFromUserId;
  String? selectedToUserId;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    currentUserId = context.read<UserProviders>().user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final settlementProvider = context.watch<SettlementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Record Settlement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Who paid whom?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // From (Payer)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Paid By",
                border: OutlineInputBorder(),
              ),
              value: selectedFromUserId,
              items: widget.group.members.map((member) {
                return DropdownMenuItem(
                  value: member.id, // Assuming member has id
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedFromUserId = value),
            ),

            const SizedBox(height: 20),

            // To (Receiver)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Paid To",
                border: OutlineInputBorder(),
              ),
              value: selectedToUserId,
              items: widget.group.members.map((member) {
                return DropdownMenuItem(
                  value: member.id,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedToUserId = value),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(_amountController.text.trim()) ?? 0;
                  if (amount <= 0 ||
                      selectedFromUserId == null ||
                      selectedToUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final fromMember = widget.group.members.firstWhere(
                    (m) => m.id == selectedFromUserId,
                  );
                  final toMember = widget.group.members.firstWhere(
                    (m) => m.id == selectedToUserId,
                  );

                  final success = await settlementProvider.recordSettlement(
                    groupId: widget.group.id,
                    fromUserId: selectedFromUserId!,
                    fromUserName: fromMember.name,
                    toUserId: selectedToUserId!,
                    toUserName: toMember.name,
                    amount: amount,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Settlement recorded successfully"),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Record Settlement",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
