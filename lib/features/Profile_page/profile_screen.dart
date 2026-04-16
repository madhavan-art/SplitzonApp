// // lib/screens/profile_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/features/Profile_page/profile_card.dart';
// import 'package:splitzon/features/Profile_page/profile_controller.dart';
// import 'edit_personal_info_screen.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<ProfileController>(context);

//     // Initialize controller
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       controller.init(context);
//     });

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F4F9),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           'My Profile',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings_outlined, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         children: [
//           _buildProfileHeader(controller),
//           const SizedBox(height: 30),

//           _buildSectionTitle("PERSONAL ACCOUNT"),

//           // Personal Account Group
//           _buildGroupedCard([
//             ProfileCard(
//               icon: Icons.person_outline,
//               title: 'Personal Information',
//               subtitle: 'Name, email, phone number',
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const EditPersonalInfoScreen(),
//                 ),
//               ),
//             ),
//             const Divider(height: 1, indent: 70),
//             ProfileCard(
//               icon: Icons.security_outlined,
//               title: 'Security & Privacy',
//               subtitle: 'Biometrics, password, 2FA',
//               onTap: () {},
//             ),
//             const Divider(height: 1, indent: 70),
//             ProfileCard(
//               icon: Icons.notifications_outlined,
//               title: 'Notifications',
//               subtitle: 'Alerts, sounds, reminders',
//               onTap: () {},
//             ),
//           ]),

//           const SizedBox(height: 30),
//           _buildSectionTitle("APP PREFERENCES"),

//           // App Preferences Group (Language removed)
//           _buildGroupedCard([
//             ProfileCard(
//               icon: Icons.support_agent_outlined,
//               title: 'Support Center',
//               subtitle: 'FAQ, live chat, feedback',
//               onTap: () {},
//             ),
//           ]),

//           const SizedBox(height: 30),
//           Center(
//             child: TextButton.icon(
//               onPressed: controller.signOut,
//               icon: const Icon(Icons.logout, color: Colors.redAccent),
//               label: const Text(
//                 'Sign Out',
//                 style: TextStyle(
//                   color: Colors.redAccent,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Center(
//             child: Text(
//               "SPLITZON VERSION 1.0.0 (BUILD 982)",
//               style: TextStyle(
//                 color: Colors.grey.shade400,
//                 fontSize: 10,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // ── UI HELPER METHODS ─────────────────────────────────────

//   Widget _buildProfileHeader(ProfileController controller) {
//     return Column(
//       children: [
//         Stack(
//           alignment: Alignment.bottomRight,
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.blue.withOpacity(0.1),
//               child: const Icon(Icons.person, size: 50, color: Colors.blue),
//             ),
//             Container(
//               padding: const EdgeInsets.all(3),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//               ),
//               child: const CircleAvatar(
//                 radius: 8,
//                 backgroundColor: Colors.green,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 15),
//         Text(
//           controller.user.name,
//           style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           controller.user.email,
//           style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: const Color(0xFFE3F2FD),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: const Text(
//             "Premium Member",
//             style: TextStyle(
//               color: Color(0xFF5AB2F7),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//         const SizedBox(height: 25),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildStatItem(
//               Icons.account_balance_wallet_outlined,
//               "\$12.4k",
//               "SAVED",
//             ),
//             _buildStatItem(Icons.grid_view_rounded, "8", "GROUPS"),
//             _buildStatItem(Icons.bolt, "98%", "RELIABLE"),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatItem(IconData icon, String value, String label) {
//     return Column(
//       children: [
//         Icon(icon, color: const Color(0xFF5AB2F7), size: 20),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey.shade500,
//             fontSize: 10,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12, left: 4),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w800,
//           color: Colors.black.withOpacity(0.6),
//           letterSpacing: 1.1,
//         ),
//       ),
//     );
//   }

//   Widget _buildGroupedCard(List<Widget> children) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 15,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(children: children),
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════
// FILE: lib/features/Profile_page/profile_screen.dart
// ════════════════════════════════════════════════════════════════
//
// FIX: Profile header reads from UserProviders (source of truth)
//      so after editing name/email it updates immediately without
//      needing a full reload.
//
// FIX: Sign out calls FirebaseAuthMethods so ExpenseProvider and
//      GroupProvider are also cleared correctly.
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/features/Profile_page/profile_card.dart';
import 'package:splitzon/features/Profile_page/profile_controller.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/services/firebase_auth.dart';
import 'edit_personal_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = context.watch<ProfileController>();
    // ✅ Read name/email from UserProviders — single source of truth
    // After updatePersonalInfo(), UserProviders is updated immediately,
    // so this widget auto-rebuilds with the new name.
    final userProvider = context.watch<UserProviders>();
    final userName = userProvider.user?.name ?? '';
    final userEmail = userProvider.user?.email ?? '';

    // Init controller whenever screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileCtrl.init(context);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // ── Profile header ──────────────────────────────────
          _buildProfileHeader(
            context,
            userName: userName,
            userEmail: userEmail,
            profilePicture: profileCtrl.user.profilePicture,
          ),

          const SizedBox(height: 30),
          _buildSectionTitle('PERSONAL ACCOUNT'),

          _buildGroupedCard([
            ProfileCard(
              icon: Icons.person_outline,
              title: 'Personal Information',
              subtitle: 'Name, email, phone number',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditPersonalInfoScreen(),
                ),
              ),
            ),
            const Divider(height: 1, indent: 70),
            ProfileCard(
              icon: Icons.security_outlined,
              title: 'Security & Privacy',
              subtitle: 'Biometrics, password, 2FA',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 70),
            ProfileCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Alerts, sounds, reminders',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 30),
          _buildSectionTitle('APP PREFERENCES'),

          _buildGroupedCard([
            ProfileCard(
              icon: Icons.support_agent_outlined,
              title: 'Support Center',
              subtitle: 'FAQ, live chat, feedback',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 30),
          Center(
            child: TextButton.icon(
              // ✅ Use FirebaseAuthMethods so all providers are cleared
              onPressed: () =>
                  FirebaseAuthMethods(FirebaseAuth.instance).signOut(context),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              'SPLITZON VERSION 1.0.0 (BUILD 982)',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String userName,
    required String userEmail,
    required String profilePicture,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.withOpacity(0.1),
              backgroundImage: profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture) as ImageProvider
                  : null,
              child: profilePicture.isEmpty
                  ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 8,
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // ✅ Uses userName from UserProviders — updates immediately after edit
        Text(
          userName.isNotEmpty ? userName : 'User',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          userEmail,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Premium Member',
            style: TextStyle(
              color: Color(0xFF5AB2F7),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              Icons.account_balance_wallet_outlined,
              '₹12.4k',
              'SAVED',
            ),
            _buildStatItem(Icons.grid_view_rounded, '8', 'GROUPS'),
            _buildStatItem(Icons.bolt, '98%', 'RELIABLE'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: const Color(0xFF5AB2F7), size: 20),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.black.withOpacity(0.6),
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _buildGroupedCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(children: children),
  );
}
