// ════════════════════════════════════════════════════════════════
// FILE: lib/features/add_expense/expense_detail_screen.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'add_expenses_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;
  final Group group;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late Expense _expense;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  // ── CATEGORY HELPERS ─────────────────────────────────────
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'medical':
        return Icons.local_hospital_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFE8834A);
      case 'travel':
        return const Color(0xFF4A90D9);
      case 'accommodation':
        return const Color(0xFF9C6FDE);
      case 'shopping':
        return const Color(0xFF4CAF50);
      case 'entertainment':
        return const Color(0xFFE53935);
      case 'utilities':
        return const Color(0xFFFFB300);
      case 'medical':
        return const Color(0xFF00ACC1);
      default:
        return const Color(0xFF78909C);
    }
  }

  Color _getCategoryBg(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFDF1EA);
      case 'travel':
        return const Color(0xFFEAF3FC);
      case 'accommodation':
        return const Color(0xFFF3EDFB);
      case 'shopping':
        return const Color(0xFFEAF7EA);
      case 'entertainment':
        return const Color(0xFFFFEBEE);
      case 'utilities':
        return const Color(0xFFFFF8E1);
      case 'medical':
        return const Color(0xFFE0F7FA);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // ── OPEN EDIT SCREEN ─────────────────────────────────────
  Future<void> _openEdit() async {
    final result = await Navigator.push<Expense?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          group: widget.group,
          existingExpense: _expense, // ← Enabled for edit mode
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _expense = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── DELETE EXPENSE ────────────────────────────────────────
  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "${_expense.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final ok = await context.read<ExpenseProvider>().deleteExpense(
      _expense.id,
      widget.group.id,
    );

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (ok) {
      if (mounted) Navigator.pop(context, true); // Return true = deleted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete expense')));
    }
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currencySymbol = '₹';
    final categoryColor = _getCategoryColor(_expense.category);
    final categoryBg = _getCategoryBg(_expense.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Expense Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _isDeleting ? null : _openEdit,
              ),
              IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.delete_rounded, color: Colors.red),
                onPressed: _isDeleting ? null : _deleteExpense,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact Premium Header
                  _HeaderCard(
                    expense: _expense,
                    currencySymbol: currencySymbol,
                    categoryColor: categoryColor,
                    categoryBg: categoryBg,
                    icon: _getCategoryIcon(_expense.category),
                  ),

                  const SizedBox(height: 16),

                  _DetailsCard(expense: _expense),

                  const SizedBox(height: 16),

                  _SyncStatusBadge(status: _expense.syncStatus),

                  const SizedBox(height: 24),

                  const Text(
                    'Member Breakdown',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._expense.memberShares
                      .where((s) => s.isInvolved)
                      .map(
                        (share) => _MemberShareRow(
                          share: share,
                          currencySymbol: currencySymbol,
                          isPayer: share.userId == _expense.paidByUserId,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COMPACT PREMIUM HEADER CARD
// ════════════════════════════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;
  final Color categoryColor;
  final Color categoryBg;
  final IconData icon;

  const _HeaderCard({
    super.key,
    required this.expense,
    required this.currencySymbol,
    required this.categoryColor,
    required this.categoryBg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final involvedCount = expense.memberShares
        .where((s) => s.isInvolved)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: categoryColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  expense.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            expense.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 18),

          Text(
            '$currencySymbol${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Paid by ',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                expense.paidByName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$involvedCount members',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Expense expense;

  const _DetailsCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(expense.date),
          ),
          const _Divider(),
          _DetailRow(
            icon: Icons.person_rounded,
            label: 'Paid By',
            value: expense.paidByName,
          ),
          const _Divider(),
          _DetailRow(
            icon: Icons.call_split_rounded,
            label: 'Split Type',
            value: expense.splitType.toUpperCase(),
          ),
          if (expense.notes.isNotEmpty) ...[
            const _Divider(),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: expense.notes,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.grey.shade100);
}

class _SyncStatusBadge extends StatelessWidget {
  final String status;

  const _SyncStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSynced = status == 'SYNCED';
    final isPendingUpdate = status == 'PENDING_UPDATE';
    final color = isSynced
        ? Colors.green
        : isPendingUpdate
        ? Colors.blue
        : Colors.orange;
    final icon = isSynced
        ? Icons.cloud_done_rounded
        : isPendingUpdate
        ? Icons.sync_rounded
        : Icons.cloud_upload_outlined;
    final label = isSynced
        ? 'Synced to cloud'
        : isPendingUpdate
        ? 'Update pending sync'
        : 'Pending sync';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberShareRow extends StatelessWidget {
  final MemberShare share;
  final String currencySymbol;
  final bool isPayer;

  const _MemberShareRow({
    required this.share,
    required this.currencySymbol,
    required this.isPayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPayer
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isPayer
                ? AppColors.primary.withOpacity(0.15)
                : Colors.grey.shade100,
            child: Text(
              share.name.isNotEmpty ? share.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: isPayer ? AppColors.primary : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.name.isNotEmpty ? share.name : share.userId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isPayer)
                  Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${share.shareAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPayer ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (share.percentage > 0)
                Text(
                  '${share.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
