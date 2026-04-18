// ════════════════════════════════════════════════════════════════
// FILE: lib/features/group_detail/group_detail_screen.dart
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/features/Add_members/add_members_screen.dart';
import 'package:splitzon/features/add_expense/add_expenses_screen.dart';
import 'package:splitzon/features/gorup_dashboard/grp_dashboard_controller.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/features/commentActivity/activity_screen.dart';
import 'package:splitzon/features/gorup_dashboard/group_settings_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late GroupDetailController _ctrl;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();

    // Build controller with current user id
    final currentUserId = context.read<UserProviders>().user?.id ?? '';
    _ctrl = GroupDetailController(
      group: widget.group,
      currentUserId: currentUserId,
    );

    // Load expenses from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses(widget.group.id);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.05;

    // Sync expense provider data into controller
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.getExpenses(widget.group.id);
    _ctrl.setExpenses(expenses);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      bottomNavigationBar: const GroupDetailBottomBar(),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<ExpenseProvider>().loadExpenses(widget.group.id),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _HeroBannerCard(
                      group: widget.group,
                      totalExpenses: _ctrl.totalExpenses,
                      symbol: _ctrl.symbol,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: expenseProvider.isLoading(widget.group.id)
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _CombinedStatusCard(ctrl: _ctrl),
                              const SizedBox(height: 24),
                              _ExpensesHeader(onViewAll: () {}),
                              const SizedBox(height: 14),
                              if (expenses.isEmpty)
                                _EmptyExpenses()
                              else
                                ...expenses.map(
                                  (e) => _ExpenseCard(
                                    expense: e,
                                    symbol: _ctrl.symbol,
                                  ),
                                ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(group: widget.group),
            ),
          );
          // Refresh after returning from add expense screen
          if (mounted) {
            context.read<ExpenseProvider>().loadExpenses(widget.group.id);
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.group.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupSettingsScreen(group: widget.group),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// HERO BANNER CARD
// ════════════════════════════════════════════════════════════════

class _HeroBannerCard extends StatelessWidget {
  final Group group;
  final double totalExpenses;
  final String symbol;

  const _HeroBannerCard({
    required this.group,
    required this.totalExpenses,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    const double cardH = 180;
    const double avatarR = 16.0;

    return SizedBox(
      height: cardH + avatarR,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: cardH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _background(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF87CEEB),
                          Color(0xFFB8E4F9),
                          Color(0xFFE8F7FF),
                          Colors.white,
                        ],
                        stops: [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL GROUP EXPENSES',
                          style: TextStyle(
                            color: const Color(0xFF1565C0).withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$symbol${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0D47A1),
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_rounded,
                                    size: 13,
                                    color: Color(0xFF1565C0),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${group.members.length} Members',
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: _MemberAvatarOverflow(group: group, avatarRadius: avatarR),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    // ALWAYS SHOW GROUP LETTER FIRST
    final letterWidget = Center(
      child: Text(
        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 110,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.15),
        ),
      ),
    );

    if (group.hasBanner) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.25,
            child:
                group.bannerImagePath != null &&
                    group.bannerImagePath!.isNotEmpty
                ? Image.file(File(group.bannerImagePath!), fit: BoxFit.cover)
                : Image.network(
                    group.bannerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
          letterWidget,
        ],
      );
    }

    // No banner: show only letter
    return letterWidget;
  }
}

class _MemberAvatarOverflow extends StatelessWidget {
  final Group group;
  final double avatarRadius;
  const _MemberAvatarOverflow({
    required this.group,
    required this.avatarRadius,
  });

