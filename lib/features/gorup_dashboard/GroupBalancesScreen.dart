// // ════════════════════════════════════════════════════════════════
// // FILE: lib/features/group_detail/group_balances_screen.dart
// // ════════════════════════════════════════════════════════════════

// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/data/models/group_model.dart';
// import 'package:splitzon/data/models/expense_model.dart';
// import 'package:splitzon/data/models/member_model.dart';
// import 'package:splitzon/provider/user_providers.dart';
// import 'package:splitzon/providers/expense_provider.dart';

// // ─────────────────────────────────────────────────────────────────
// // SETTLEMENT MODEL
// // ─────────────────────────────────────────────────────────────────

// class Settlement {
//   final String fromUserId;
//   final String fromName;
//   final String toUserId;
//   final String toName;
//   final double amount;

//   const Settlement({
//     required this.fromUserId,
//     required this.fromName,
//     required this.toUserId,
//     required this.toName,
//     required this.amount,
//   });
// }

// // ─────────────────────────────────────────────────────────────────
// // BALANCE ENGINE — Splitwise-style debt simplification
// // ─────────────────────────────────────────────────────────────────

// class BalanceEngine {
//   /// Compute net balance for every member from expenses.
//   /// net > 0 → they are owed money
//   /// net < 0 → they owe money
//   static Map<String, _BalanceMeta> computeNetBalances(
//     List<Expense> expenses,
//     List<Member> groupMembers,
//   ) {
//     final Map<String, _BalanceMeta> net = {};

//     // Pre-populate all group members so even non-participants show up
//     for (final m in groupMembers) {
//       net[m.id] = _BalanceMeta(userId: m.id, name: m.name, net: 0);
//     }

//     for (final expense in expenses) {
//       final payer = expense.paidByUserId;
//       if (payer.isEmpty) continue;

//       // Payer gets credited
//       net.putIfAbsent(
//         payer,
//         () => _BalanceMeta(userId: payer, name: expense.paidByName, net: 0),
//       );
//       net[payer]!.net += expense.amount;

//       // Each involved member gets debited their share
//       for (final share in expense.memberShares) {
//         if (!share.isInvolved || share.shareAmount <= 0) continue;
//         final uid = share.userId;
//         net.putIfAbsent(
//           uid,
//           () => _BalanceMeta(userId: uid, name: share.name, net: 0),
//         );
//         net[uid]!.net -= share.shareAmount;
//         // Update name if empty
//         if (net[uid]!.name.isEmpty && share.name.isNotEmpty) {
//           net[uid]!.name = share.name;
//         }
//       }
//     }

//     return net;
//   }

//   /// Simplify debts — minimum number of transactions.
//   /// Uses greedy creditor/debtor matching (same as Splitwise).
//   static List<Settlement> simplifyDebts(Map<String, _BalanceMeta> netBalances) {
//     final settlements = <Settlement>[];

//     // Separate into creditors (net > 0) and debtors (net < 0)
//     final creditors =
//         netBalances.values
//             .where((b) => b.net > 0.01)
//             .map(
//               (b) => _MutableBalance(
//                 userId: b.userId,
//                 name: b.name,
//                 amount: b.net,
//               ),
//             )
//             .toList()
//           ..sort((a, b) => b.amount.compareTo(a.amount)); // largest first

//     final debtors =
//         netBalances.values
//             .where((b) => b.net < -0.01)
//             .map(
//               (b) => _MutableBalance(
//                 userId: b.userId,
//                 name: b.name,
//                 amount: b.net.abs(),
//               ),
//             )
//             .toList()
//           ..sort((a, b) => b.amount.compareTo(a.amount)); // largest first

//     int ci = 0, di = 0;
//     while (ci < creditors.length && di < debtors.length) {
//       final creditor = creditors[ci];
//       final debtor = debtors[di];

//       final settled = math.min(creditor.amount, debtor.amount);
//       if (settled > 0.01) {
//         settlements.add(
//           Settlement(
//             fromUserId: debtor.userId,
//             fromName: debtor.name,
//             toUserId: creditor.userId,
//             toName: creditor.name,
//             amount: double.parse(settled.toStringAsFixed(2)),
//           ),
//         );
//       }

//       creditor.amount -= settled;
//       debtor.amount -= settled;

//       if (creditor.amount < 0.01) ci++;
//       if (debtor.amount < 0.01) di++;
//     }

//     return settlements;
//   }
// }

