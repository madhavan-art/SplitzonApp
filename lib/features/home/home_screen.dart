// // ════════════════════════════════════════════════════════════════
// // FILE: lib/features/group_detail/group_detail_screen.dart
// // ════════════════════════════════════════════════════════════════

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/data/models/expense_model.dart';
// import 'package:splitzon/data/models/group_model.dart';
// import 'package:splitzon/features/Add_members/add_members_screen.dart';
// import 'package:splitzon/features/add_expense/add_expenses_screen.dart';
// import 'package:splitzon/provider/user_providers.dart';
// import 'package:splitzon/providers/expense_provider.dart';

// class GroupDetailScreen extends StatefulWidget {
//   final Group group;
//   const GroupDetailScreen({super.key, required this.group});

//   @override
//   State<GroupDetailScreen> createState() => _GroupDetailScreenState();
// }

// class _GroupDetailScreenState extends State<GroupDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animCtrl;
//   late Animation<double> _fade;
//   late Animation<Offset> _slide;

//   @override
//   void initState() {
//     super.initState();

//     _animCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
//     _slide = Tween<Offset>(
//       begin: const Offset(0, 0.06),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

//     _animCtrl.forward();

//     // Load expenses for this group (works offline)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ExpenseProvider>().loadExpenses(widget.group.id);
//     });
//   }

//   @override
//   void dispose() {
//     _animCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sw = MediaQuery.of(context).size.width;
//     final hPad = sw * 0.05;

//     final expenseProvider = context.watch<ExpenseProvider>();
//     final expenses = expenseProvider.getExpenses(widget.group.id);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F8FF),
//       bottomNavigationBar: GroupDetailBottomBar(group: widget.group),
//       body: FadeTransition(
//         opacity: _fade,
//         child: SlideTransition(
//           position: _slide,
//           child: RefreshIndicator(
//             onRefresh: () =>
//                 context.read<ExpenseProvider>().loadExpenses(widget.group.id),
//             color: AppColors.primary,
//             child: CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(child: _buildTopBar()),
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: hPad),
//                     child: _HeroBannerCard(
//                       group: widget.group,
//                       totalExpenses: _calculateTotalExpenses(expenses),
//                       symbol: _getCurrencySymbol(widget.group.currency),
//                     ),
//                   ),
//                 ),
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: hPad),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 20),
//                         _CombinedStatusCard(
//                           group: widget.group,
//                           expenses: expenses,
//                         ),
//                         const SizedBox(height: 24),
//                         _ExpensesHeader(),
//                         const SizedBox(height: 14),

//                         if (expenseProvider.isLoading(widget.group.id))
//                           const SizedBox(
//                             height: 200,
//                             child: Center(
//                               child: CircularProgressIndicator(
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                           )
//                         else if (expenses.isEmpty)
//                           const _EmptyExpenses()
//                         else
//                           ...expenses.map(
//                             (e) => _ExpenseCard(
//                               expense: e,
//                               symbol: _getCurrencySymbol(widget.group.currency),
//                             ),
//                           ),

//                         const SizedBox(height: 120),
//                       ],
//                     ),
//                   ),
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
//           await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => AddExpenseScreen(group: widget.group),
//             ),
//           );
//           if (mounted) {
//             context.read<ExpenseProvider>().loadExpenses(widget.group.id);
//           }
//         },
//         child: const Icon(Icons.add_rounded),
//       ),
//     );
//   }

