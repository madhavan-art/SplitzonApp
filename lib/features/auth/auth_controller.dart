// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:splitzon/api/api_controller.dart';
// import 'package:splitzon/core/widgets/show_snack_bar.dart';
// import 'package:splitzon/services/firebase_auth.dart';

// class RegisterController {
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();

//   bool rememberMe = false;
//   String? completePhoneNumber;

//   /// 🔥 HANDLE SIGNUP (UPDATED)
//   Future<void> handleSignUp(BuildContext context) async {
//     if (!formKey.currentState!.validate()) {
//       print("❌ Form validation failed");
//       return;
//     }

//     if (completePhoneNumber == null) {
//       print("❌ Phone number is null");
//       showSnackBar(context, "Enter valid phone number");
//       return;
//     }

//     print("✅ Form valid");
//     print("📧 Email: ${emailController.text.trim()}");
//     print("📱 Phone: $completePhoneNumber");

//     try {
//       print("🔄 Calling API...");

//       /// ✅ STEP 1: CHECK USER IN BACKEND
//       final res = await ApiService.signupCheck(
//         name: nameController.text.trim(),
//         email: emailController.text.trim(),
//         phone: completePhoneNumber!,
//       );

//       print("📦 API Response: $res"); // ← most important

//       if (res["success"] == true) {
//         print("✅ No duplicates, sending OTP...");

//         /// ✅ STEP 2: SEND OTP
//         FirebaseAuthMethods(FirebaseAuth.instance).sendOtp(
//           context: context,
//           name: nameController.text.trim(),
//           email: emailController.text.trim(),
//           phone: completePhoneNumber!,
//           rememberMe: rememberMe,
//         );
//       } else {
//         print("❌ API returned error: ${res["message"]}");
//         showSnackBar(context, res["message"]);
//       }
//     } catch (e) {
//       print("🔥 Exception: $e");
//       showSnackBar(context, e.toString());
//     }
//   }

//   void dispose() {
//     nameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/core/widgets/show_snack_bar.dart';
import 'package:splitzon/services/firebase_auth.dart';

class RegisterController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool rememberMe = false;
  String? completePhoneNumber;

  Future<void> handleSignUp(
    BuildContext context, {
    required VoidCallback onLoadingStart, // ← added
    required VoidCallback onLoadingStop, // ← added
  }) async {
    if (!formKey.currentState!.validate()) return;

    if (completePhoneNumber == null) {
      showSnackBar(context, "Enter valid phone number");
      return;
    }

    onLoadingStart(); // ← start loading

    try {
      final res = await ApiService.signupCheck(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: completePhoneNumber!,
      );

      print("📦 API Response: $res");

      if (res["success"] == true) {
        // ✅ OTP sent — loading stops when OTP screen opens
        onLoadingStop();
        FirebaseAuthMethods(FirebaseAuth.instance).sendOtp(
          context: context,
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: completePhoneNumber!,
          rememberMe: rememberMe,
        );
      } else {
        onLoadingStop(); // ← stop loading on error
        showSnackBar(context, res["message"] ?? "Something went wrong");
      }
    } catch (e) {
      onLoadingStop(); // ← stop loading on exception
      print("🔥 Exception: $e");
      showSnackBar(context, e.toString());
    }
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}