// class _BalanceMeta {
//   final String userId;
//   String name;
//   double net;
//   _BalanceMeta({required this.userId, required this.name, required this.net});
// }

// class _MutableBalance {
//   final String userId;
//   final String name;
//   double amount;
//   _MutableBalance({
//     required this.userId,
//     required this.name,
//     required this.amount,
//   });
// }

// // ─────────────────────────────────────────────────────────────────
// // MAIN SCREEN
// // ─────────────────────────────────────────────────────────────────

// class GroupBalancesScreen extends StatefulWidget {
//   final Group group;

//   const GroupBalancesScreen({super.key, required this.group});

//   @override
//   State<GroupBalancesScreen> createState() => _GroupBalancesScreenState();
// }

// class _GroupBalancesScreenState extends State<GroupBalancesScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabCtrl;
//   String _currentUserId = '';
//   String _currentUserName = '';

//   @override
//   void initState() {
//     super.initState();
//     _tabCtrl = TabController(length: 2, vsync: this);
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final user = context.read<UserProviders>().user;
//     _currentUserId = user?.id ?? '';
//     _currentUserName = user?.name ?? 'You';
//   }

//   @override
//   void dispose() {
//     _tabCtrl.dispose();
//     super.dispose();
//   }

//   // ── BUILD ───────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final expenses = context.watch<ExpenseProvider>().getExpenses(
//       widget.group.id,
//     );

//     final netBalances = BalanceEngine.computeNetBalances(
//       expenses,
//       widget.group.members,
//     );

//     final settlements = BalanceEngine.simplifyDebts(netBalances);

//     // My personal balance summary
//     final myNet = netBalances[_currentUserId]?.net ?? 0.0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7FF),
//       body: NestedScrollView(
//         headerSliverBuilder: (ctx, innerBoxScrolled) => [
//           _buildSliverHeader(myNet, settlements, netBalances),
//         ],
//         body: TabBarView(
//           controller: _tabCtrl,
//           children: [
//             // Tab 0: Suggested Settlements
//             _SettlementsTab(
//               settlements: settlements,
//               currentUserId: _currentUserId,
//               currentUserName: _currentUserName,
//               group: widget.group,
//               onSettle: _handleSettle,
//             ),
//             // Tab 1: All Balances
//             _AllBalancesTab(
//               netBalances: netBalances,
//               currentUserId: _currentUserId,
//               currentUserName: _currentUserName,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── SLIVER HEADER ──────────────────────────────────────────

//   Widget _buildSliverHeader(
//     double myNet,
//     List<Settlement> settlements,
//     Map<String, _BalanceMeta> netBalances,
//   ) {
//     final isOwed = myNet > 0.01;
//     final isOwing = myNet < -0.01;
//     final isSettled = !isOwed && !isOwing;

//     return SliverAppBar(
//       expandedHeight: 280,
//       pinned: true,
//       backgroundColor: AppColors.primary,
//       foregroundColor: Colors.white,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new_rounded),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: Text(
//         widget.group.name,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 18,
//           color: Colors.white,
//         ),
//       ),
//       bottom: TabBar(
//         controller: _tabCtrl,
//         indicatorColor: Colors.white,
//         indicatorWeight: 3,
//         labelColor: Colors.white,
//         unselectedLabelColor: Colors.white60,
//         labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//         tabs: const [
//           Tab(text: 'Settlements'),
//           Tab(text: 'All Balances'),
//         ],
//       ),
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [Color(0xFF1A237E), Color(0xFF1565C0), Color(0xFF1976D2)],
//             ),
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // My balance pill
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(50),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.3),
//                         width: 1,
//                       ),
//                     ),
//                     child: Text(
//                       isSettled
//                           ? '✅  You\'re all settled up!'
//                           : isOwed
//                           ? '📈  Overall you are owed'
//                           : '📉  Overall you owe',
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   if (!isSettled)
//                     Text(
//                       '₹${myNet.abs().toStringAsFixed(2)}',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 48,
//                         fontWeight: FontWeight.w900,
//                         letterSpacing: -2,
//                         shadows: [
//                           Shadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                     ),

//                   // Quick stats row
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _statChip(
//                         Icons.people_rounded,
//                         '${widget.group.members.length} members',
//                       ),
//                       const SizedBox(width: 12),
//                       _statChip(
//                         Icons.swap_horiz_rounded,
//                         '${settlements.length} to settle',
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _statChip(IconData icon, String label) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//     decoration: BoxDecoration(
//       color: Colors.white.withOpacity(0.12),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 14, color: Colors.white70),
//         const SizedBox(width: 5),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white70,
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     ),
//   );

