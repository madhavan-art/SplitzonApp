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
                            keyboardType: TextInputType.number,
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
                  // ✅ FIXED: was c.paidBy → now c.paidByName
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
                  _splitChip(context, 'Share', SplitType.share),
                ],
              ),

              const SizedBox(height: 14),

              // ── MEMBERS LIST ─────────────────────────────────
              Consumer<AddExpenseController>(
                builder: (ctx, ctrl, _) => Column(
                  children: ctrl.members
                      .map((m) => _memberCard(ctrl, m))
                      .toList(),
                ),
              ),

              const SizedBox(height: 26),

              // ── SAVE BUTTON ──────────────────────────────────
              Consumer<AddExpenseController>(
                builder: (ctx, ctrl, _) => GestureDetector(
                  onTap: ctrl.isSaving ? null : () => ctrl.saveExpense(ctx),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: ctrl.isSaving
                            ? [Colors.grey.shade400, Colors.grey.shade400]
                            : const [Color(0xFF4A90E2), Color(0xFF5DADE2)],
                      ),
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
                          : const Text(
                              'Save Expense',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── TYPE CHIP ──────────────────────────────────────────────
  Widget _typeChip(AddExpenseController c, String text) {
    // ✅ reads from controller so selection persists
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
    // ✅ FIXED: was c.paidBy → now c.paidByName
    final String displayName;
    if (m.name == c.paidByName || m.id == c.paidByUserId) {
      displayName = 'You';
    } else if (m.name.length > 18) {
      displayName = '${m.name.substring(0, 8)}…';
    } else {
      displayName = m.name;
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
                keyboardType: TextInputType.number,
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
                keyboardType: TextInputType.number,
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

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'add_expenses_controller.dart';

// class AddExpenseScreen extends StatelessWidget {
//   const AddExpenseScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AddExpenseController(),
//       child: const _AddExpenseView(),
//     );
//   }
// }

// class _AddExpenseView extends StatelessWidget {
//   const _AddExpenseView();

//   @override
//   Widget build(BuildContext context) {
//     final c = context.watch<AddExpenseController>();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F5F9),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Add Expense",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),

//       body: Column(
//         children: [
//           const SizedBox(height: 10),

//           /// AMOUNT
//           const Text(
//             "AMOUNT",
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey,
//               letterSpacing: 1,
//             ),
//           ),

//           const SizedBox(height: 8),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "₹",
//                 style: TextStyle(fontSize: 28, color: Colors.grey),
//               ),
//               const SizedBox(width: 4),

//               SizedBox(
//                 width: 150,
//                 child: TextField(
//                   controller: c.amountController,
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   decoration: const InputDecoration(
//                     hintText: "0.00",
//                     border: InputBorder.none,
//                   ),
//                   onChanged: (_) => c.notifyListeners(),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           /// WHAT WAS IT FOR
//           _sectionTitle("What was it for?"),

//           const SizedBox(height: 10),

//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: _cardDecoration(),
//               child: Row(
//                 children: const [
//                   Icon(Icons.restaurant, color: Colors.orange),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       "e.g. Dinner at Blue Bay",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                   Icon(Icons.calendar_today, size: 18),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 16),

//           /// CATEGORY ICONS
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _category("DINNER", Icons.restaurant, Colors.orange),
//                 _category("TAXI", Icons.local_taxi, Colors.blue),
//                 _category("SHOPPING", Icons.shopping_bag, Colors.purple),
//                 _category("OTHERS", Icons.more_horiz, Colors.green),
//               ],
//             ),
//           ),

//           const SizedBox(height: 18),

//           /// PAID BY
//           _sectionTitle("Paid by"),

//           const SizedBox(height: 10),

//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 _paidChip("You", true),
//                 const SizedBox(width: 10),
//                 _paidChip("Split", false),
//                 const Spacer(),
//                 const Text(
//                   "Balances",
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 18),

//           /// SPLIT WITH
//           _sectionTitle("Split with"),

//           const SizedBox(height: 10),

//           _splitTypeSelector(),

//           const SizedBox(height: 10),

//           /// MEMBERS
//           Expanded(child: _membersList()),

//           /// SAVE BUTTON
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: GestureDetector(
//               onTap: () {
//                 if (!c.validateAll(context)) return;

//                 final expense = {
//                   "title": "New Expense",
//                   "amount": c.totalAmount,
//                   "paidBy": "You",
//                   "splitCount": c.selectedMembers.length,
//                 };

//                 Navigator.pop(context, expense);
//               },
//               child: Container(
//                 height: 55,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF4A90D9), Color(0xFF5DADE2)],
//                   ),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     "Save Expense →",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// -------------------------

//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//         ),
//       ),
//     );
//   }

//   BoxDecoration _cardDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//     );
//   }

//   Widget _category(String label, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           width: 56,
//           height: 56,
//           decoration: BoxDecoration(
//             color: color.withOpacity(.15),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color),
//         ),
//         const SizedBox(height: 6),
//         Text(label, style: const TextStyle(fontSize: 11)),
//       ],
//     );
//   }

//   Widget _paidChip(String text, bool selected) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
//       decoration: BoxDecoration(
//         color: selected ? Colors.blue : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.blue),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(color: selected ? Colors.white : Colors.blue),
//       ),
//     );
//   }

//   /// SPLIT TYPE

//   Widget _splitTypeSelector() {
//     return Consumer<AddExpenseController>(
//       builder: (context, c, _) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             children: [
//               _chip(
//                 "By Equally",
//                 c.splitType == SplitType.equal,
//                 () => c.changeSplitType(SplitType.equal),
//               ),
//               const SizedBox(width: 8),
//               _chip(
//                 "By Percentage",
//                 c.splitType == SplitType.percentage,
//                 () => c.changeSplitType(SplitType.percentage),
//               ),
//               const SizedBox(width: 8),
//               _chip(
//                 "By Share",
//                 c.splitType == SplitType.share,
//                 () => c.changeSplitType(SplitType.share),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _chip(String text, bool selected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: selected ? Colors.blue : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.blue),
//         ),
//         child: Text(
//           text,
//           style: TextStyle(
//             fontSize: 12,
//             color: selected ? Colors.white : Colors.blue,
//           ),
//         ),
//       ),
//     );
//   }

//   /// MEMBERS LIST

//   Widget _membersList() {
//     return Consumer<AddExpenseController>(
//       builder: (context, c, _) {
//         return ListView.builder(
//           itemCount: c.members.length,
//           itemBuilder: (context, index) {
//             final m = c.members[index];

//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(
//                     color: m.isSelected ? Colors.blue : Colors.transparent,
//                     width: 2,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundImage: NetworkImage(m.avatar),
//                       radius: 22,
//                     ),

//                     const SizedBox(width: 12),

//                     Expanded(
//                       child: Text(
//                         m.name,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),

//                     _trailingWidget(c, m),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _trailingWidget(AddExpenseController c, MemberModel m) {
//     if (c.splitType == SplitType.equal) {
//       return Checkbox(
//         value: m.isSelected,
//         onChanged: (_) => c.toggleMember(m.id),
//       );
//     }

//     if (c.splitType == SplitType.percentage) {
//       return SizedBox(
//         width: 70,
//         child: TextField(
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(suffixText: "%"),
//           controller: TextEditingController(
//             text: m.percentage.toStringAsFixed(0),
//           ),
//           onChanged: (v) => c.updatePercentage(m.id, v),
//         ),
//       );
//     }

//     if (c.splitType == SplitType.share) {
//       return SizedBox(
//         width: 90,
//         child: TextField(
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(prefixText: "₹"),
//           onChanged: (v) => c.updateShareAmount(m.id, v),
//         ),
//       );
//     }

//     return const SizedBox();
//   }
// }
