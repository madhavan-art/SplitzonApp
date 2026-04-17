// ════════════════════════════════════════════════════════════════
// FILE: lib/features/add_group/add_group_screen.dart
// ════════════════════════════════════════════════════════════════
//
//  Dynamic version using Provider + SQLite
//  - All UI preserved from original design
//  - Data saved via GroupProvider to SQLite
//  - Members stored as list of names (no static people.json)
//
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_main_theme.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/features/commentActivity/activity_controller.dart';

// ─────────────────────────────────────────────────────────────
// CURRENCY DATA
// ─────────────────────────────────────────────────────────────

class _Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  const _Currency(this.code, this.symbol, this.name, this.flag);
}

const List<_Currency> _kCurrencies = [
  _Currency('INR', '₹', 'Indian Rupee', '🇮🇳'),
  _Currency('USD', '\$', 'US Dollar', '🇺🇸'),
  _Currency('EUR', '€', 'Euro', '🇪🇺'),
  _Currency('GBP', '£', 'British Pound', '🇬🇧'),
  _Currency('JPY', '¥', 'Japanese Yen', '🇯🇵'),
  _Currency('AUD', 'A\$', 'Australian Dollar', '🇦🇺'),
  _Currency('CAD', 'C\$', 'Canadian Dollar', '🇨🇦'),
  _Currency('SGD', 'S\$', 'Singapore Dollar', '🇸🇬'),
  _Currency('AED', 'د.إ', 'UAE Dirham', '🇦🇪'),
  _Currency('SAR', '﷼', 'Saudi Riyal', '🇸🇦'),
  _Currency('THB', '฿', 'Thai Baht', '🇹🇭'),
  _Currency('MYR', 'RM', 'Malaysian Ringgit', '🇲🇾'),
  _Currency('IDR', 'Rp', 'Indonesian Rupiah', '🇮🇩'),
  _Currency('KRW', '₩', 'South Korean Won', '🇰🇷'),
  _Currency('CNY', '¥', 'Chinese Yuan', '🇨🇳'),
  _Currency('HKD', 'HK\$', 'Hong Kong Dollar', '🇭🇰'),
  _Currency('CHF', 'Fr', 'Swiss Franc', '🇨🇭'),
  _Currency('SEK', 'kr', 'Swedish Krona', '🇸🇪'),
  _Currency('NOK', 'kr', 'Norwegian Krone', '🇳🇴'),
  _Currency('NZD', 'NZ\$', 'New Zealand Dollar', '🇳🇿'),
];

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _shareCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  final List<String> _members = [];
  final _memberNameCtrl = TextEditingController();
  bool _isSaving = false;
  String _selectedType = 'Other';
  File? _pickedImage;
  _Currency _currency = _kCurrencies.first;

  static const _types = [
    {'label': 'Trip', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Home', 'icon': Icons.home_rounded},
    {'label': 'Office', 'icon': Icons.work_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Other', 'icon': Icons.category_rounded},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _shareCtrl.dispose();
    _budgetCtrl.dispose();
    _memberNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (file != null) setState(() => _pickedImage = File(file.path));
    } catch (e) {
      _snack('Could not open gallery.', Colors.orange);
    }
  }

  void _openCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencySheet(
        selected: _currency,
        onSelect: (c) {
          setState(() => _currency = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_members.isEmpty) {
      _snack('Please add at least one member.', Colors.red);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Create group via Provider (saves to SQLite)
      final createdGroup = await context.read<GroupProvider>().createGroup(
        name: _titleCtrl.text.trim(),
        description: _subtitleCtrl.text.trim(),
        groupType: _selectedType,
        currency: _currency.code,
        overallBudget: double.tryParse(_budgetCtrl.text.trim()) ?? 0.0,
        myShare: double.tryParse(_shareCtrl.text.trim()) ?? 0.0,
        members: _members,
        bannerImagePath: _pickedImage?.path,
      );

      // ✅ Log Group Created activity
      if (createdGroup != null) {
        try {
          final activityController = context.read<ActivityController>();
          await activityController.logGroupCreated(
            createdGroup.id,
            _titleCtrl.text.trim(),
            'You',
          );
        } catch (e) {
          debugPrint('⚠️ Could not log activity: $e');
        }
      }

      setState(() => _isSaving = false);
      if (!mounted) return;
      _snack('Group created successfully!', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Failed to create group. Try again.', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _addMember() {
    final name = _memberNameCtrl.text.trim();
    if (name.isEmpty) return;
    if (_members.contains(name)) {
      _snack('Member already added.', Colors.orange);
      return;
    }
    setState(() {
      _members.add(name);
      _memberNameCtrl.clear();
    });
  }

  void _removeMember(String member) {
    setState(() {
      _members.remove(member);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw < 360 ? sw * 0.04 : sw * 0.05;

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ── App Bar ───────────────────────────
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _BackBtn(),
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_members.length} members',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      // ── Sticky Create button ──────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          hPad,
          10,
          hPad,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF).withOpacity(.97),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────
      body: BackgroundMainTheme(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ╔══════════════════════════════╗
                // ║  1. OVERALL BUDGET HERO        ║
                // ╚══════════════════════════════╝
                _BudgetHero(
                  pickedImage: _pickedImage,
                  budgetCtrl: _budgetCtrl,
                  currency: _currency,
                  onPickImage: _pickImage,
                  onPickCurrency: _openCurrencyPicker,
                ),

                const SizedBox(height: 20),

                // ╔══════════════════════════════╗
                // ║  2. GROUP TYPE                 ║
                // ╚══════════════════════════════╝
                _SectionCard(
                  title: 'Group Type',
                  child: SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _types.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final t = _types[i];
                        final label = t['label'] as String;
                        final icon = t['icon'] as IconData;
                        final active = _selectedType == label;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: sw < 360 ? 66 : 74,
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          .3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color: active
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ╔══════════════════════════════╗
                // ║  3. GROUP DETAILS              ║
                // ╚══════════════════════════════╝
                _SectionCard(
                  title: 'Group Details',
                  child: Column(
                    children: [
                      _Field(
                        controller: _titleCtrl,
                        hint: 'e.g. Goa Trip, Office Lunch…',
                        label: 'Group Name',
                        icon: Icons.group_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Group name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _subtitleCtrl,
                        hint: 'Describe the purpose of this group…',
                        label: 'Description',
                        icon: Icons.description_rounded,
                        maxLines: 4,
                        minLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Description is required'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ╔══════════════════════════════╗
                // ║  4. MY SHARE                   ║
                // ╚══════════════════════════════╝
                _SectionCard(
                  title: 'My Share',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info hint
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.primary.withOpacity(.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'How much are you personally contributing to this group?',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Currency badge + amount input
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _openCurrencyPicker,
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _currency.symbol,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _shareCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Enter your share amount';
                                if (double.tryParse(v.trim()) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F9FF),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ╔══════════════════════════════╗
                // ║  5. ADD MEMBERS                ║
                // ╚══════════════════════════════╝
                _SectionCard(
                  title: 'Add Members',
                  trailing: _members.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_members.length} added',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  child: Column(
                    children: [
                      // Input row for adding members
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _memberNameCtrl,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter member name',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F9FF),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onFieldSubmitted: (_) => _addMember(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addMember,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Icon(Icons.add, size: 20),
                          ),
                        ],
                      ),

                      // Selected members chips
                      if (_members.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _members.map((member) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  .2,
                                ),
                                child: Text(
                                  member[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              label: Text(
                                member,
                                style: TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeMember(member),
                              backgroundColor: Colors.white,
                              deleteIconColor: Colors.red.shade400,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUDGET HERO
// ─────────────────────────────────────────────────────────────

class _BudgetHero extends StatelessWidget {
  final File? pickedImage;
  final TextEditingController budgetCtrl;
  final _Currency currency;
  final VoidCallback onPickImage;
  final VoidCallback onPickCurrency;

  const _BudgetHero({
    required this.pickedImage,
    required this.budgetCtrl,
    required this.currency,
    required this.onPickImage,
    required this.onPickCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── image + amount row ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular image picker
              GestureDetector(
                onTap: onPickImage,
                child: Stack(
                  children: [
                    Container(
                      width: sw < 360 ? 82 : 90,
                      height: sw < 360 ? 82 : 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEAF4FF),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(.2),
                          width: 2,
                        ),
                        image: pickedImage != null
                            ? DecorationImage(
                                image: FileImage(pickedImage!),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: NetworkImage(''),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Budget label + big input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERALL BUDGET',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total cost for this group / trip',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: onPickCurrency,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                fontSize: sw < 360 ? 22 : 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            controller: budgetCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: sw < 360 ? 26 : 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter overall budget';
                              if (double.tryParse(v.trim()) == null)
                                return 'Enter a valid number';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                fontSize: sw < 360 ? 26 : 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade300,
                                letterSpacing: -0.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onPickImage,
                      child: Text(
                        'Tap image to change photo',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),

          // ── currency row ───────────────────
          GestureDetector(
            onTap: onPickCurrency,
            child: Row(
              children: [
                Text(currency.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currency.code}  •  ${currency.name}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'All amounts in this group use ${currency.code}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CURRENCY PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _CurrencySheet extends StatefulWidget {
  final _Currency selected;
  final ValueChanged<_Currency> onSelect;
  const _CurrencySheet({required this.selected, required this.onSelect});

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final _searchCtrl = TextEditingController();
  List<_Currency> _filtered = _kCurrencies;

  void _filter(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _kCurrencies
          : _kCurrencies
                .where(
                  (c) =>
                      c.code.toLowerCase().contains(ql) ||
                      c.name.toLowerCase().contains(ql),
                )
                .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search currency…',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F9FF),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final active = c.code == widget.selected.code;
                return ListTile(
                  onTap: () => widget.onSelect(c),
                  leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    '${c.code}  –  ${c.name}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    c.symbol,
                    style: TextStyle(
                      fontSize: 12,
                      color: active
                          ? AppColors.primary.withOpacity(.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: active
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : null,
                  tileColor: active ? AppColors.primary.withOpacity(.04) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.primary,
        size: 18,
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.85),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;

  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        minLines: minLines,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          filled: true,
          fillColor: const Color(0xFFF5F9FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