  static const _colors = [
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final show = group.members.length > 4 ? 4 : group.members.length;
    final total = group.members.length;
    return Row(
      children: List.generate(show, (i) {
        return Transform.translate(
          offset: Offset(i * -(avatarRadius * 0.4), 0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
              ],
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: _colors[i % _colors.length].withOpacity(0.85),
              child: (total > 4 && i == 3)
                  ? Text(
                      '+${total - 3}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: avatarRadius * 0.65,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      group.members[i].isNotEmpty
                          ? group.members[i][0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: avatarRadius * 0.65,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// COMBINED STATUS CARD (Your Status + Balances + Settle)
// ════════════════════════════════════════════════════════════════

class _CombinedStatusCard extends StatelessWidget {
  final GroupDetailController ctrl;
  const _CombinedStatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final total = ctrl.youOweTotal.abs();
    final debt = ctrl.topDebt;
    final bals = ctrl.balances;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YOUR STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                ctrl.isOwing
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: ctrl.isOwing ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ctrl.isOwing
                      ? 'You owe ${ctrl.symbol}${total.toStringAsFixed(2)}'
                      : total == 0
                      ? 'All settled up ✅'
                      : 'You are owed ${ctrl.symbol}${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ctrl.isOwing
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                  ),
                ),
              ),
            ],
          ),

          if (bals.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            ...bals.map((b) => _BalanceRow(balance: b, symbol: ctrl.symbol)),
          ],

          if (debt != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ctrl.settleUp(debt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settle with ${debt.name} '
                      '(${ctrl.symbol}${debt.amount.abs().toStringAsFixed(2)})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final MemberBalance balance;
  final String symbol;
  const _BalanceRow({required this.balance, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final isOwing = balance.amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _Avatar(label: 'You', color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${isOwing ? '-' : '+'}$symbol${balance.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOwing
                        ? Colors.red.shade400
                        : Colors.green.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isOwing
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Avatar(label: balance.avatar, color: Colors.orange),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              balance.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
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

class _Avatar extends StatelessWidget {
  final String label;
  final Color color;
  const _Avatar({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: color.withOpacity(0.15),
    child: Text(
      label[0].toUpperCase(),
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// EXPENSES SECTION
// ════════════════════════════════════════════════════════════════

class _ExpensesHeader extends StatelessWidget {
  final VoidCallback onViewAll;
  const _ExpensesHeader({required this.onViewAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Recent Expenses',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      GestureDetector(
        onTap: onViewAll,
        child: const Text(
          'View All',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    ],
  );
}

class _EmptyExpenses extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(
          Icons.receipt_long_rounded,
          size: 56,
          color: AppColors.primary.withOpacity(0.25),
        ),
        const SizedBox(height: 14),
        const Text(
          'No expenses yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap + to add the first expense',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

// Maps category string → icon + colors (same style as existing cards)
IconData _iconForCategory(String cat) {
  switch (cat.toLowerCase()) {
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

Color _iconColorForCategory(String cat) {
  switch (cat.toLowerCase()) {
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

Color _iconBgForCategory(String cat) {
  switch (cat.toLowerCase()) {
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
  return '${months[dt.month - 1]} ${dt.day}';
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String symbol;
  const _ExpenseCard({required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(expense.category);
    final iconColor = _iconColorForCategory(expense.category);
    final iconBg = _iconBgForCategory(expense.category);
    final involved = expense.memberShares.where((s) => s.isInvolved).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // PENDING badge
                    if (expense.syncStatus == 'PENDING')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(expense.date)} · Paid by ${expense.paidByName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$symbol${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '1/$involved SPLIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
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

// ─────────────────────────────────────────
// GROUP DETAIL BOTTOM BAR
// Same style as Home screen
// ─────────────────────────────────────────

class GroupDetailBottomBar extends StatefulWidget {
  const GroupDetailBottomBar({super.key});

  @override
  State<GroupDetailBottomBar> createState() => _GroupDetailBottomBarState();
}

class _GroupDetailBottomBarState extends State<GroupDetailBottomBar> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Friends',
    ),
    _NavItem(
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Analytics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withOpacity(.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isActive = _currentIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });

              // Navigation logic
              switch (index) {
                case 0:
                  Navigator.pop(context);
                  break;

                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMembersScreen(
                        groupId: context
                            .findAncestorWidgetOfExactType<GroupDetailScreen>()!
                            .group
                            .id,
                      ),
                    ),
                  );
                  break;

                case 2:
                  final group = context
                      .findAncestorWidgetOfExactType<GroupDetailScreen>()!
                      .group;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityScreen(
                        groupId: group.id,
                        groupName: group.name,
                      ),
                    ),
                  );
                  break;

                case 3:
                  // TODO: Navigate to Analytics
                  break;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? AppColors.primary : Colors.grey.shade500,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// // ════════════════════════════════════════════════════════════════
// // FILE: lib/features/group_detail/group_detail_screen.dart
// // ════════════════════════════════════════════════════════════════

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/data/models/group_model.dart';
// import 'package:splitzon/features/add_expense/add_expenses_screen.dart';
// import 'package:splitzon/features/gorup_dashboard/grp_dashboard_controller.dart';

// class GroupDetailScreen extends StatefulWidget {
//   final Group group;
//   const GroupDetailScreen({super.key, required this.group});

//   @override
//   State<GroupDetailScreen> createState() => _GroupDetailScreenState();
// }

// class _GroupDetailScreenState extends State<GroupDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;
//   late Animation<Offset> _slideAnim;
//   late GroupDetailController _ctrl;

//   final _titleCtrl = TextEditingController();
//   final _amountCtrl = TextEditingController();
//   final _paidByCtrl = TextEditingController();
//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = GroupDetailController(group: widget.group);
//     _ctrl.addListener(() => setState(() {}));

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.08),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

//     _animController.forward();
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     _ctrl.dispose();
//     _titleCtrl.dispose();
//     _amountCtrl.dispose();
//     _paidByCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sw = MediaQuery.of(context).size.width;
//     final hPad = sw * 0.05;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FF),
//       body: FadeTransition(
//         opacity: _fadeAnim,
//         child: SlideTransition(
//           position: _slideAnim,
//           child: RefreshIndicator(
//             onRefresh: _ctrl.refresh,
//             color: AppColors.primary,
//             child: CustomScrollView(
//               slivers: [
//                 // ── CUSTOM APP BAR (not SliverAppBar — gives full control)
//                 SliverToBoxAdapter(child: _buildTopBar()),

//                 // ── HERO BANNER CARD ──────────────────────
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: hPad),
//                     child: _HeroBannerCard(
//                       group: widget.group,
//                       totalExpenses: _ctrl.totalExpenses,
//                       symbol: _ctrl.symbol,
//                     ),
//                   ),
//                 ),

//                 // ── BODY ──────────────────────────────────
//                 SliverToBoxAdapter(
//                   child: _ctrl.isLoading
//                       ? const SizedBox(
//                           height: 200,
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               color: AppColors.primary,
//                             ),
//                           ),
//                         )
//                       : Padding(
//                           padding: EdgeInsets.symmetric(horizontal: hPad),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 20),

//                               // ── COMBINED STATUS + BALANCES + SETTLE ──
//                               _CombinedStatusCard(ctrl: _ctrl),

//                               const SizedBox(height: 24),

//                               // ── RECENT EXPENSES ──────────────────────
//                               _ExpensesHeader(onViewAll: () {}),
//                               const SizedBox(height: 14),
//                               ..._ctrl.expenses.map(
//                                 (e) => _ExpenseCard(
//                                   expense: e,
//                                   symbol: _ctrl.symbol,
//                                 ),
//                               ),
//                               const SizedBox(height: 120),
//                             ],
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         onPressed: () async {
//           final result = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => AddExpenseScreen(group: widget.group),
//             ),
//           );

//           if (result != null && result is ExpenseItem) {
//             _ctrl.addExpenseItem(result);
//           }
//         },
//         child: const Icon(Icons.add_rounded),
//       ),
//     );
//   }

//   // ── TOP BAR — title always centered, fully visible ────────
//   Widget _buildTopBar() {
//     return Container(
//       color: Colors.white,
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           child: Row(
//             children: [
//               // Back button — fixed width
//               SizedBox(
//                 width: 44,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(0.08),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Icon(
//                       Icons.arrow_back_ios_new_rounded,
//                       color: AppColors.primary,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),

//               // Title — takes all remaining space, perfectly centered
//               Expanded(
//                 child: Text(
//                   widget.group.name,
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ),

//               // Settings button — fixed width (mirrors back button)
//               SizedBox(
//                 width: 44,
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.08),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: IconButton(
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                     icon: const Icon(
//                       Icons.settings_rounded,
//                       color: AppColors.primary,
//                       size: 20,
//                     ),
//                     onPressed: () {},
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // HERO BANNER CARD
// // - Sky blue → white gradient
// // - Big total expense amount
// // - Member count bottom right
// // - Member avatars half inside / half outside card
// // ════════════════════════════════════════════════════════════════

// class _HeroBannerCard extends StatelessWidget {
//   final Group group;
//   final double totalExpenses;
//   final String symbol;

//   const _HeroBannerCard({
//     required this.group,
//     required this.totalExpenses,
//     required this.symbol,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Card height — avatars overflow by half their size (24px radius = 48px diameter)
//     const double cardHeight = 180;
//     const double avatarRadius = 16.0;

//     return SizedBox(
//       // Extra space below card for avatar overflow
//       height: cardHeight + avatarRadius,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           // ── THE CARD ──────────────────────────────────────
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: cardHeight,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Background: image or gradient
//                   _background(),

//                   // Sky blue → white overlay gradient
//                   Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           Color(0xFF87CEEB), // sky blue
//                           Color(0xFFB8E4F9), // light sky
//                           Color(0xFFE8F7FF), // near white
//                           Colors.white,
//                         ],
//                         stops: [0.0, 0.35, 0.7, 1.0],
//                       ),
//                     ),
//                   ),

//                   // Content
//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Label
//                         Text(
//                           'TOTAL GROUP EXPENSES',
//                           style: TextStyle(
//                             color: const Color(0xFF1565C0).withOpacity(0.7),
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 1.6,
//                           ),
//                         ),
//                         const SizedBox(height: 6),

//                         // Big amount
//                         Text(
//                           '$symbol${totalExpenses.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             // color: Color(0xFF0D47A1),
//                             // color: Colors.white,
//                             color: const Color(0xFF0D47A1),
//                             fontSize: 36,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: -1,
//                           ),
//                         ),

//                         const Spacer(),

//                         // Bottom row: spacer + member count on right
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 5,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF1565C0).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(20),
//                                 border: Border.all(
//                                   color: const Color(
//                                     0xFF1565C0,
//                                   ).withOpacity(0.2),
//                                 ),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Icon(
//                                     Icons.people_rounded,
//                                     size: 13,
//                                     color: Color(0xFF1565C0),
//                                   ),
//                                   const SizedBox(width: 5),
//                                   Text(
//                                     '${group.members.length} Members',
//                                     style: const TextStyle(
//                                       color: Color(0xFF1565C0),
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ── MEMBER AVATARS — half inside, half outside card ──
//           Positioned(
//             bottom: 0,
//             left: 20,
//             child: _MemberAvatarOverflow(
//               group: group,
//               avatarRadius: avatarRadius,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _background() {
//     if (group.bannerImagePath != null && group.bannerImagePath!.isNotEmpty) {
//       return Opacity(
//         opacity: 0.15, // subtle — let gradient dominate
//         child: Image.file(File(group.bannerImagePath!), fit: BoxFit.cover),
//       );
//     }
//     if (group.bannerImageUrl != null && group.bannerImageUrl!.isNotEmpty) {
//       return Opacity(
//         opacity: 0.15,
//         child: Image.network(
//           group.bannerImageUrl!,
//           fit: BoxFit.cover,
//           errorBuilder: (_, __, ___) => const SizedBox.shrink(),
//         ),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// // ── MEMBER AVATARS OVERFLOW ROW ───────────────────────────────
// // Avatars sit with bottom half below the card edge
// class _MemberAvatarOverflow extends StatelessWidget {
//   final Group group;
//   final double avatarRadius;

//   const _MemberAvatarOverflow({
//     required this.group,
//     required this.avatarRadius,
//   });

//   static const _bgColors = [
//     Color(0xFF1565C0),
//     Color(0xFFE65100),
//     Color(0xFF2E7D32),
//     Color(0xFF6A1B9A),
//     Color(0xFF00695C),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final total = group.members.length;

//     // LOGIC: show max 4 avatars
//     final show = total > 4 ? 4 : total;

//     final diameter = avatarRadius * 2;

//     return Row(
//       children: [
//         ...List.generate(show, (i) {
//           return Transform.translate(
//             offset: Offset(i * -(avatarRadius * 0.4), 0),
//             child: Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 2.5),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.12),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: CircleAvatar(
//                 radius: avatarRadius,
//                 backgroundColor: _bgColors[i % _bgColors.length].withOpacity(
//                   0.85,
//                 ),

//                 child: (total > 4 && i == 3)
//                     // LOGIC: last slot shows +remaining
//                     ? Text(
//                         '+${total - 3}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: avatarRadius * 0.65,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       )
//                     : Text(
//                         group.members[i].isNotEmpty
//                             ? group.members[i][0].toUpperCase()
//                             : '?',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: avatarRadius * 0.65,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // COMBINED STATUS CARD
// // Contains: Your Status + Balance rows + Settle Up — all in ONE card
// // ════════════════════════════════════════════════════════════════

// class _CombinedStatusCard extends StatelessWidget {
//   final GroupDetailController ctrl;
//   const _CombinedStatusCard({required this.ctrl});

//   @override
//   Widget build(BuildContext context) {
//     final total = ctrl.youOweTotal.abs();
//     final debt = ctrl.topDebt;

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 14,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── YOUR STATUS ──────────────────────────────────
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'YOUR STATUS',
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textSecondary,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//               Icon(
//                 Icons.info_outline_rounded,
//                 size: 16,
//                 color: AppColors.textSecondary,
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Icon(
//                 ctrl.isOwing
//                     ? Icons.trending_down_rounded
//                     : Icons.trending_up_rounded,
//                 color: ctrl.isOwing ? Colors.red : Colors.green,
//                 size: 20,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 ctrl.isOwing
//                     ? 'You owe ${ctrl.symbol}${total.toStringAsFixed(2)}'
//                     : 'You are owed ${ctrl.symbol}${total.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: ctrl.isOwing
//                       ? Colors.red.shade600
//                       : Colors.green.shade600,
//                 ),
//               ),
//             ],
//           ),

//           // ── DIVIDER ──────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             child: Divider(height: 1, color: Colors.grey.shade100),
//           ),

//           // ── BALANCE ROWS ─────────────────────────────────
//           ...ctrl.balances.map(
//             (b) => _BalanceRow(balance: b, symbol: ctrl.symbol),
//           ),

//           // ── SETTLE UP ────────────────────────────────────
//           if (debt != null) ...[
//             const SizedBox(height: 12),
//             GestureDetector(
//               onTap: () => ctrl.settleUp(debt),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 13),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: AppColors.primary.withOpacity(0.25),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.check_circle_outline_rounded,
//                       size: 17,
//                       color: AppColors.primary,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Settle with ${debt.name} '
//                       '(${ctrl.symbol}${debt.amount.abs().toStringAsFixed(2)})',
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ── BALANCE ROW ───────────────────────────────────────────────
// class _BalanceRow extends StatelessWidget {
//   final MemberBalance balance;
//   final String symbol;
//   const _BalanceRow({required this.balance, required this.symbol});

//   @override
//   Widget build(BuildContext context) {
//     final isOwing = balance.amount < 0;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 7),
//       child: Row(
//         children: [
//           _Avatar(label: 'You', color: AppColors.primary),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               children: [
//                 Text(
//                   '${isOwing ? '-' : '+'}$symbol${balance.amount.abs().toStringAsFixed(2)}',
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: isOwing
//                         ? Colors.red.shade400
//                         : Colors.green.shade500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   height: 2,
//                   decoration: BoxDecoration(
//                     color: isOwing
//                         ? Colors.red.shade200
//                         : Colors.green.shade200,
//                     borderRadius: BorderRadius.circular(1),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           _Avatar(label: balance.avatar, color: Colors.orange),
//           const SizedBox(width: 8),
//           SizedBox(
//             width: 52,
//             child: Text(
//               balance.name,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Avatar extends StatelessWidget {
//   final String label;
//   final Color color;
//   // TODO: add profileImageUrl parameter when real data is available
//   const _Avatar({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) => CircleAvatar(
//     radius: 20,
//     backgroundColor: color.withOpacity(0.15),
//     child: Text(
//       label[0].toUpperCase(),
//       style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════
// // EXPENSE WIDGETS
// // ════════════════════════════════════════════════════════════════

// class _ExpensesHeader extends StatelessWidget {
//   final VoidCallback onViewAll;
//   const _ExpensesHeader({required this.onViewAll});

//   @override
//   Widget build(BuildContext context) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       const Text(
//         'Recent Expenses',
//         style: TextStyle(
//           fontSize: 17,
//           fontWeight: FontWeight.bold,
//           color: AppColors.textPrimary,
//         ),
//       ),
//       GestureDetector(
//         onTap: onViewAll,
//         child: const Text(
//           'View All',
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//             color: AppColors.primary,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// class _ExpenseCard extends StatelessWidget {
//   final ExpenseItem expense;
//   final String symbol;
//   const _ExpenseCard({required this.expense, required this.symbol});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: expense.iconBg,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(expense.icon, color: expense.iconColor, size: 22),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   expense.title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${expense.date} · Paid by ${expense.paidBy}',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '$symbol${expense.amount.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w800,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Text(
//                   '1/${expense.splitCount} SPLIT',
//                   style: TextStyle(
//                     fontSize: 9,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primary,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── INPUT FIELD ───────────────────────────────────────────────
// class _InputField extends StatelessWidget {
//   final TextEditingController controller;
//   final String hint;
//   final IconData icon;
//   final bool isNumber;

//   const _InputField({
//     required this.controller,
//     required this.hint,
//     required this.icon,
//     this.isNumber = false,
//   });

//   @override
//   Widget build(BuildContext context) => TextFormField(
//     controller: controller,
//     keyboardType: isNumber
//         ? const TextInputType.numberWithOptions(decimal: true)
//         : TextInputType.text,
//     style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
//     decoration: InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//       prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
//       filled: true,
//       fillColor: const Color(0xFFF5F9FF),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey.shade200),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
//       ),
//     ),
//   );
// }
