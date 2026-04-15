import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_main_theme.dart';
import 'package:splitzon/features/add_group/add_group_screen.dart';
import 'package:splitzon/features/gorup_dashboard/grp_dashboard_screen.dart';
import 'package:splitzon/features/home/balance_card.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/services/firebase_auth.dart';
import 'package:splitzon/provider/user_providers.dart';

import '../../data/models/group_model.dart';

// ─────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;

  static const int _initialCount = 5;
  bool _showAll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() => userData = args);
    }
  }

  @override
  void initState() {
    super.initState();

    // Load groups from Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().initialize();
    });
  }

  // ✅ Open Add Group → insert result at TOP of list
  Future<void> _openAddGroup() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddGroupScreen()),
    );

    if (result != null && mounted) {
      // Create group via Provider
      final name = result['name'] as String;
      final members = List<String>.from(result['members'] ?? []);

      await context.read<GroupProvider>().createGroup(
        name: name,
        members: members,
        groupType: 'Other', // Default group type
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"$name" added!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final userProvider = context.watch<UserProviders>();
    // final userName = userProvider.user?.name ?? 'User';
    final userProvider = context.watch<UserProviders>();

    print("===== USER PROVIDER =====");
    print(userProvider.user);
    print("User name:");
    print(userProvider.user?.name);

    final userName = userProvider.user?.name ?? 'User';
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final mq = MediaQuery.of(context);
        final sw = mq.size.width;
        final hPad = sw * 0.05;

        final groups = groupProvider.groups;
        final visibleGroups = _showAll
            ? groups
            : groups.take(_initialCount).toList();

        return Scaffold(
          extendBody: true,
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: _openAddGroup,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const DashboardBottomBar(),
          body: BackgroundMainTheme(
            child: SafeArea(
              child: Column(
                children: [
                  // ── FIXED PINNED HEADER ──────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Menu icon with bg
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        // App name
                        Text(
                          'Splitzon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        // Profile icon with bg

                        // ✅ Replace with this:
                        GestureDetector(
                          onTap: () => FirebaseAuthMethods(
                            FirebaseAuth.instance,
                          ).signOut(context),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(.15),
                            // child: const Icon(
                            //   Icons.person,
                            //   color: AppColors.primary,
                            //   size: 20,
                            // ),
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SCROLLABLE CONTENT ───────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Greeting
                          Text(
                            'Hi, $userName 👋',
                            style: TextStyle(
                              fontSize: sw < 360 ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            "Let's review your expenses",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: sw < 360 ? 12 : 14,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Balance card
                          const BalanceCard(),

                          const SizedBox(height: 25),

                          // Quick insights
                          const Text(
                            'Quick Insights',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),

                          const SizedBox(height: 15),

                          QuickActions(onNewGroup: _openAddGroup),
                          const SizedBox(height: 25),

                          /// GROUPS HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Groups',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (groups.length > _initialCount)
                                Row(
                                  children: [
                                    Text(
                                      'See More',
                                      style: TextStyle(
                                        color: AppColors.primary.withOpacity(
                                          .8,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppColors.primary.withOpacity(.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          /// ✅ DYNAMIC GROUP LIST from Provider
                          if (groupProvider.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (groups.isEmpty)
                            _buildEmptyState()
                          else
                            ...visibleGroups.map(
                              (group) => _buildGroupCard(group),
                            ),

                          const SizedBox(height: 10),

                          /// ✅ SEE MORE / SEE LESS BUTTON AT BOTTOM
                          if (!groupProvider.isLoading &&
                              groups.length > _initialCount)
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _showAll = !_showAll),
                                icon: Icon(
                                  _showAll
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                ),
                                label: Text(_showAll ? 'See Less' : 'See More'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: AppColors.primary.withOpacity(.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to get started',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // REPLACE your _buildGroupCard method in dashboard_screen.dart
  // with this version — adds onTap to navigate to GroupDetailScreen
  // ══════════════════════════════════════════════════════════

  // Add this import at the top of dashboard_screen.dart:
  // import 'package:splitzon/features/group_detail/group_detail_screen.dart';

  Widget _buildGroupCard(Group group) {
    final userProvider = context.read<UserProviders>();

    final currentUserId = userProvider.user?.id ?? "";
    print("===== GROUP =====");
    print(group.name);
    print("Members:");
    print(group.members);
    String currencySymbol = _getCurrencySymbol(group.currency);

    return GestureDetector(
      onTap: () {
        // ✅ Navigate to GroupDetailScreen passing the group
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                    ),
                    child: _buildGroupImage(group),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.overallBudget != null &&
                              group.overallBudget! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$currencySymbol${_formatBudget(group.overallBudget!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (group.description != null &&
                          group.description!.isNotEmpty)
                        Text(
                          group.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 28,
                            width: group.members.length > 3
                                ? 100
                                : (group.members.length * 20.0 + 8),
                            child: Builder(
                              builder: (context) {
                                final displayCount = group.members.length > 3
                                    ? 3
                                    : group.members.length;

                                final remaining =
                                    group.members.length - displayCount;

                                return Stack(
                                  children: [
                                    // Show first 3 members
                                    ...List.generate(displayCount, (index) {
                                      return Positioned(
                                        left: index * 18.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: AppColors.primary
                                                .withOpacity(.2),
                                            child: Text(
                                              // getInitial(group.members[index]),
                                              getAvatarText(
                                                group.members[index],
                                                currentUserId,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),

                                    // Show +N if more members
                                    if (remaining > 0)
                                      Positioned(
                                        left: displayCount * 18.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            child: Text(
                                              '+$remaining',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // SizedBox(
                          //   height: 28,
                          //   width: group.members.length > 3
                          //       ? 70
                          //       : (group.members.length * 20.0 + 8),
                          //   child: Stack(
                          //     children: List.generate(
                          //       group.members.length > 3
                          //           ? 3
                          //           : group.members.length,
                          //       (index) => Positioned(
                          //         left: index * 18.0,
                          //         child: Container(
                          //           decoration: BoxDecoration(
                          //             shape: BoxShape.circle,
                          //             border: Border.all(
                          //               color: Colors.white,
                          //               width: 2,
                          //             ),
                          //           ),
                          //           child: CircleAvatar(
                          //             radius: 12,
                          //             backgroundColor: AppColors.primary
                          //                 .withOpacity(.2),
                          //             child: Text(
                          //               getInitial(group.members[index]),
                          //               // group.members[index].isNotEmpty
                          //               //     ? group.members[index][0]
                          //               //           .toUpperCase()
                          //               //     : '?',
                          //               style: TextStyle(
                          //                 fontSize: 10,
                          //                 color: AppColors.primary,
                          //                 fontWeight: FontWeight.bold,
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Text(
                            '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupImage(Group group) {
    // Show local image if available, otherwise show placeholder
    if (group.bannerImagePath != null && group.bannerImagePath!.isNotEmpty) {
      return Image.file(
        File(group.bannerImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _getGroupTypeIcon(group.groupType),
            size: 32,
            color: AppColors.primary.withOpacity(.5),
          );
        },
      );
    } else if (group.bannerImageUrl != null &&
        group.bannerImageUrl!.isNotEmpty) {
      return Image.network(
        group.bannerImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _getGroupTypeIcon(group.groupType),
            size: 32,
            color: AppColors.primary.withOpacity(.5),
          );
        },
      );
    } else {
      // Placeholder icon based on group type
      return Icon(
        _getGroupTypeIcon(group.groupType),
        size: 32,
        color: AppColors.primary.withOpacity(.5),
      );
    }
  }

  IconData _getGroupTypeIcon(String groupType) {
    switch (groupType.toLowerCase()) {
      case 'trip':
        return Icons.flight_takeoff_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'office':
        return Icons.work_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '$currencyCode ';
    }
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return budget.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // String getInitial(String value) {
  //   if (value.isEmpty) return '?';

  //   // If value is number like "6"
  //   if (int.tryParse(value) != null) {
  //     return 'U'; // fallback letter
  //   }

  //   return value[0].toUpperCase();
  // }

  String getAvatarText(String member, String currentUserId) {
    // If this member is current user
    if (member == currentUserId) {
      return "Me";
    }

    if (member.isEmpty) return "?";

    // Show first letter for others
    return member[0].toUpperCase();
  }
}

// ─────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────

class DashboardBottomBar extends StatefulWidget {
  const DashboardBottomBar({super.key});

  @override
  State<DashboardBottomBar> createState() => _DashboardBottomBarState();
}

class _DashboardBottomBarState extends State<DashboardBottomBar> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Friends',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Activity',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24), // ✅ floating effect
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
            onTap: () => setState(() => _currentIndex = index),
            behavior: HitTestBehavior.opaque,
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

// ─────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────

class QuickActions extends StatelessWidget {
  final VoidCallback onNewGroup;

  const QuickActions({super.key, required this.onNewGroup});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ActionItem(
          icon: Icons.person_add,
          label: 'New Group',
          color: Colors.green,
          onTap: onNewGroup, // ✅ connected
        ),
        const ActionItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          color: Colors.orange,
        ),
        const ActionItem(
          icon: Icons.history_rounded,
          label: 'Activity',
          color: Colors.blue,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// ACTION ITEM
// ─────────────────────────────────────────

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap; // ✅ receive function

  const ActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ✅ use passed function
      child: Container(
        height: 110,
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
