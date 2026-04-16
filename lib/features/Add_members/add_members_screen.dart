import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'add_members_controller.dart';

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
      appBar: AppBar(title: const Text("Add Members to Group")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: controller.searchUsers,
              decoration: InputDecoration(
                hintText: "Search by email or phone number",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: controller.isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            if (controller.searchedUser != null)
              GestureDetector(
                onTap: controller.toggleSelection,
                child: Card(
                  elevation: 3,
                  color: controller.isSelected
                      ? Colors.green.shade50
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: controller.isSelected
                        ? const BorderSide(color: Colors.green, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage:
                              controller.searchedUser!.profilePicture.isNotEmpty
                              ? NetworkImage(
                                  controller.searchedUser!.profilePicture,
                                )
                              : null,
                          child: controller.searchedUser!.profilePicture.isEmpty
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.searchedUser!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.searchedUser!.email,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.searchedUser!.phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: controller.isSelected,
                          onChanged: (val) => controller.toggleSelection(),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (controller.searchQuery.isNotEmpty &&
                !controller.isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "No user found with that email or phone",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            if (controller.selectedUsers.isNotEmpty) ...[
              const Text(
                "Selected Members",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.selectedUsers[index];
                  return Card(
                    color: Colors.green.shade50,
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
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: controller.selectedUsers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final success = await controller.addAllSelectedMembers();
                if (!context.mounted) return;

                if (success) {
                  // Auto refresh GroupProvider so UI updates immediately
                  final groupProvider = Provider.of<GroupProvider>(
                    context,
                    listen: false,
                  );
                  await groupProvider.refreshGroups();

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Members added successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to add members. Check connection."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: Text("Add ${controller.selectedUsers.length} Member(s)"),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'add_members_controller.dart';

// class AddMembersScreen extends StatelessWidget {
//   final String groupId;

//   const AddMembersScreen({super.key, required this.groupId});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AddMembersController(groupId: groupId),
//       child: const _AddMembersView(),
//     );
//   }
// }

// class _AddMembersView extends StatelessWidget {
//   const _AddMembersView();

//   @override
//   Widget build(BuildContext context) {
//     final controller = context.watch<AddMembersController>();

//     return Scaffold(
//       appBar: AppBar(title: const Text("Add Members to Group")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Input
//             TextField(
//               onChanged: controller.searchUsers,
//               decoration: InputDecoration(
//                 hintText: "Search by email or phone number",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 suffixIcon: controller.isSearching
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : null,
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Search Result Card
//             if (controller.searchedUser != null)
//               GestureDetector(
//                 onTap: controller.toggleSelection,
//                 child: Card(
//                   elevation: 3,
//                   color: controller.isSelected
//                       ? Colors.green.shade50
//                       : Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     side: controller.isSelected
//                         ? const BorderSide(color: Colors.green, width: 2)
//                         : BorderSide.none,
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Row(
//                       children: [
//                         // Profile Picture
//                         CircleAvatar(
//                           radius: 32,
//                           backgroundImage:
//                               controller.searchedUser!.profilePicture.isNotEmpty
//                               ? NetworkImage(
//                                   controller.searchedUser!.profilePicture,
//                                 )
//                               : null,
//                           child: controller.searchedUser!.profilePicture.isEmpty
//                               ? const Icon(Icons.person, size: 32)
//                               : null,
//                         ),
//                         const SizedBox(width: 16),

//                         // User Details (Horizontal Layout)
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 controller.searchedUser!.name,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 controller.searchedUser!.email,
//                                 style: TextStyle(
//                                   color: Colors.grey[700],
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 controller.searchedUser!.phone,
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         // Checkbox
//                         Checkbox(
//                           value: controller.isSelected,
//                           onChanged: (val) => controller.toggleSelection(),
//                           activeColor: Colors.green,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//             else if (controller.searchQuery.isNotEmpty &&
//                 !controller.isSearching)
//               const Center(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 40),
//                   child: Text(
//                     "No user found with that email or phone",
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 ),
//               ),

//             const SizedBox(height: 30),

//             // Selected Members Section
//             if (controller.selectedUsers.isNotEmpty) ...[
//               const Text(
//                 "Selected Members",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 12),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: controller.selectedUsers.length,
//                 itemBuilder: (context, index) {
//                   final user = controller.selectedUsers[index];
//                   return Card(
//                     color: Colors.green.shade50,
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: user.profilePicture.isNotEmpty
//                             ? NetworkImage(user.profilePicture)
//                             : null,
//                         child: user.profilePicture.isEmpty
//                             ? const Icon(Icons.person)
//                             : null,
//                       ),
//                       title: Text(user.name),
//                       subtitle: Text(user.email),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.close, color: Colors.red),
//                         onPressed: () => controller.removeFromSelected(index),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],

//             const SizedBox(height: 80), // Space for floating button
//           ],
//         ),
//       ),

//       // Floating Action Button - Add All Selected
//       floatingActionButton: controller.selectedUsers.isNotEmpty
//           ? FloatingActionButton.extended(
//               onPressed: () async {
//                 final success = await controller.addAllSelectedMembers();
//                 if (!context.mounted) return;

//                 if (success) {
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Members added successfully!"),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text("Failed to add members. Check connection."),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               icon: const Icon(Icons.check),
//               label: Text("Add ${controller.selectedUsers.length} Member(s)"),
//               backgroundColor: Colors.green,
//             )
//           : null,
//     );
//   }
// }