//   // ── SETTLE HANDLER ─────────────────────────────────────────

//   Future<void> _handleSettle(Settlement settlement) async {
//     final confirmed = await showModalBottomSheet<bool>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _SettleConfirmSheet(
//         settlement: settlement,
//         currentUserId: _currentUserId,
//       ),
//     );

//     if (confirmed == true && mounted) {
//       // TODO: call SettlementProvider.recordSettlement()
//       // For now show success snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(
//                 Icons.check_circle_rounded,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Settlement recorded: ₹${settlement.amount.toStringAsFixed(2)}',
//               ),
//             ],
//           ),
//           backgroundColor: Colors.green.shade600,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           margin: const EdgeInsets.all(16),
//         ),
//       );

//       // Refresh after settle
//       if (mounted) {
//         context.read<ExpenseProvider>().loadExpenses(widget.group.id);
//       }
//     }
//   }
// }

// // ─────────────────────────────────────────────────────────────────
// // TAB 1: SUGGESTED SETTLEMENTS
// // ─────────────────────────────────────────────────────────────────

// class _SettlementsTab extends StatelessWidget {
//   final List<Settlement> settlements;
//   final String currentUserId;
//   final String currentUserName;
//   final Group group;
//   final Future<void> Function(Settlement) onSettle;

//   const _SettlementsTab({
//     required this.settlements,
//     required this.currentUserId,
//     required this.currentUserName,
//     required this.group,
//     required this.onSettle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (settlements.isEmpty) {
//       return _buildAllSettled();
//     }

