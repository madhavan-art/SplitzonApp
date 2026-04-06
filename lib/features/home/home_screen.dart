// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/core/utils/background_main_theme.dart';
// import 'package:splitzon/features/home/balance_card.dart';

// // ─────────────────────────────────────────
// // MODELS
// // ─────────────────────────────────────────

// class PersonModel {
//   final String id;
//   final String name;
//   final String phone;
//   final String avatar;
//   final String email;

//   PersonModel({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.avatar,
//     required this.email,
//   });

//   factory PersonModel.fromJson(Map<String, dynamic> json) {
//     return PersonModel(
//       id: json['id'],
//       name: json['name'],
//       phone: json['phone'],
//       avatar: json['avatar'],
//       email: json['email'],
//     );
//   }
// }

// class GroupModel {
//   final String id;
//   final String title;
//   final String subtitle;
//   final String amount;
//   final bool isPositive;
//   final String date;
//   final String coverImage;
//   final List<String> memberIds;

//   GroupModel({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.amount,
//     required this.isPositive,
//     required this.date,
//     required this.coverImage,
//     required this.memberIds,
//   });

//   factory GroupModel.fromJson(Map<String, dynamic> json) {
//     return GroupModel(
//       id: json['id'],
//       title: json['title'],
//       subtitle: json['subtitle'],
//       amount: json['amount'],
//       isPositive: json['isPositive'],
//       date: json['date'],
//       coverImage: json['coverImage'],
//       memberIds: List<String>.from(json['memberIds']),
//     );
//   }
// }

// // ─────────────────────────────────────────
// // DASHBOARD SCREEN
// // ─────────────────────────────────────────

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   // ✅ ALL variables declared at the very top of the class
//   Map<String, dynamic>? userData;
//   List<GroupModel> groups = [];
//   Map<String, PersonModel> peopleMap = {};
//   bool isLoading = true;
//   static const int _initialCount = 5; // ✅ controls how many shown by default
//   bool _showAll = false; // ✅ toggles see more / see less

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments;
//     if (args != null && args is Map<String, dynamic>) {
//       setState(() => userData = args);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     try {
//       final peopleJson = await rootBundle.loadString('datas/people.json');
//       final people = (jsonDecode(peopleJson) as List)
//           .map((e) => PersonModel.fromJson(e))
//           .toList();

//       final groupsJson = await rootBundle.loadString('datas/groups.json');
//       final loadedGroups = (jsonDecode(groupsJson) as List)
//           .map((e) => GroupModel.fromJson(e))
//           .toList();

//       setState(() {
//         peopleMap = {for (var p in people) p.id: p};
//         groups = loadedGroups;
//         isLoading = false;
//         debugPrint("✅ Groups loaded: ${groups.length}");
//       });
//     } catch (e) {
//       debugPrint("❌ Error loading JSON: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Slice groups based on _showAll flag
//     final visibleGroups = _showAll
//         ? groups
//         : groups.take(_initialCount).toList();

//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         onPressed: () {},
//         child: const Icon(Icons.add),
//       ),
//       bottomNavigationBar: const DashboardBottomBar(),
//       body: BackgroundMainTheme(
//         child: SafeArea(
//           child: Column(
//             // ✅ Column instead of just ScrollView
//             children: [
//               // ✅ FIXED HEADER — stays on top always
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(.85),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: const Icon(Icons.menu, color: AppColors.primary),
//                     ),
//                     CircleAvatar(
//                       radius: 18,
//                       backgroundColor: AppColors.primary.withOpacity(.15),
//                       child: const Icon(Icons.person, color: AppColors.primary),
//                     ),
//                   ],
//                 ),
//               ),

//               // ✅ SCROLLABLE CONTENT below fixed header
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 20),

