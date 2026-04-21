// ════════════════════════════════════════════════════════════════
// FILE: lib/features/gorup_dashboard/group_settings_screen.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/widgets/show_snack_bar.dart';
import 'package:splitzon/data/models/group_model.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/features/commentActivity/activity_controller.dart';

class GroupSettingsScreen extends StatefulWidget {
  final Group group;

  const GroupSettingsScreen({super.key, required this.group});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _isDeleting = false;
  String? _currentUserId;

  bool get _isGroupCreator {
    return _currentUserId == widget.group.createdBy;
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<UserProviders>().user?.id ?? '';
  }

  Future<void> _deleteGroup() async {
    if (!_isGroupCreator) {
      showSnackBar(context, 'Only group creator can delete this group');
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete This Group?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All expenses, balances, and group data will be permanently deleted.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete group from provider (handles local + sync)
      await context.read<GroupProvider>().deleteGroup(widget.group.id);

      // Log activity
      await context.read<ActivityController>().addActivity(
        type: 'delete',
        title: 'Group Deleted',
        description: 'Group "${widget.group.name}" was deleted',
        groupId: widget.group.id,
        groupName: widget.group.name,
        userId: _currentUserId ?? '',
        userName: context.read<UserProviders>().user?.name ?? '',
      );

      if (!mounted) return;

      showSnackBar(context, 'Group deleted successfully');

      // Navigate all the way back
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Failed to delete group: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Group Settings',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group info card
            _GroupInfoCard(group: widget.group),

            const SizedBox(height: 24),

            // Members header
            const Text(
              'Group Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Members list
            ...widget.group.members.map((member) {
              return _MemberCard(
                member: member,
                isCreator: member.id == widget.group.createdBy,
              );
            }),

            const SizedBox(height: 32),

            // Danger zone section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '⚠️ Deleting this group will permanently remove all expenses and data associated with it. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note about delete permission
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isGroupCreator
                                ? '✅ You are the group creator — you can delete this group'
                                : '🔒 Only the person who created this group can delete it',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isGroupCreator
                                  ? Colors.green.shade700
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delete group button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGroupCreator && !_isDeleting
                          ? _deleteGroup
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_forever_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Delete This Group Permanently',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── GROUP INFO CARD ─────────────────────────────────────────────
class _GroupInfoCard extends StatelessWidget {
  final Group group;

  const _GroupInfoCard({required this.group});

  @override
  Widget build(BuildContext context) {
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
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          if (group.description != null && group.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              group.description!,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 16),

          _InfoRow(
            icon: Icons.category_rounded,
            label: 'Group Type',
            value: group.groupType,
          ),

          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Currency',
            value: group.currency,
          ),

          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.people_rounded,
            label: 'Total Members',
            value: '${group.members.length}',
          ),
        ],
      ),
    );
  }
}

// ── INFO ROW ───────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── MEMBER CARD ─────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final dynamic member;
  final bool isCreator;

  const _MemberCard({required this.member, this.isCreator = false});

  static const _colors = [
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = member.id.hashCode % _colors.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _colors[colorIndex].withOpacity(0.85),
            child: Text(
              member.name?.isNotEmpty == true
                  ? member.name![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name ?? member.id,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isCreator)
                  Text(
                    'Group Creator',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
