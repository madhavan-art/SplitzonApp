// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:splitzon/core/constants/app_colors.dart';
// import 'package:splitzon/core/utils/background_theme.dart';
// import 'package:splitzon/core/widgets/app_branding.dart';
// import 'package:splitzon/core/widgets/primary_button.dart';
// import 'package:splitzon/features/auth/login_controller.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final LoginController controller = LoginController();

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
//                   const SizedBox(height: 30),

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
//                     "Sign In to continue to manage your shared expenses.",
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
//                         /// PHONE
//                         _buildLabel("Phone Number"),
//                         const SizedBox(height: 20),

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
//                           title: "Sign In",
//                           icon: Icons.arrow_forward_rounded,
//                           onPressed: () => controller.handleSignUp(context),
//                         ),

//                         // const SizedBox(height: 25),
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
//                           const TextSpan(text: "Don't have an account? "),
//                           TextSpan(
//                             text: "Sign Up",
//                             style: TextStyle(
//                               color: AppColors.primary,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             recognizer: TapGestureRecognizer()
//                               ..onTap = () {
//                                 Navigator.pushNamed(context, "/auth");
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
// }

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_theme.dart';
import 'package:splitzon/core/widgets/app_branding.dart';
import 'package:splitzon/features/auth/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = LoginController();
  bool _isLoading = false; // ← loading state

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSignIn() async {
    _dismissKeyboard();
    await controller.handleSignIn(
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
      onTap: _dismissKeyboard,
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
                    const SizedBox(height: 30),

                    Text(
                      "Welcome Back...",
                      style: TextStyle(
                        fontSize: size.width * 0.08,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign in to continue managing your shared expenses.",
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
                          _buildLabel("Phone Number"),
                          const SizedBox(height: 6),

                          IntlPhoneField(
                            controller: controller.phoneController,
                            initialCountryCode: 'IN',
                            textInputAction: TextInputAction.done,
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
                            onSubmitted: (_) => _dismissKeyboard(),
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

                          /// SIGN IN BUTTON WITH LOADING
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
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
                                          "Sign In",
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

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  if (!_isLoading) {
                                    Navigator.pushNamed(context, "/auth");
                                  }
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
}
