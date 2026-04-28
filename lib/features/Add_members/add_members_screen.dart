// lib/features/Add_members/add_members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_members_controller.dart';
import 'package:splitzon/core/constants/app_colors.dart';

class AddMembersScreen extends StatelessWidget {
  final String groupId;

  const AddMembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddMembersController(groupId: groupId),
      child: const _AddMembersView(),
    );
  }
}

class _AddMembersView extends StatelessWidget {
  const _AddMembersView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddMembersController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Add Members",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                onChanged: controller.searchUsers,
                decoration: InputDecoration(
                  hintText: "Search by email or phone",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: controller.isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Searched User Card
            if (controller.searchedUser != null)
              _buildSearchedUserCard(controller),

            if (controller.searchedUser == null &&
                controller.searchQuery.length >= 3)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    "No user found",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Selected Members
            if (controller.selectedUsers.isNotEmpty) ...[
              const Text(
                "Selected Members",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.selectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = controller.selectedUsers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profilePicture.isNotEmpty
                              ? NetworkImage(user.profilePicture)
                              : null,
                          child: user.profilePicture.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => controller.removeFromSelected(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (controller.selectedUsers.isEmpty &&
                controller.searchedUser == null)
              const Expanded(
                child: Center(
                  child: Text(
                    "Search and add members to the group",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: controller.selectedUsers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final success = await controller.addAllSelectedMembers(context);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Members added successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: Text("Add ${controller.selectedUsers.length} Member(s)"),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildSearchedUserCard(AddMembersController controller) {
    final user = controller.searchedUser!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: user.profilePicture.isNotEmpty
                  ? NetworkImage(user.profilePicture)
                  : null,
              child: user.profilePicture.isEmpty
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  Text(user.phone, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Checkbox(
              value: controller.isSelected,
              onChanged: (_) => controller.toggleSelection(),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
