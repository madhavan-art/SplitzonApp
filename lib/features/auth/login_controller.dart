// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:splitzon/core/widgets/show_snack_bar.dart';
// import 'package:splitzon/services/firebase_auth.dart';

// class LoginController {
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   final TextEditingController phoneController = TextEditingController();

//   bool rememberMe = false;
//   String? completePhoneNumber;

//   /// HANDLE SIGNUP
//   Future<void> handleSignUp(BuildContext context) async {
//     if (!formKey.currentState!.validate()) return;

//     if (completePhoneNumber == null) {
//       showSnackBar(context, "Enter valid phone number");
//       return;
//     }

//     FirebaseAuthMethods(FirebaseAuth.instance).sendOtpLogin(
//       context: context,
//       phone: completePhoneNumber!,
//       rememberMe: rememberMe,
//     );
//   }

//   /// DISPOSE CONTROLLERS
//   void dispose() {
//     phoneController.dispose();
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/core/widgets/show_snack_bar.dart';
import 'package:splitzon/services/firebase_auth.dart';

class LoginController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  bool rememberMe = false;
  String? completePhoneNumber;

  Future<void> handleSignIn(
    BuildContext context, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingStop,
  }) async {
    if (!formKey.currentState!.validate()) return;

    if (completePhoneNumber == null) {
      showSnackBar(context, "Enter valid phone number");
      return;
    }

    onLoadingStart();

    try {
      // ✅ STEP 1: Check phone exists in DB
      final res = await ApiService.signinCheck(phone: completePhoneNumber!);

      if (res["success"] == true) {
        onLoadingStop();
        // ✅ STEP 2: Send OTP
        FirebaseAuthMethods(FirebaseAuth.instance).sendOtpLogin(
          context: context,
          phone: completePhoneNumber!,
          rememberMe: rememberMe,
        );
      } else {
        onLoadingStop();
        showSnackBar(
          context,
          res["message"] ?? "User not found, please register!",
        );
      }
    } catch (e) {
      onLoadingStop();
      showSnackBar(context, e.toString());
    }
  }

  void dispose() {
    phoneController.dispose();
  }
}