//     // Separate: my settlements vs others
//     final mySettlements = settlements
//         .where(
//           (s) => s.fromUserId == currentUserId || s.toUserId == currentUserId,
//         )
//         .toList();
//     final otherSettlements = settlements
//         .where(
//           (s) => s.fromUserId != currentUserId && s.toUserId != currentUserId,
//         )
//         .toList();

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         if (mySettlements.isNotEmpty) ...[
//           _sectionLabel('Your Settlements'),
//           const SizedBox(height: 10),
//           ...mySettlements.map(
//             (s) => _SettlementCard(
//               settlement: s,
//               currentUserId: currentUserId,
//               currentUserName: currentUserName,
//               onSettle: onSettle,
//               isMySettlement: true,
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//         if (otherSettlements.isNotEmpty) ...[
//           _sectionLabel('Other Members'),
//           const SizedBox(height: 10),
//           ...otherSettlements.map(
//             (s) => _SettlementCard(
//               settlement: s,
//               currentUserId: currentUserId,
//               currentUserName: currentUserName,
//               onSettle: onSettle,
//               isMySettlement: false,
//             ),
//           ),
//         ],
//         const SizedBox(height: 80),
//       ],
//     );
//   }

//   Widget _sectionLabel(String text) => Text(
//     text,
//     style: const TextStyle(
//       fontSize: 13,
//       fontWeight: FontWeight.w700,
//       color: Color(0xFF607D8B),
//       letterSpacing: 0.8,
//     ),
//   );

//   Widget _buildAllSettled() => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           width: 90,
//           height: 90,
//           decoration: BoxDecoration(
//             color: Colors.green.shade50,
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             Icons.check_circle_rounded,
//             size: 50,
//             color: Colors.green.shade400,
//           ),
//         ),
//         const SizedBox(height: 20),
//         const Text(
//           'All settled up! 🎉',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1A237E),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Everyone in ${group.name} is even.',
//           style: const TextStyle(fontSize: 14, color: Colors.grey),
//         ),
//       ],
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────
// // SETTLEMENT CARD
// // ─────────────────────────────────────────────────────────────────

// class _SettlementCard extends StatelessWidget {
//   final Settlement settlement;
//   final String currentUserId;
//   final String currentUserName;
//   final Future<void> Function(Settlement) onSettle;
//   final bool isMySettlement;

//   const _SettlementCard({
//     required this.settlement,
//     required this.currentUserId,
//     required this.currentUserName,
//     required this.onSettle,
//     required this.isMySettlement,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final iOwe = settlement.fromUserId == currentUserId;
//     final theyOweMe = settlement.toUserId == currentUserId;

//     final fromName = settlement.fromUserId == currentUserId
//         ? 'You'
//         : settlement.fromName;
//     final toName = settlement.toUserId == currentUserId
//         ? 'You'
//         : settlement.toName;

//     final Color accentColor = iOwe
//         ? Colors.red.shade600
//         : Colors.green.shade600;
//     final Color bgColor = iOwe ? Colors.red.shade50 : Colors.green.shade50;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: isMySettlement
//             ? Border.all(color: accentColor.withOpacity(0.3), width: 1.5)
//             : null,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // FROM → TO row
//             Row(
//               children: [
//                 // From avatar
//                 _Avatar(
//                   name: fromName,
//                   color: iOwe ? Colors.red.shade400 : Colors.orange.shade400,
//                 ),
//                 const SizedBox(width: 10),

//                 // Arrow + amount
//                 Expanded(
//                   child: Column(
//                     children: [
//                       Text(
//                         '₹${settlement.amount.toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w900,
//                           color: isMySettlement
//                               ? accentColor
//                               : Colors.grey.shade700,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height: 2,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: isMySettlement
//                                       ? [
//                                           accentColor.withOpacity(0.3),
//                                           accentColor,
//                                         ]
//                                       : [
//                                           Colors.grey.shade200,
//                                           Colors.grey.shade400,
//                                         ],
//                                 ),
//                                 borderRadius: BorderRadius.circular(1),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 6),
//                             child: Icon(
//                               Icons.arrow_forward_rounded,
//                               size: 16,
//                               color: isMySettlement
//                                   ? accentColor
//                                   : Colors.grey.shade500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(width: 10),
//                 // To avatar
//                 _Avatar(
//                   name: toName,
//                   color: theyOweMe ? Colors.green.shade500 : AppColors.primary,
//                 ),
//               ],
//             ),

//             // Names row
//             Row(
//               children: [
//                 SizedBox(
//                   width: 44,
//                   child: Text(
//                     fromName,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: iOwe ? accentColor : Colors.grey.shade600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const Spacer(),
//                 SizedBox(
//                   width: 44,
//                   child: Text(
//                     toName,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: theyOweMe ? accentColor : Colors.grey.shade600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),

//             // Settle button — only show for MY settlements
//             if (isMySettlement) ...[
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: () => onSettle(settlement),
//                   icon: const Icon(Icons.check_rounded, size: 18),
//                   label: Text(
//                     iOwe
//                         ? 'I\'ve paid ${settlement.toName}'
//                         : '${settlement.fromName} paid me',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 13,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: accentColor,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────
// // TAB 2: ALL BALANCES
// // ─────────────────────────────────────────────────────────────────

// class _AllBalancesTab extends StatelessWidget {
//   final Map<String, _BalanceMeta> netBalances;
//   final String currentUserId;
//   final String currentUserName;

//   const _AllBalancesTab({
//     required this.netBalances,
//     required this.currentUserId,
//     required this.currentUserName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (netBalances.isEmpty) {
//       return const Center(
//         child: Text(
//           'No expenses yet.',
//           style: TextStyle(color: Colors.grey, fontSize: 16),
//         ),
//       );
//     }

//     // Sort: current user first, then by abs(net) desc
//     final sorted = netBalances.values.toList()
//       ..sort((a, b) {
//         if (a.userId == currentUserId) return -1;
//         if (b.userId == currentUserId) return 1;
//         return b.net.abs().compareTo(a.net.abs());
//       });

//     // Total group spend
//     final totalSpend = netBalances.values
//         .where((b) => b.net > 0)
//         .fold(0.0, (s, b) => s + b.net);

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         // Total spend card
//         _TotalSpendCard(totalSpend: totalSpend),
//         const SizedBox(height: 20),

//         const Text(
//           'NET BALANCES',
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF607D8B),
//             letterSpacing: 1.2,
//           ),
//         ),
//         const SizedBox(height: 10),

//         ...sorted.map(
//           (b) => _BalanceRow(
//             meta: b,
//             isCurrentUser: b.userId == currentUserId,
//             currentUserName: currentUserName,
//             totalSpend: totalSpend,
//           ),
//         ),
//         const SizedBox(height: 80),
//       ],
//     );
//   }
// }

// class _TotalSpendCard extends StatelessWidget {
//   final double totalSpend;
//   const _TotalSpendCard({required this.totalSpend});

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.all(20),
//     decoration: BoxDecoration(
//       gradient: const LinearGradient(
//         colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(20),
//     ),
//     child: Row(
//       children: [
//         const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 36),
//         const SizedBox(width: 16),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Total Group Spend',
//               style: TextStyle(color: Colors.white70, fontSize: 13),
//             ),
//             Text(
//               '₹${totalSpend.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: -1,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// class _BalanceRow extends StatelessWidget {
//   final _BalanceMeta meta;
//   final bool isCurrentUser;
//   final String currentUserName;
//   final double totalSpend;

