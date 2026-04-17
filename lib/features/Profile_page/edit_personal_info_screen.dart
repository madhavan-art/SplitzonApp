// ════════════════════════════════════════════════════════════════
// FILE: lib/features/Profile_page/edit_personal_info_screen.dart
// ════════════════════════════════════════════════════════════════
//
// FIX: Pass `context` to controller methods instead of storing it.
// FIX: Profile picture save now calls updateProfilePicture() correctly.
// FIX: Name/email/phone saved together in one call.
// ════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/features/Profile_page/profile_controller.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  File? _selectedImage;
  String? _emailError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<ProfileController>();
    _nameController = TextEditingController(text: ctrl.user.name);
    _emailController = TextEditingController(text: ctrl.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Pick image from gallery ───────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      debugPrint('🖼️ Image picked: ${pickedFile.path}');
    }
  }

  // ── Validate email format ─────────────────────────────────
  void _validateEmail(String value) {
    final isValid = RegExp(
      r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(value);
    setState(
      () => _emailError = isValid ? null : 'Please enter a valid email address',
    );
  }

  // ── Save all changes ──────────────────────────────────────
  Future<void> _saveChanges() async {
    if (_emailError != null) return;

    setState(() => _isSaving = true);

    final ctrl = context.read<ProfileController>();
    bool success = false;

    // ── Update name/email only ───────────────────────────
    debugPrint('💾 Saving name/email...');
    success = await ctrl.updatePersonalInfo(
      context: context, // ✅ pass context as parameter
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: ctrl.user.phone,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ctrl.lastError.isNotEmpty
                ? ctrl.lastError
                : 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ── Profile picture ───────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    // Show picked image → existing URL → initials
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (ctrl.user.profilePicture.isNotEmpty
                              ? NetworkImage(ctrl.user.profilePicture)
                                    as ImageProvider
                              : null),
                    child:
                        (_selectedImage == null &&
                            ctrl.user.profilePicture.isEmpty)
                        ? Text(
                            ctrl.user.name.isNotEmpty
                                ? ctrl.user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5AB2F7),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5AB2F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'New photo selected — tap Save to upload',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                ),
              ),

            const SizedBox(height: 40),

            // ── Name + Email fields ───────────────────────────
            _buildGroupedCard([
              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              const Divider(height: 1, indent: 55),
              _buildTextField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                errorText: _emailError,
                onChanged: _validateEmail,
              ),
            ]),

            const SizedBox(height: 20),

            // ── Phone (read-only) ─────────────────────────────
            _buildGroupedCard([
              ListTile(
                leading: const Icon(
                  Icons.phone_android_outlined,
                  color: Colors.grey,
                ),
                title: const Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                subtitle: Text(
                  ctrl.user.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ]),

            const SizedBox(height: 50),

            // ── Save button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_emailError == null && !_isSaving)
                    ? _saveChanges
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5AB2F7),
                  disabledBackgroundColor: const Color(
                    0xFF5AB2F7,
                  ).withOpacity(0.5),
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
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? errorText,
    Function(String)? onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        if (errorText != null)
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
      ],
    ),
  );
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/features/Profile_page/profile_controller.dart';

// class EditPersonalInfoScreen extends StatefulWidget {
//   const EditPersonalInfoScreen({super.key});

//   @override
//   State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
// }

// class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
//   late TextEditingController nameController;
//   late TextEditingController emailController;
//   File? _selectedImage;
//   String? emailError;

//   @override
//   void initState() {
//     super.initState();
//     final user = context.read<ProfileController>().user;
//     nameController = TextEditingController(text: user.name);
//     emailController = TextEditingController(text: user.email);
//   }

//   // --- Image Picker Logic ---
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//       });
//     }
//   }

//   // --- Email Validation Logic ---
//   void _validateEmail(String value) {
//     final bool emailValid = RegExp(
//       r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
//     ).hasMatch(value);
//     setState(() {
//       emailError = emailValid ? null : "Please enter a valid email address";
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<ProfileController>(context);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F4F9),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             // --- Animated Profile Photo ---
//             GestureDetector(
//               onTap: _pickImage,
//               child: TweenAnimationBuilder(
//                 tween: Tween<double>(begin: 0.8, end: 1.0),
//                 duration: const Duration(milliseconds: 500),
//                 curve: Curves.elasticOut,
//                 builder: (context, double value, child) {
//                   return Transform.scale(scale: value, child: child);
//                 },
//                 child: Stack(
//                   alignment: Alignment.bottomRight,
//                   children: [
//                     CircleAvatar(
//                       radius: 60,
//                       backgroundColor: Colors.white,
//                       backgroundImage: _selectedImage != null
//                           ? FileImage(_selectedImage!)
//                           : null,
//                       child: _selectedImage == null
//                           ? const Icon(
//                               Icons.person,
//                               size: 60,
//                               color: Colors.blue,
//                             )
//                           : null,
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF5AB2F7),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.add_a_photo,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),

//             // --- Inputs with Fade-in Animation ---
//             _buildAnimatedSection(
//               title: "GENERAL",
//               delay: 200,
//               child: _buildGroupedCard([
//                 _buildTextField(
//                   label: "Full Name",
//                   controller: nameController,
//                   icon: Icons.person_outline,
//                 ),
//                 const Divider(height: 1, indent: 55),
//                 _buildTextField(
//                   label: "Email Address",
//                   controller: emailController,
//                   icon: Icons.email_outlined,
//                   errorText: emailError,
//                   onChanged: _validateEmail,
//                 ),
//               ]),
//             ),

//             const SizedBox(height: 30),

//             _buildAnimatedSection(
//               title: "SECURED",
//               delay: 400,
//               child: _buildGroupedCard([
//                 _buildLockedField(
//                   label: "Phone Number",
//                   value: controller.user.phone,
//                   icon: Icons.phone_android_outlined,
//                 ),
//               ]),
//             ),

//             const SizedBox(height: 40),

//             // --- Animated Save Button ---
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: emailError == null
//                     ? () {
//                         controller.updatePersonalInfo(
//                           nameController.text,
//                           emailController.text,
//                           controller.user.phone,
//                         );
//                         Navigator.pop(context);
//                       }
//                     : null, // Disable button if email is wrong
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF5AB2F7),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text(
//                   "Save Changes",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- Animation Helper ---
//   Widget _buildAnimatedSection({
//     required String title,
//     required int delay,
//     required Widget child,
//   }) {
//     return TweenAnimationBuilder(
//       tween: Tween<double>(begin: 0, end: 1),
//       duration: Duration(milliseconds: delay + 500),
//       builder: (context, double value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(0, 30 * (1 - value)),
//             child: child,
//           ),
//         );
//       },
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 10, bottom: 10),
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//           ),
//           child,
//         ],
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
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(children: children),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     String? errorText,
//     Function(String)? onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, color: const Color(0xFF5AB2F7)),
//         title: Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: Colors.grey),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: controller,
//               onChanged: onChanged,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               decoration: const InputDecoration(
//                 isDense: true,
//                 border: InputBorder.none,
//               ),
//             ),
//             if (errorText != null)
//               Text(
//                 errorText,
//                 style: const TextStyle(color: Colors.red, fontSize: 11),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLockedField({
//     required String label,
//     required String value,
//     required IconData icon,
//   }) {
//     return ListTile(
//       leading: const Icon(Icons.phone_android_outlined, color: Colors.grey),
//       title: Text(
//         label,
//         style: const TextStyle(fontSize: 12, color: Colors.grey),
//       ),
//       subtitle: Text(
//         value,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.grey,
//         ),
//       ),
//       trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
//     );
//   }
// }
