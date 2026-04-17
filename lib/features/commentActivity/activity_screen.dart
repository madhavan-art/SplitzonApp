import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/features/commentActivity/activity_controller.dart';
import 'package:splitzon/features/commentActivity/activity_model.dart';

class ActivityScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;
  const ActivityScreen({super.key, this.groupId, this.groupName});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Timer? _timeUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.groupId != null) {
        context.read<ActivityController>().loadGroupActivities(widget.groupId!);
      } else {
        context.read<ActivityController>().initialize();
      }
    });

    // Auto update timestamps every 30 seconds
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'add_expense':
        return Icons.receipt_long_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;
      case 'add_member':
        return Icons.person_add_rounded;
      case 'create':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'add_expense':
        return Colors.blue;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      case 'add_member':
        return Colors.green;
      case 'create':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityController = context.watch<ActivityController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Activity',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (activityController.activities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Activity'),
                    content: const Text(
                      'Are you sure you want to clear all activity history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          activityController.clearAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: activityController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activityController.activities.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All your group activities will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activityController.activities.length,
              itemBuilder: (ctx, index) {
                final activity = activityController.activities[index];
                return _ActivityItem(
                  activity: activity,
                  icon: _getIconForType(activity.type),
                  color: _getColorForType(activity.type),
                  date: _formatDate(activity.timestamp),
                );
              },
            ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityModel activity;
  final IconData icon;
  final Color color;
  final String date;

  const _ActivityItem({
    required this.activity,
    required this.icon,
    required this.color,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activity.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (activity.groupName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      activity.groupName,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