//   const _BalanceRow({
//     required this.meta,
//     required this.isCurrentUser,
//     required this.currentUserName,
//     required this.totalSpend,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isOwed = meta.net > 0.01;
//     final isOwing = meta.net < -0.01;
//     final isEven = !isOwed && !isOwing;

//     final color = isOwed
//         ? Colors.green.shade600
//         : isOwing
//         ? Colors.red.shade600
//         : Colors.grey.shade500;

//     final displayName = isCurrentUser
//         ? '$currentUserName (You)'
//         : meta.name.isNotEmpty
//         ? meta.name
//         : meta.userId;

//     // Progress bar width — proportion of total spend
//     final proportion = totalSpend > 0
//         ? (meta.net.abs() / totalSpend).clamp(0.0, 1.0)
//         : 0.0;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: isCurrentUser
//             ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
//             : null,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               _Avatar(
//                 name: isCurrentUser
//                     ? 'Y'
//                     : (meta.name.isNotEmpty ? meta.name : '?'),
//                 color: isCurrentUser
//                     ? AppColors.primary
//                     : Colors.blueGrey.shade400,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       displayName,
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: isCurrentUser
//                             ? FontWeight.w800
//                             : FontWeight.w600,
//                         color: const Color(0xFF1A1A2E),
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Text(
//                       isEven
//                           ? 'Settled up'
//                           : isOwed
//                           ? 'Gets back'
//                           : 'Owes',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: color,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Text(
//                 isEven
//                     ? '₹0'
//                     : '${isOwed ? '+' : '-'}₹${meta.net.abs().toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w800,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           if (!isEven) ...[
//             const SizedBox(height: 10),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: proportion,
//                 minHeight: 5,
//                 backgroundColor: color.withOpacity(0.1),
//                 valueColor: AlwaysStoppedAnimation<Color>(color),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────
// // SETTLE CONFIRM BOTTOM SHEET
// // ─────────────────────────────────────────────────────────────────

// class _SettleConfirmSheet extends StatelessWidget {
//   final Settlement settlement;
//   final String currentUserId;

//   const _SettleConfirmSheet({
//     required this.settlement,
//     required this.currentUserId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final iOwe = settlement.fromUserId == currentUserId;
//     final accentColor = iOwe ? Colors.red.shade600 : Colors.green.shade600;

//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//       ),
//       padding: EdgeInsets.fromLTRB(
//         24,
//         16,
//         24,
//         MediaQuery.of(context).viewInsets.bottom + 32,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Handle
//           Container(
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Amount display
//           Container(
//             width: 90,
//             height: 90,
//             decoration: BoxDecoration(
//               color: accentColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 '₹${settlement.amount.toStringAsFixed(0)}',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w900,
//                   color: accentColor,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           Text(
//             iOwe
//                 ? 'Confirm you paid ${settlement.toName}'
//                 : 'Confirm ${settlement.fromName} paid you',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1A1A2E),
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             iOwe
//                 ? 'This will mark ₹${settlement.amount.toStringAsFixed(2)} as paid to ${settlement.toName}'
//                 : '${settlement.fromName} paid you ₹${settlement.amount.toStringAsFixed(2)}',
//             style: const TextStyle(color: Colors.grey, fontSize: 14),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 28),

//           // Confirm button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: accentColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: const Text(
//                 'Confirm Settlement',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Cancel
//           SizedBox(
//             width: double.infinity,
//             child: TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.grey, fontSize: 15),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────
// // SHARED AVATAR WIDGET
// // ─────────────────────────────────────────────────────────────────

// class _Avatar extends StatelessWidget {
//   final String name;
//   final Color color;

//   const _Avatar({required this.name, required this.color});

//   @override
//   Widget build(BuildContext context) => CircleAvatar(
//     radius: 22,
//     backgroundColor: color.withOpacity(0.15),
//     child: Text(
//       name.isNotEmpty ? name[0].toUpperCase() : '?',
//       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
//     ),
//   );
// }

// ════════════════════════════════════════════════════════════════
// FILE: lib/features/group_detail/group_balances_screen.dart
// ════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/data/models/expense_model.dart';
import 'package:splitzon/data/models/member_model.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';

// ─────────────────────────────────────────────────────────────────
// SETTLEMENT MODEL
// ─────────────────────────────────────────────────────────────────

class Settlement {
  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final double amount;

  const Settlement({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
  });
}

// ─────────────────────────────────────────────────────────────────
// BALANCE ENGINE — Splitwise-style debt simplification
// ─────────────────────────────────────────────────────────────────

class BalanceEngine {
  /// Compute net balance for every member from expenses.
  /// net > 0 → they are owed money
  /// net < 0 → they owe money
  static Map<String, _BalanceMeta> computeNetBalances(
    List<Expense> expenses,
    List<Member> groupMembers,
  ) {
    final Map<String, _BalanceMeta> net = {};

    // Pre-populate all group members so even non-participants show up
    for (final m in groupMembers) {
      net[m.id] = _BalanceMeta(userId: m.id, name: m.name, net: 0);
    }

    for (final expense in expenses) {
      final payer = expense.paidByUserId;
      if (payer.isEmpty) continue;

      // Payer gets credited
      net.putIfAbsent(
        payer,
        () => _BalanceMeta(userId: payer, name: expense.paidByName, net: 0),
      );
      net[payer]!.net += expense.amount;

      // Each involved member gets debited their share
      for (final share in expense.memberShares) {
        if (!share.isInvolved || share.shareAmount <= 0) continue;
        final uid = share.userId;
        net.putIfAbsent(
          uid,
          () => _BalanceMeta(userId: uid, name: share.name, net: 0),
        );
        net[uid]!.net -= share.shareAmount;
        // Update name if empty
        if (net[uid]!.name.isEmpty && share.name.isNotEmpty) {
          net[uid]!.name = share.name;
        }
      }
    }

    return net;
  }

  /// Simplify debts — minimum number of transactions.
  /// Uses greedy creditor/debtor matching (same as Splitwise).
  static List<Settlement> simplifyDebts(Map<String, _BalanceMeta> netBalances) {
    final settlements = <Settlement>[];

    // Separate into creditors (net > 0) and debtors (net < 0)
    final creditors =
        netBalances.values
            .where((b) => b.net > 0.01)
            .map(
              (b) => _MutableBalance(
                userId: b.userId,
                name: b.name,
                amount: b.net,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount)); // largest first

    final debtors =
        netBalances.values
            .where((b) => b.net < -0.01)
            .map(
              (b) => _MutableBalance(
                userId: b.userId,
                name: b.name,
                amount: b.net.abs(),
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount)); // largest first

    int ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final creditor = creditors[ci];
      final debtor = debtors[di];

      final settled = math.min(creditor.amount, debtor.amount);
      if (settled > 0.01) {
        settlements.add(
          Settlement(
            fromUserId: debtor.userId,
            fromName: debtor.name,
            toUserId: creditor.userId,
            toName: creditor.name,
            amount: double.parse(settled.toStringAsFixed(2)),
          ),
        );
      }

      creditor.amount -= settled;
      debtor.amount -= settled;

      if (creditor.amount < 0.01) ci++;
      if (debtor.amount < 0.01) di++;
    }

    return settlements;
  }
}

