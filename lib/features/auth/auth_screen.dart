// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/core/utils/background_theme.dart';
// import 'package:splitzon/core/widgets/app_branding.dart';
// import 'package:splitzon/core/widgets/primary_button.dart';
// import 'package:splitzon/features/auth/auth_controller.dart';

// class AuthenticationScreen extends StatefulWidget {
//   const AuthenticationScreen({super.key});

//   @override
//   State<AuthenticationScreen> createState() => _AuthenticationScreenState();
// }

// class _AuthenticationScreenState extends State<AuthenticationScreen> {
//   final RegisterController controller = RegisterController();

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return BackgroundTheme(
//       child: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.only(
//             left: 24,
//             right: 24,
//             top: 10,
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: MediaQuery.of(context).size.height,
//             ),
//             child: Form(
//               key: controller.formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   /// TITLE
//                   Text(
//                     "Welcome ...",
//                     style: TextStyle(
//                       fontSize: size.width * 0.08,
//                       fontWeight: FontWeight.w800,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   Text(
//                     "Sign up and start to manage your shared expenses.",
//                     style: TextStyle(
//                       fontSize: 15,
//                       height: 1.5,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),

//                   const SizedBox(height: 30),

//                   /// CARD
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(.95),
//                       borderRadius: BorderRadius.circular(22),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(.08),
//                           blurRadius: 25,
//                           offset: const Offset(0, 15),
//                         ),
//                       ],
//                     ),

//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         /// NAME
//                         _buildLabel("Full Name"),
//                         const SizedBox(height: 6),

//                         _buildTextField(
//                           controller: controller.nameController,
//                           hint: "eg. P Madhavan",
//                           icon: Icons.person_outline,
//                           keyboardType: TextInputType.name,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Enter full name";
//                             }
//                             return null;
//                           },
//                         ),

//                         const SizedBox(height: 16),

//                         /// EMAIL
//                         _buildLabel("Email Address"),
//                         const SizedBox(height: 6),

//                         _buildTextField(
//                           controller: controller.emailController,
//                           hint: "eg. madhavan@gmail.com",
//                           icon: Icons.email_outlined,
//                           keyboardType: TextInputType.emailAddress,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return "Enter email";
//                             }
//                             return null;
//                           },
//                         ),

//                         const SizedBox(height: 16),

//                         /// PHONE
//                         _buildLabel("Phone Number"),
//                         const SizedBox(height: 6),

//                         IntlPhoneField(
//                           controller: controller.phoneController,
//                           initialCountryCode: 'IN',
//                           style: TextStyle(color: AppColors.textSecondary),
//                           dropdownTextStyle: TextStyle(
//                             color: AppColors.textPrimary,
//                             fontWeight: FontWeight.w600,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: "9876543210",
//                             hintStyle: TextStyle(
//                               color: AppColors.textSecondary.withOpacity(.2),
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey.shade100,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(14),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),

//                           onChanged: (phone) {
//                             controller.completePhoneNumber =
//                                 phone.completeNumber;
//                           },

//                           validator: (phone) {
//                             if (phone == null || !phone.isValidNumber()) {
//                               return "Enter valid phone number";
//                             }
//                             return null;
//                           },
//                         ),

//                         const SizedBox(height: 10),

//                         /// REMEMBER ME
//                         Row(
//                           children: [
//                             Checkbox(
//                               value: controller.rememberMe,
//                               activeColor: AppColors.primary,
//                               onChanged: (value) {
//                                 setState(() {
//                                   controller.rememberMe = value ?? false;
//                                 });
//                               },
//                             ),

//                             const Text(
//                               "Keep me signed in",
//                               style: TextStyle(color: AppColors.textPrimary),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 10),

//                         /// SIGN UP BUTTON
//                         PrimaryButton(
//                           title: "Sign Up",
//                           icon: Icons.arrow_forward_rounded,
//                           onPressed: () => controller.handleSignUp(context),
//                         ),