//   Widget _buildTopBar() => Container(
//     color: Colors.white,
//     child: SafeArea(
//       bottom: false,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         child: Row(
//           children: [
//             SizedBox(
//               width: 44,
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.08),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Icon(
//                     Icons.arrow_back_ios_new_rounded,
//                     color: AppColors.primary,
//                     size: 18,
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Text(
//                 widget.group.name,
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   color: AppColors.primary,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 44),
//           ],
//         ),
//       ),
//     ),
//   );

//   double _calculateTotalExpenses(List<Expense> expenses) {
//     return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
//   }

//   String _getCurrencySymbol(String currencyCode) {
//     switch (currencyCode.toUpperCase()) {
//       case 'INR':
//         return '₹';
//       case 'USD':
//         return '\$';
//       case 'EUR':
//         return '€';
//       case 'GBP':
//         return '£';
//       default:
//         return '$currencyCode ';
//     }
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // HERO BANNER CARD
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
//     const double cardH = 180;
//     const double avatarR = 16.0;

//     return SizedBox(
//       height: cardH + avatarR,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: cardH,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   _background(),
//                   Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           Color(0xFF87CEEB),
//                           Color(0xFFB8E4F9),
//                           Color(0xFFE8F7FF),
//                           Colors.white,
//                         ],
//                         stops: [0.0, 0.35, 0.7, 1.0],
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'TOTAL GROUP EXPENSES',
//                           style: TextStyle(
//                             color: const Color(0xFF1565C0).withOpacity(0.7),
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 1.4,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           '$symbol${totalExpenses.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             color: Color(0xFF0D47A1),
//                             fontSize: 36,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: -1,
//                           ),
//                         ),
//                         const Spacer(),
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
//           Positioned(
//             bottom: 0,
//             left: 20,
//             child: _MemberAvatarOverflow(group: group, avatarRadius: avatarR),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _background() {
//     if (group.bannerImagePath != null && group.bannerImagePath!.isNotEmpty) {
//       return Opacity(
//         opacity: 0.15,
//         child: Image.file(File(group.bannerImagePath!), fit: BoxFit.cover),
//       );
//     }
//     if (group.bannerImageUrl != null && group.bannerImageUrl!.isNotEmpty) {
//       return Opacity(
//         opacity: 0.15,
//         child: Image.network(group.bannerImageUrl!, fit: BoxFit.cover),
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// class _MemberAvatarOverflow extends StatelessWidget {
//   final Group group;
//   final double avatarRadius;

//   const _MemberAvatarOverflow({
//     required this.group,
//     required this.avatarRadius,
//   });

//   static const _colors = [
//     Color(0xFF1565C0),
//     Color(0xFFE65100),
//     Color(0xFF2E7D32),
//     Color(0xFF6A1B9A),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final show = group.members.length > 4 ? 4 : group.members.length;
//     final total = group.members.length;

//     return Row(
//       children: List.generate(show, (i) {
//         return Transform.translate(
//           offset: Offset(i * -(avatarRadius * 0.4), 0),
//           child: Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 2.5),
//             ),
//             child: CircleAvatar(
//               radius: avatarRadius,
//               backgroundColor: _colors[i % _colors.length].withOpacity(0.85),
//               child: (total > 4 && i == 3)
//                   ? Text(
//                       '+${total - 3}',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: avatarRadius * 0.65,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     )
//                   : Text(
//                       group.members[i].isNotEmpty
//                           ? group.members[i][0].toUpperCase()
//                           : '?',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: avatarRadius * 0.65,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // COMBINED STATUS CARD
// // ════════════════════════════════════════════════════════════════

// class _CombinedStatusCard extends StatelessWidget {
//   final Group group;
//   final List<Expense> expenses;

//   const _CombinedStatusCard({required this.group, required this.expenses});

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = context.watch<UserProviders>();
//     final currentUserId = userProvider.user?.id ?? '';

//     double youOwe = 0.0;
//     double youAreOwed = 0.0;

//     for (final expense in expenses) {
//       final userShare = expense.memberShares.firstWhere(
//         (share) => share.userId == currentUserId,
//         orElse: () => MemberShare(userId: currentUserId, amount: 0.0),
//       );

//       if (expense.paidByUserId == currentUserId) {
//         youAreOwed += userShare.amount;
//       } else {
//         youOwe += userShare.amount;
//       }
//     }

//     final total = (youAreOwed - youOwe).abs();
//     final isOwing = youOwe > youAreOwed;
//     final symbol = _getCurrencySymbol(group.currency);

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
//                 isOwing
//                     ? Icons.trending_down_rounded
//                     : Icons.trending_up_rounded,
//                 color: isOwing ? Colors.red : Colors.green,
//                 size: 20,
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   isOwing
//                       ? 'You owe $symbol${total.toStringAsFixed(2)}'
//                       : total == 0
//                       ? 'All settled up ✅'
//                       : 'You are owed $symbol${total.toStringAsFixed(2)}',
//                   style: TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold,
//                     color: isOwing
//                         ? Colors.red.shade600
//                         : Colors.green.shade600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   String _getCurrencySymbol(String currencyCode) {
//     switch (currencyCode.toUpperCase()) {
//       case 'INR':
//         return '₹';
//       case 'USD':
//         return '\$';
//       case 'EUR':
//         return '€';
//       case 'GBP':
//         return '£';
//       default:
//         return '$currencyCode ';
//     }
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // EXPENSES SECTION
// // ════════════════════════════════════════════════════════════════

// class _ExpensesHeader extends StatelessWidget {
//   const _ExpensesHeader();

//   @override
//   Widget build(BuildContext context) => const Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(
//         'Recent Expenses',
//         style: TextStyle(
//           fontSize: 17,
//           fontWeight: FontWeight.bold,
//           color: AppColors.textPrimary,
//         ),
//       ),
//       Text(
//         'View All',
//         style: TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           color: AppColors.primary,
//         ),
//       ),
//     ],
//   );
// }

// class _EmptyExpenses extends StatelessWidget {
//   const _EmptyExpenses();

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(36),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.04),
//           blurRadius: 8,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [
//         Icon(
//           Icons.receipt_long_rounded,
//           size: 56,
//           color: AppColors.primary.withOpacity(0.25),
//         ),
//         const SizedBox(height: 14),
//         const Text(
//           'No expenses yet',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           'Tap + to add the first expense',
//           style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
//         ),
//       ],
//     ),
//   );
// }