//                       Text(
//                         "Hi, ${userData?['name'] ?? 'User'}",
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                       Text(
//                         "Let's review your expenses",
//                         style: TextStyle(color: AppColors.textSecondary),
//                       ),

//                       const SizedBox(height: 20),

//                       /// BALANCE CARD
//                       const BalanceCard(),

//                       const SizedBox(height: 25),

//                       /// QUICK ACTIONS
//                       const Text(
//                         "Quick insights",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: AppColors.primary,
//                         ),
//                       ),

//                       const SizedBox(height: 15),

//                       const QuickActions(),

//                       const SizedBox(height: 25),

//                       /// GROUPS HEADER — untouched as requested
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Groups",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: AppColors.primary,
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Text(
//                                 "See More",
//                                 style: TextStyle(
//                                   color: AppColors.primary.withOpacity(.8),
//                                 ),
//                               ),
//                               Icon(
//                                 Icons.arrow_forward_ios_rounded,
//                                 color: AppColors.primary.withOpacity(.8),
//                                 size: 18,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 15),

//                       /// ✅ DYNAMIC GROUP LIST — shows _initialCount or all
//                       if (isLoading)
//                         const Center(child: CircularProgressIndicator())
//                       else
//                         ...visibleGroups.map((group) {
//                           final memberAvatars = group.memberIds
//                               .where((id) => peopleMap.containsKey(id))
//                               .map((id) => peopleMap[id]!.avatar)
//                               .toList();

//                           return GroupCard(
//                             title: group.title,
//                             subtitle: group.subtitle,
//                             amount: group.amount,
//                             color: group.isPositive ? Colors.green : Colors.red,
//                             date: group.date,
//                             coverImage: group.coverImage,
//                             memberAvatars: memberAvatars,
//                           );
//                         }),

//                       const SizedBox(height: 10),

//                       /// ✅ SEE MORE / SEE LESS BUTTON AT BOTTOM
//                       if (!isLoading)
//                         Center(
//                           child: OutlinedButton.icon(
//                             // ✅ disabled when total groups is 5 or less
//                             onPressed: groups.length <= _initialCount
//                                 ? null
//                                 : () => setState(() => _showAll = !_showAll),
//                             icon: Icon(
//                               _showAll
//                                   ? Icons.keyboard_arrow_up_rounded
//                                   : Icons.keyboard_arrow_down_rounded,
//                             ),
//                             label: Text(_showAll ? "See Less" : "See More"),
//                             style: OutlinedButton.styleFrom(
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 10,
//                               ),
//                             ),
//                           ),
//                         ),

//                       const SizedBox(height: 120),
//                     ],
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

// // ─────────────────────────────────────────
// // BOTTOM BAR
// // ─────────────────────────────────────────

// // ─────────────────────────────────────────
// // QUICK ACTIONS
// // ─────────────────────────────────────────

// class QuickActions extends StatelessWidget {
//   const QuickActions({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: const [
//         ActionItem(
//           icon: Icons.person_add,
//           label: "New Group",
//           color: Colors.green,
//         ),
//         ActionItem(
//           icon: Icons.analytics_rounded,
//           label: "Analytics",
//           color: Colors.orange,
//         ),
//         ActionItem(
//           icon: Icons.history_rounded,
//           label: "Activity",
//           color: Colors.blue,
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────
// // ACTION ITEM
// // ─────────────────────────────────────────

// class ActionItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;

//   const ActionItem({
//     super.key,
//     required this.icon,
//     required this.label,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 110,
//       width: 100,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.7),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 6,
//             spreadRadius: 1,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: color.withOpacity(.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: AppColors.textPrimary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────
// // GROUP CARD
// // ─────────────────────────────────────────

// class GroupCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final String amount;
//   final Color color;
//   final String date;
//   final String coverImage;
//   final List<String> memberAvatars;

//   const GroupCard({
//     super.key,
//     required this.title,
//     required this.subtitle,
//     required this.amount,
//     required this.color,
//     required this.date,
//     required this.coverImage,
//     required this.memberAvatars,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(.85),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             spreadRadius: 0,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: Container(
//               width: 90,
//               height: 100,
//               color: Colors.grey.shade100,
//               child: Image.network(
//                 coverImage,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Icon(
//                   Icons.image_outlined,
//                   color: Colors.grey.shade300,
//                   size: 32,
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(width: 16),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.textPrimary,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                     Text(
//                       amount,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: color,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 0.3,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 6),

//                 Text(
//                   subtitle,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: AppColors.textSecondary,
//                     height: 1.5,
//                   ),
//                 ),

//                 const SizedBox(height: 14),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       height: 28,
//                       width: memberAvatars.length > 3
//                           ? 70
//                           : (memberAvatars.length * 20.0 + 8),
//                       child: Stack(
//                         children: List.generate(
//                           memberAvatars.length > 3 ? 3 : memberAvatars.length,
//                           (index) => Positioned(
//                             left: index * 18.0,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.white,
//                                   width: 2,
//                                 ),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.08),
//                                     blurRadius: 4,
//                                     offset: const Offset(0, 1),
//                                   ),
//                                 ],
//                               ),
//                               child: CircleAvatar(
//                                 radius: 12,
//                                 backgroundImage: NetworkImage(
//                                   memberAvatars[index],
//                                 ),
//                                 backgroundColor: Colors.grey.shade200,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       date,
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: AppColors.textSecondary,
//                         fontWeight: FontWeight.w400,
//                         letterSpacing: 0.3,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DashboardBottomBar extends StatefulWidget {
//   const DashboardBottomBar({super.key});

//   @override
//   State<DashboardBottomBar> createState() => _DashboardBottomBarState();
// }

// class _DashboardBottomBarState extends State<DashboardBottomBar> {
//   int _currentIndex = 0;

//   final List<_NavItem> _items = const [
//     _NavItem(
//       icon: Icons.home_outlined,
//       activeIcon: Icons.home_rounded,
//       label: "Home",
//     ),
//     _NavItem(
//       icon: Icons.people_outline,
//       activeIcon: Icons.people_rounded,
//       label: "Friends",
//     ),
//     _NavItem(
//       icon: Icons.bar_chart_outlined,
//       activeIcon: Icons.bar_chart_rounded,
//       label: "Activity",
//     ),
//     _NavItem(
//       icon: Icons.person_outline,
//       activeIcon: Icons.person_rounded,
//       label: "Profile",
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 24), // ✅ floating effect
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(
//           color: AppColors.primary.withOpacity(.2),
//           width: 1.2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primary.withOpacity(.08),
//             blurRadius: 20,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: List.generate(_items.length, (index) {
//           final item = _items[index];
//           final isActive = _currentIndex == index;

//           return GestureDetector(
//             onTap: () => setState(() => _currentIndex = index),
//             behavior: HitTestBehavior.opaque,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: isActive
//                     ? AppColors.primary.withOpacity(.1)
//                     : Colors.transparent,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     isActive ? item.activeIcon : item.icon,
//                     color: isActive ? AppColors.primary : Colors.grey.shade500,
//                     size: 24,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     item.label,
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//                       color: isActive
//                           ? AppColors.primary
//                           : Colors.grey.shade500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// class _NavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//   });
// }
// ════════════════════════════════════════════════════════════════
// FILE: lib/features/home/home_screen.dart
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_main_theme.dart';
import 'package:splitzon/features/add_group/add_group_screen.dart';
import 'package:splitzon/features/home/balance_card.dart';
import 'package:splitzon/services/firebase_auth.dart';

// ─────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────

class PersonModel {
  final String id;
  final String name;
  final String phone;
  final String avatar;
  final String email;

  const PersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.email,
  });

  factory PersonModel.fromJson(Map<String, dynamic> j) => PersonModel(
    id: j['id'],
    name: j['name'],
    phone: j['phone'],
    avatar: j['avatar'],
    email: j['email'],
  );
}

class GroupModel {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;
  final String date;
  final String coverImage;
  final List<String> memberIds;

  const GroupModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.date,
    required this.coverImage,
    required this.memberIds,
  });

  factory GroupModel.fromJson(Map<String, dynamic> j) => GroupModel(
    id: j['id'],
    title: j['title'],
    subtitle: j['subtitle'],
    amount: j['amount'],
    isPositive: j['isPositive'],
    date: j['date'],
    coverImage: j['coverImage'],
    memberIds: List<String>.from(j['memberIds']),
  );
}

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
  List<GroupModel> groups = [];
  Map<String, PersonModel> peopleMap = {};
  bool isLoading = true;

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final peopleJson = await rootBundle.loadString('datas/people.json');
      final people = (jsonDecode(peopleJson) as List)
          .map((e) => PersonModel.fromJson(e))
          .toList();

      final groupsJson = await rootBundle.loadString('datas/groups.json');
      final loaded = (jsonDecode(groupsJson) as List)
          .map((e) => GroupModel.fromJson(e))
          .toList();

      setState(() {
        peopleMap = {for (var p in people) p.id: p};
        groups = loaded;
        isLoading = false;
      });
      debugPrint('✅ Groups loaded: ${groups.length}');
    } catch (e) {
      debugPrint('❌ Error loading JSON: $e');
      setState(() => isLoading = false);
    }
  }

  // ✅ Open Add Group → insert result at TOP of list
  Future<void> _openAddGroup() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddGroupScreen()),
    );

    if (result != null) {
      final newGroup = GroupModel.fromJson(result);
      setState(() {
        groups.insert(0, newGroup); // ✅ Top of list
        _showAll = false; // ✅ Scroll back so new group is visible
      });
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
                  '"${newGroup.title}" added!',
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
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final hPad = sw * 0.05;

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
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
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
                        'Hi, ${userData?['name'] ?? 'User'} 👋',
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

                      // Groups header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Groups',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (groups.length > _initialCount) {
                                setState(() => _showAll = !_showAll);
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  'See More',
                                  style: TextStyle(
                                    color: AppColors.primary.withOpacity(.8),
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.primary.withOpacity(.8),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Groups list
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (groups.isEmpty)
                        _EmptyGroups(onTap: _openAddGroup)
                      else
                        ...visibleGroups.map((g) {
                          final avatars = g.memberIds
                              .where((id) => peopleMap.containsKey(id))
                              .map((id) => peopleMap[id]!.avatar)
                              .toList();
                          return GroupCard(
                            title: g.title,
                            subtitle: g.subtitle,
                            amount: g.amount,
                            color: g.isPositive ? Colors.green : Colors.red,
                            date: g.date,
                            coverImage: g.coverImage,
                            memberAvatars: avatars,
                          );
                        }),

                      const SizedBox(height: 10),

                      // See more/less toggle
                      if (!isLoading && groups.length > _initialCount)
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
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(.4),
                              ),
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

                      const SizedBox(height: 130),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyGroups({required this.onTap});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.group_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first group',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────
// BOTTOM BAR (floating card style)
// ─────────────────────────────────────────

class DashboardBottomBar extends StatefulWidget {
  const DashboardBottomBar({super.key});

  @override
  State<DashboardBottomBar> createState() => _DashboardBottomBarState();
}

class _DashboardBottomBarState extends State<DashboardBottomBar> {
  int _idx = 0;

  static const _items = [
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
    final sw = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, 24),
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
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = _idx == i;
          return GestureDetector(
            onTap: () => setState(() => _idx = i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withOpacity(.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    color: active ? AppColors.primary : Colors.grey.shade500,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : Colors.grey.shade500,
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
          onTap: onNewGroup,
        ),
        ActionItem(
          icon: Icons.receipt,
          label: 'Add Expense',
          color: Colors.orange,
          onTap: () {},
        ),
        ActionItem(
          icon: Icons.account_balance_wallet,
          label: 'Activity',
          color: Colors.blue,
          onTap: () {},
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
  final VoidCallback onTap;

  const ActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final w = (sw - (sw * 0.1) - 40) / 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sw < 360 ? 10 : 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// GROUP CARD
// ─────────────────────────────────────────

class GroupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String date;
  final String coverImage;
  final List<String> memberAvatars;

  const GroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.date,
    required this.coverImage,
    required this.memberAvatars,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final imgW = sw < 360 ? 76.0 : 90.0;
    final imgH = sw < 360 ? 88.0 : 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: imgW,
              height: imgH,
              color: Colors.grey.shade100,
              child: Image.network(
                coverImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_outlined,
                  color: Colors.grey.shade300,
                  size: 28,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: sw < 360 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: sw < 360 ? 12 : 14,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Avatars + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (memberAvatars.isNotEmpty)
                      SizedBox(
                        height: 26,
                        width: memberAvatars.length > 3
                            ? 64
                            : memberAvatars.length * 19.0 + 4,
                        child: Stack(
                          children: List.generate(
                            memberAvatars.length > 3 ? 3 : memberAvatars.length,
                            (i) => Positioned(
                              left: i * 17.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 11,
                                  backgroundImage: NetworkImage(
                                    memberAvatars[i],
                                  ),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