class _BalanceMeta {
  final String userId;
  String name;
  double net;
  _BalanceMeta({required this.userId, required this.name, required this.net});
}

class _MutableBalance {
  final String userId;
  final String name;
  double amount;
  _MutableBalance({
    required this.userId,
    required this.name,
    required this.amount,
  });
}

// ─────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────

class GroupBalancesScreen extends StatefulWidget {
  final Group group;

  const GroupBalancesScreen({super.key, required this.group});

  @override
  State<GroupBalancesScreen> createState() => _GroupBalancesScreenState();
}

class _GroupBalancesScreenState extends State<GroupBalancesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _currentUserId = '';
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProviders>().user;
    _currentUserId = user?.id ?? '';
    _currentUserName = user?.name ?? 'You';
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().getExpenses(
      widget.group.id,
    );

    final netBalances = BalanceEngine.computeNetBalances(
      expenses,
      widget.group.members,
    );

    final settlements = BalanceEngine.simplifyDebts(netBalances);

    // My personal balance summary
    final myNet = netBalances[_currentUserId]?.net ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          _buildSliverHeader(myNet, settlements, netBalances),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Tab 0: Suggested Settlements
            _SettlementsTab(
              settlements: settlements,
              currentUserId: _currentUserId,
              currentUserName: _currentUserName,
              group: widget.group,
              onSettle: _handleSettle,
            ),
            // Tab 1: All Balances
            _AllBalancesTab(
              netBalances: netBalances,
              currentUserId: _currentUserId,
              currentUserName: _currentUserName,
            ),
          ],
        ),
      ),
    );
  }

  // ── SLIVER HEADER ──────────────────────────────────────────

  Widget _buildSliverHeader(
    double myNet,
    List<Settlement> settlements,
    Map<String, _BalanceMeta> netBalances,
  ) {
    final isOwed = myNet > 0.01;
    final isOwing = myNet < -0.01;
    final isSettled = !isOwed && !isOwing;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.group.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      bottom: TabBar(
        controller: _tabCtrl,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Settlements'),
          Tab(text: 'All Balances'),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // My balance pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSettled
                          ? '✅  You\'re all settled up!'
                          : isOwed
                          ? '📈  Overall you are owed'
                          : '📉  Overall you owe',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isSettled)
                    Text(
                      '₹${myNet.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                  // Quick stats row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statChip(
                        Icons.people_rounded,
                        '${widget.group.members.length} members',
                      ),
                      const SizedBox(width: 12),
                      _statChip(
                        Icons.swap_horiz_rounded,
                        '${settlements.length} to settle',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  // ── SETTLE HANDLER ─────────────────────────────────────────

  Future<void> _handleSettle(Settlement settlement) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettleConfirmSheet(
        settlement: settlement,
        currentUserId: _currentUserId,
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: call SettlementProvider.recordSettlement()
      // For now show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Settlement recorded: ₹${settlement.amount.toStringAsFixed(2)}',
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Refresh after settle
      if (mounted) {
        context.read<ExpenseProvider>().loadExpenses(widget.group.id);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// TAB 1: SUGGESTED SETTLEMENTS
// ─────────────────────────────────────────────────────────────────

class _SettlementsTab extends StatelessWidget {
  final List<Settlement> settlements;
  final String currentUserId;
  final String currentUserName;
  final Group group;
  final Future<void> Function(Settlement) onSettle;

  const _SettlementsTab({
    required this.settlements,
    required this.currentUserId,
    required this.currentUserName,
    required this.group,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    if (settlements.isEmpty) {
      return _buildAllSettled();
    }

    // Separate: my settlements vs others
    final mySettlements = settlements
        .where(
          (s) => s.fromUserId == currentUserId || s.toUserId == currentUserId,
        )
        .toList();
    final otherSettlements = settlements
        .where(
          (s) => s.fromUserId != currentUserId && s.toUserId != currentUserId,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (mySettlements.isNotEmpty) ...[
          _sectionLabel('Your Settlements'),
          const SizedBox(height: 10),
          ...mySettlements.map(
            (s) => _SettlementCard(
              settlement: s,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              onSettle: onSettle,
              isMySettlement: true,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (otherSettlements.isNotEmpty) ...[
          _sectionLabel('Other Members'),
          const SizedBox(height: 10),
          ...otherSettlements.map(
            (s) => _SettlementCard(
              settlement: s,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              onSettle: onSettle,
              isMySettlement: false,
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Color(0xFF607D8B),
      letterSpacing: 0.8,
    ),
  );

  Widget _buildAllSettled() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 50,
            color: Colors.green.shade400,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'All settled up! 🎉',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everyone in ${group.name} is even.',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// SETTLEMENT CARD
// ─────────────────────────────────────────────────────────────────

class _SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final String currentUserId;
  final String currentUserName;
  final Future<void> Function(Settlement) onSettle;
  final bool isMySettlement;

  const _SettlementCard({
    required this.settlement,
    required this.currentUserId,
    required this.currentUserName,
    required this.onSettle,
    required this.isMySettlement,
  });

  @override
  Widget build(BuildContext context) {
    final iOwe = settlement.fromUserId == currentUserId;
    final theyOweMe = settlement.toUserId == currentUserId;

    final fromName = settlement.fromUserId == currentUserId
        ? 'You'
        : settlement.fromName;
    final toName = settlement.toUserId == currentUserId
        ? 'You'
        : settlement.toName;

    final Color accentColor = iOwe
        ? Colors.red.shade600
        : Colors.green.shade600;
    final Color bgColor = iOwe ? Colors.red.shade50 : Colors.green.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isMySettlement
            ? Border.all(color: accentColor.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FROM → TO row
            Row(
              children: [
                // From avatar
                _Avatar(
                  name: fromName,
                  color: iOwe ? Colors.red.shade400 : Colors.orange.shade400,
                ),
                const SizedBox(width: 10),

                // Arrow + amount
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '₹${settlement.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isMySettlement
                              ? accentColor
                              : Colors.grey.shade700,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMySettlement
                                      ? [
                                          accentColor.withOpacity(0.3),
                                          accentColor,
                                        ]
                                      : [
                                          Colors.grey.shade200,
                                          Colors.grey.shade400,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: isMySettlement
                                  ? accentColor
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                // To avatar
                _Avatar(
                  name: toName,
                  color: theyOweMe ? Colors.green.shade500 : AppColors.primary,
                ),
              ],
            ),

            // Names row
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    fromName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: iOwe ? accentColor : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 44,
                  child: Text(
                    toName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theyOweMe ? accentColor : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Settle button — only show for MY settlements
            if (isMySettlement) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onSettle(settlement),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    iOwe
                        ? 'I\'ve paid ${settlement.toName}'
                        : '${settlement.fromName} paid me',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TAB 2: ALL BALANCES
// ─────────────────────────────────────────────────────────────────

class _AllBalancesTab extends StatelessWidget {
  final Map<String, _BalanceMeta> netBalances;
  final String currentUserId;
  final String currentUserName;

  const _AllBalancesTab({
    required this.netBalances,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    if (netBalances.isEmpty) {
      return const Center(
        child: Text(
          'No expenses yet.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Sort: current user first, then by abs(net) desc
    final sorted = netBalances.values.toList()
      ..sort((a, b) {
        if (a.userId == currentUserId) return -1;
        if (b.userId == currentUserId) return 1;
        return b.net.abs().compareTo(a.net.abs());
      });

    // Total group spend
    final totalSpend = netBalances.values
        .where((b) => b.net > 0)
        .fold(0.0, (s, b) => s + b.net);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total spend card
        _TotalSpendCard(totalSpend: totalSpend),
        const SizedBox(height: 20),

        const Text(
          'NET BALANCES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF607D8B),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        ...sorted.map(
          (b) => _BalanceRow(
            meta: b,
            isCurrentUser: b.userId == currentUserId,
            currentUserName: currentUserName,
            totalSpend: totalSpend,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TotalSpendCard extends StatelessWidget {
  final double totalSpend;
  const _TotalSpendCard({required this.totalSpend});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 36),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Group Spend',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              '₹${totalSpend.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BalanceRow extends StatelessWidget {
  final _BalanceMeta meta;
  final bool isCurrentUser;
  final String currentUserName;
  final double totalSpend;

  const _BalanceRow({
    required this.meta,
    required this.isCurrentUser,
    required this.currentUserName,
    required this.totalSpend,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = meta.net > 0.01;
    final isOwing = meta.net < -0.01;
    final isEven = !isOwed && !isOwing;

    final color = isOwed
        ? Colors.green.shade600
        : isOwing
        ? Colors.red.shade600
        : Colors.grey.shade500;

    final displayName = isCurrentUser
        ? '$currentUserName (You)'
        : meta.name.isNotEmpty
        ? meta.name
        : meta.userId;

    // Progress bar width — proportion of total spend
    final proportion = totalSpend > 0
        ? (meta.net.abs() / totalSpend).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                name: isCurrentUser
                    ? 'Y'
                    : (meta.name.isNotEmpty ? meta.name : '?'),
                color: isCurrentUser
                    ? AppColors.primary
                    : Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrentUser
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isEven
                          ? 'Settled up'
                          : isOwed
                          ? 'Gets back'
                          : 'Owes',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isEven
                    ? '₹0'
                    : '${isOwed ? '+' : '-'}₹${meta.net.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (!isEven) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: proportion,
                minHeight: 5,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SETTLE CONFIRM BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────

class _SettleConfirmSheet extends StatelessWidget {
  final Settlement settlement;
  final String currentUserId;

  const _SettleConfirmSheet({
    required this.settlement,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final iOwe = settlement.fromUserId == currentUserId;
    final accentColor = iOwe ? Colors.red.shade600 : Colors.green.shade600;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Amount display
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '₹${settlement.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            iOwe
                ? 'Confirm you paid ${settlement.toName}'
                : 'Confirm ${settlement.fromName} paid you',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            iOwe
                ? 'This will mark ₹${settlement.amount.toStringAsFixed(2)} as paid to ${settlement.toName}'
                : '${settlement.fromName} paid you ₹${settlement.amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Confirm Settlement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED AVATAR WIDGET
// ─────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;

  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 22,
    backgroundColor: color.withOpacity(0.15),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
    ),
  );
}