// class _ExpenseCard extends StatelessWidget {
//   final Expense expense;
//   final String symbol;

//   const _ExpenseCard({required this.expense, required this.symbol});

//   @override
//   Widget build(BuildContext context) {
//     final involved = expense.memberShares.where((s) => s.amount > 0).length;

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
//               color: _iconBgForCategory(expense.category),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(
//               _iconForCategory(expense.category),
//               color: _iconColorForCategory(expense.category),
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         expense.title,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                     ),
//                     if (expense.syncStatus == 'PENDING')
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Text(
//                           'Pending',
//                           style: TextStyle(
//                             fontSize: 9,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${_formatDate(expense.date)} · Paid by ${expense.paidByName}',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
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
//                   '1/$involved SPLIT',
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

//   // Category Helpers
//   IconData _iconForCategory(String cat) {
//     switch (cat.toLowerCase()) {
//       case 'food':
//         return Icons.restaurant_rounded;
//       case 'travel':
//         return Icons.flight_rounded;
//       case 'accommodation':
//         return Icons.hotel_rounded;
//       case 'shopping':
//         return Icons.shopping_bag_rounded;
//       case 'entertainment':
//         return Icons.movie_rounded;
//       case 'utilities':
//         return Icons.bolt_rounded;
//       case 'medical':
//         return Icons.local_hospital_rounded;
//       default:
//         return Icons.receipt_long_rounded;
//     }
//   }

//   Color _iconColorForCategory(String cat) {
//     switch (cat.toLowerCase()) {
//       case 'food':
//         return const Color(0xFFE8834A);
//       case 'travel':
//         return const Color(0xFF4A90D9);
//       case 'accommodation':
//         return const Color(0xFF9C6FDE);
//       case 'shopping':
//         return const Color(0xFF4CAF50);
//       case 'entertainment':
//         return const Color(0xFFE53935);
//       case 'utilities':
//         return const Color(0xFFFFB300);
//       case 'medical':
//         return const Color(0xFF00ACC1);
//       default:
//         return const Color(0xFF78909C);
//     }
//   }

//   Color _iconBgForCategory(String cat) {
//     switch (cat.toLowerCase()) {
//       case 'food':
//         return const Color(0xFFFDF1EA);
//       case 'travel':
//         return const Color(0xFFEAF3FC);
//       case 'accommodation':
//         return const Color(0xFFF3EDFB);
//       case 'shopping':
//         return const Color(0xFFEAF7EA);
//       case 'entertainment':
//         return const Color(0xFFFFEBEE);
//       case 'utilities':
//         return const Color(0xFFFFF8E1);
//       case 'medical':
//         return const Color(0xFFE0F7FA);
//       default:
//         return const Color(0xFFF5F5F5);
//     }
//   }

//   String _formatDate(DateTime dt) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     return '${months[dt.month - 1]} ${dt.day}';
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // BOTTOM BAR
// // ════════════════════════════════════════════════════════════════

// class GroupDetailBottomBar extends StatelessWidget {
//   final Group group;

//   const GroupDetailBottomBar({super.key, required this.group});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(
//           color: AppColors.primary.withOpacity(0.2),
//           width: 1.2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(0.08),
//             blurRadius: 20,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _NavItem(
//             icon: Icons.dashboard_outlined,
//             activeIcon: Icons.dashboard,
//             label: 'Dashboard',
//             onTap: () => Navigator.pop(context),
//           ),
//           _NavItem(
//             icon: Icons.people_outline,
//             activeIcon: Icons.people_rounded,
//             label: 'Members',
//             onTap: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => AddMembersScreen(groupId: group.id),
//               ),
//             ),
//           ),
//           _NavItem(
//             icon: Icons.access_time_outlined,
//             activeIcon: Icons.access_time,
//             label: 'Activity',
//             onTap: () {},
//           ),
//           _NavItem(
//             icon: Icons.bar_chart_outlined,
//             activeIcon: Icons.bar_chart,
//             label: 'Analytics',
//             onTap: () {},
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: Colors.grey.shade500, size: 24),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_main_theme.dart';
import 'package:splitzon/features/Profile_page/profile_screen.dart';
import 'package:splitzon/features/add_group/add_group_screen.dart';
import 'package:splitzon/features/gorup_dashboard/grp_dashboard_screen.dart';
import 'package:splitzon/features/home/balance_card.dart';
import 'package:splitzon/features/commentActivity/activity_screen.dart';
import 'package:splitzon/features/commentActivity/activity_controller.dart';
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
      context.read<ActivityController>().initialize();
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

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProviders>();
    final userName = userProvider.user?.name ?? 'User';

    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final mq = MediaQuery.of(context);
        final sw = mq.size.width;
        final hPad = sw * 0.05;

        // Pages for bottom navigation
        final List<Widget> pages = [
          // Home Page
          _buildHomePage(userName, sw, hPad, groupProvider),
          // Activity Page
          const ActivityScreen(),
          // Analytics Page
          _buildAnalyticsPage(),
          // Profile Page
          const ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true,
          floatingActionButton: _selectedNavIndex == 0
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: _openAddGroup,
                  child: const Icon(Icons.add),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: _buildBottomNav(),
          body: BackgroundMainTheme(
            child: IndexedStack(index: _selectedNavIndex, children: pages),
          ),
        );
      },
    );
  }

  Widget _buildHomePage(
    String userName,
    double sw,
    double hPad,
    GroupProvider groupProvider,
  ) {
    final groups = groupProvider.groups;
    final visibleGroups = _showAll
        ? groups
        : groups.take(_initialCount).toList();

    return SafeArea(
      child: Column(
        children: [
          // ── FIXED PINNED HEADER ──────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
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
                Text(
                  'Splitzon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(.15),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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

                  QuickActions(
                    onNewGroup: _openAddGroup,
                    onAnalytics: () {
                      // Navigate to Analytics tab (index 2)
                      setState(() {
                        _selectedNavIndex = 2;
                      });
                    },
                    onActivity: () {
                      // Navigate to Activity tab (index 1)
                      setState(() {
                        _selectedNavIndex = 1;
                      });
                    },
                  ),
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
                                color: AppColors.primary.withOpacity(.8),
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
                    ...visibleGroups.map((group) => _buildGroupCard(group)),

                  const SizedBox(height: 10),

                  /// ✅ SEE MORE / SEE LESS BUTTON AT BOTTOM
                  if (!groupProvider.isLoading && groups.length > _initialCount)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showAll = !_showAll),
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
    );
  }

  Widget _buildAnalyticsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text('Coming Soon', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.access_time_outlined,
        activeIcon: Icons.access_time_filled,
        label: 'Activity',
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'Analytics',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

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
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = _selectedNavIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedNavIndex = index);
            },
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
    String currencySymbol = _getCurrencySymbol(group.currency);

    return GestureDetector(
      onTap: () {
        // ✅ FULL GROUP DEBUG LOG WHEN CLICKING GROUP CARD
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('  🟢 GROUP CARD CLICKED: ${group.name}');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('  Group ID:    ${group.id}');
        debugPrint('  Name:        ${group.name}');
        debugPrint('  Type:        ${group.groupType}');
        debugPrint('  Created By:  ${group.createdBy ?? 'N/A'}');
        debugPrint('  Budget:      ${group.overallBudget}');
        debugPrint('  Currency:    ${group.currency}');
        debugPrint('  Sync Status: ${group.syncStatus}');
        debugPrint('  Created At:  ${group.createdAt}');
        debugPrint('');
        debugPrint('  ➤ MEMBERS LIST (${group.members.length} total):');
        for (var i = 0; i < group.members.length; i++) {
          final member = group.members[i];
          final isCurrentUser = member == currentUserId ? ' ✅ (YOU)' : '';
          debugPrint('    [$i] ${member.toString()}$isCurrentUser');
        }
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('');

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

  String getAvatarText(dynamic member, String currentUserId) {
    if (member.name?.isNotEmpty == true) {
      return member.name![0].toUpperCase();
    }

    if (member.id?.isNotEmpty == true) {
      return member.id[0].toUpperCase();
    }

    return "?";
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
// BOTTOM BAR
// ─────────────────────────────────────────

// ─────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────

class QuickActions extends StatelessWidget {
  final VoidCallback onNewGroup;
  final VoidCallback onAnalytics;
  final VoidCallback onActivity;

  const QuickActions({
    super.key,
    required this.onNewGroup,
    required this.onAnalytics,
    required this.onActivity,
  });

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
        ActionItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          color: Colors.orange,
          onTap: onAnalytics, // ✅ connected
        ),
        ActionItem(
          icon: Icons.history_rounded,
          label: 'Activity',
          color: Colors.blue,
          onTap: onActivity, // ✅ connected
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
