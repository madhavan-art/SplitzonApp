// ════════════════════════════════════════════════════════════════
// FILE: lib/features/add_expense/add_expenses_screen.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_expenses_controller.dart';
import 'package:splitzon/data/models/group_model.dart';

class AddExpenseScreen extends StatelessWidget {
  final Group group;
  const AddExpenseScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddExpenseController(group: group),
      child: const _AddExpenseView(),
    );
  }
}

class _AddExpenseView extends StatefulWidget {
  const _AddExpenseView();

  @override
  State<_AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<_AddExpenseView> {
  static const primary = Color(0xFF4A90E2);
  static const background = Color(0xFFF5F7FA);
  static const cardBorder = Color(0xFFE3E8EF);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AddExpenseController>();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── AMOUNT ──────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 32,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: c.amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => c.notifyListeners(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── TITLE ────────────────────────────────────────
              const Text(
                'What was it for?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: TextField(
                  controller: c.titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dinner at Blue Bay',
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                  onChanged: (_) => c.notifyListeners(),
                ),
              ),

              const SizedBox(height: 20),

              // ── EXPENSE TYPE ─────────────────────────────────
              const Text(
                'Expense Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _typeChip(c, 'General'),
                  _typeChip(c, 'Food'),
                  _typeChip(c, 'Travel'),
                  _typeChip(c, 'Shopping'),
                ],
              ),

              const SizedBox(height: 20),

              // ── PAID BY ──────────────────────────────────────
              const Text(
                'Paid by',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  c.paidByName.isEmpty ? 'You' : c.paidByName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── SPLIT HEADER ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Split with',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${c.selectedMembers.length}/${c.members.length} Members',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── SPLIT TYPE ───────────────────────────────────
              Row(
                children: [
                  _splitChip(context, 'Equal', SplitType.equal),
                  _splitChip(context, 'Percentage', SplitType.percentage),
                  _splitChip(context, 'Custom', SplitType.share),
                ],
              ),

              const SizedBox(height: 14),

              // ── SPLIT SUMMARY (percentage / custom) ──────────
              Consumer<AddExpenseController>(
                builder: (ctx, ctrl, _) {
                  if (ctrl.splitType == SplitType.percentage) {
                    final total = ctrl.totalPercentage;
                    final isOk = (total - 100.0).abs() < 0.01;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total: ${total.toStringAsFixed(1)}% / 100%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOk ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (ctrl.splitType == SplitType.share) {
                    final entered = ctrl.totalShareAmount;
                    final target = ctrl.totalAmount;
                    final isOk = target > 0 && (entered - target).abs() < 0.01;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total: ₹${entered.toStringAsFixed(2)} / ₹${target.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOk ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // ── MEMBERS LIST ─────────────────────────────────
              Consumer<AddExpenseController>(
                builder: (ctx, ctrl, _) => Column(
                  children: ctrl.members
                      .map((m) => _memberCard(ctrl, m))
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ── SAVE BUTTON ──────────────────────────────────
              Consumer<AddExpenseController>(
                builder: (ctx, ctrl, _) {
                  final enabled = ctrl.canSave && !ctrl.isSaving;
                  final hint = ctrl.validationHint;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: enabled ? () => ctrl.saveExpense(ctx) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: enabled
                                  ? const [Color(0xFF4A90E2), Color(0xFF5DADE2)]
                                  : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade300,
                                    ],
                            ),
                            boxShadow: enabled
                                ? [
                                    BoxShadow(
                                      color: primary.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: ctrl.isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Expense',
                                    style: TextStyle(
                                      color: enabled
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      // Validation hint below button
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                hint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── TYPE CHIP ──────────────────────────────────────────────
  Widget _typeChip(AddExpenseController c, String text) {
    final selected = c.selectedCategory == text;
    return GestureDetector(
      onTap: () {
        c.selectedCategory = text;
        c.notifyListeners();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // ── SPLIT CHIP ─────────────────────────────────────────────
  Widget _splitChip(BuildContext context, String text, SplitType type) {
    return Expanded(
      child: Consumer<AddExpenseController>(
        builder: (ctx, c, _) {
          final selected = c.splitType == type;
          return GestureDetector(
            onTap: () => c.changeSplitType(type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? Border.all(color: primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? primary : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── MEMBER CARD ────────────────────────────────────────────
  Widget _memberCard(AddExpenseController c, MemberModel m) {
    final String displayName;
    if (m.name == c.paidByName || m.id == c.paidByUserId) {
      displayName = 'You';
    } else if (m.name.length > 18) {
      displayName = '${m.name.substring(0, 8)}…';
    } else {
      displayName = m.name;
    }

    // Per-member share preview for equal split
    String sharePreview = '';
    if (c.splitType == SplitType.equal && m.isSelected && c.totalAmount > 0) {
      final share = c.totalAmount / c.totalSelected;
      sharePreview = '₹${share.toStringAsFixed(2)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isSelected ? primary : cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(m.avatar),
            onBackgroundImageError: (_, __) {},
            child: m.avatar.isEmpty
                ? Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                // Show share preview for equal split
                if (sharePreview.isNotEmpty)
                  Text(
                    sharePreview,
                    style: const TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Member',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),

          // ── Input per split type ───────────────────────────
          if (c.splitType == SplitType.equal)
            Checkbox(
              value: m.isSelected,
              onChanged: (_) => c.toggleMember(m.id),
              activeColor: primary,
            ),

          if (c.splitType == SplitType.percentage)
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => c.updatePercentage(m.id, v),
              ),
            ),

          if (c.splitType == SplitType.share)
            SizedBox(
              width: 90,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => c.updateShareAmount(m.id, v),
              ),
            ),
        ],
      ),
    );
  }
}