//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   /// LOGIN
//                   Center(
//                     child: RichText(
//                       text: TextSpan(
//                         style: const TextStyle(color: Colors.black),
//                         children: [
//                           const TextSpan(text: "Already have an account? "),
//                           TextSpan(
//                             text: "Login",
//                             style: TextStyle(
//                               color: AppColors.primary,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             recognizer: TapGestureRecognizer()
//                               ..onTap = () {
//                                 Navigator.pushNamed(context, "/login");
//                               },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   const AppBranding(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// LABEL
//   Widget _buildLabel(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontWeight: FontWeight.w600,
//         fontSize: 16,
//         color: AppColors.textPrimary,
//       ),
//     );
//   }

//   /// TEXTFIELD
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     required TextInputType keyboardType,
//     required String? Function(String?) validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       validator: validator,
//       // style: TextStyle(color: AppColors.textPrimary),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(.2)),
//         prefixIcon: Icon(icon),
//         prefixIconColor: AppColors.textPrimary,
//         filled: true,
//         prefixStyle: TextStyle(color: AppColors.textPrimary),
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_theme.dart';
import 'package:splitzon/core/widgets/app_branding.dart';
import 'package:splitzon/features/auth/auth_controller.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final RegisterController controller = RegisterController();
  bool _isLoading = false; // ← loading state

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ✅ Dismiss keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // ✅ Handle signup
  Future<void> _handleSignUp() async {
    _dismissKeyboard(); // ← hide keyboard immediately on button tap
    await controller.handleSignUp(
      context,
      onLoadingStart: () => setState(() => _isLoading = true),
      onLoadingStop: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _dismissKeyboard, // ← tap anywhere dismisses keyboard
      child: BackgroundTheme(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Text(
                      "Welcome ...",
                      style: TextStyle(
                        fontSize: size.width * 0.08,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign up and start to manage your shared expenses.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.95),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 25,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// NAME
                          _buildLabel("Full Name"),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: controller.nameController,
                            hint: "eg. P Madhavan",
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            textInputAction:
                                TextInputAction.next, // ← next moves to email
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "Enter full name";
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// EMAIL
                          _buildLabel("Email Address"),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: controller.emailController,
                            hint: "eg. madhavan@gmail.com",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction:
                                TextInputAction.done, // ← done closes keyboard
                            onEditingComplete:
                                _dismissKeyboard, // ← closes after .com
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "Enter email";
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// PHONE
                          _buildLabel("Phone Number"),
                          const SizedBox(height: 6),
                          IntlPhoneField(
                            controller: controller.phoneController,
                            initialCountryCode: 'IN',
                            textInputAction:
                                TextInputAction.done, // ← done closes keyboard
                            style: TextStyle(color: AppColors.textSecondary),
                            dropdownTextStyle: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: "9876543210",
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(.2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (phone) {
                              controller.completePhoneNumber =
                                  phone.completeNumber;
                            },
                            onSubmitted: (_) =>
                                _dismissKeyboard(), // ← closes on submit
                            validator: (phone) {
                              if (phone == null || !phone.isValidNumber()) {
                                return "Enter valid phone number";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          /// REMEMBER ME
                          Row(
                            children: [
                              Checkbox(
                                value: controller.rememberMe,
                                activeColor: AppColors.primary,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          controller.rememberMe =
                                              value ?? false;
                                        });
                                      },
                              ),
                              const Text(
                                "Keep me signed in",
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// SIGN UP BUTTON WITH LOADING
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary
                                    .withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Please wait...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// LOGIN
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (!_isLoading)
                                    Navigator.pushNamed(context, "/login");
                                },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    const AppBranding(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    TextInputAction? textInputAction, // ← added
    VoidCallback? onEditingComplete, // ← added
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction, // ← added
      onEditingComplete: onEditingComplete, // ← added
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(.2)),
        prefixIcon: Icon(icon),
        prefixIconColor: AppColors.textPrimary,
        filled: true,
        prefixStyle: TextStyle(color: AppColors.textPrimary),
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
