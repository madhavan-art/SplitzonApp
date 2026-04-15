// ════════════════════════════════════════════════════════════════
// FILE: lib/services/firebase_auth.dart
// ════════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/core/utils/otp_screen.dart';
import 'package:splitzon/core/utils/otp_screen_login.dart';
import 'package:splitzon/core/widgets/show_snack_bar.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/services/connectivity_service.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;
  FirebaseAuthMethods(this._auth);

  Future<void> sendOtp({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (c) async => await _auth.signInWithCredential(c),
        verificationFailed: (e) =>
            showSnackBar(context, e.message ?? 'OTP Failed'),
        codeSent: (verificationId, _) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              name: name,
              email: email,
              phone: phone,
              verificationId: verificationId,
              rememberMe: rememberMe,
            ),
          ),
        ),
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> sendOtpLogin({
    required BuildContext context,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (c) async => await _auth.signInWithCredential(c),
        verificationFailed: (e) =>
            showSnackBar(context, e.message ?? 'OTP Failed'),
        codeSent: (verificationId, _) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreenLogin(
              phone: phone,
              verificationId: verificationId,
              rememberMe: rememberMe,
            ),
          ),
        ),
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> verifyOtpAndHandleUser({
    required BuildContext context,
    required String verificationId,
    required String otp,
    required String name,
    required String email,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final uc = await _auth.signInWithCredential(cred);
      if (uc.user == null) {
        showSnackBar(context, 'Auth Failed');
        return;
      }
      final res = await ApiService.signupComplete(
        name: name,
        email: email,
        phone: phone,
        firebaseUid: uc.user!.uid,
      );

      if (res['success'] == true && context.mounted) {
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        final expenseProvider = Provider.of<ExpenseProvider>(
          context,
          listen: false,
        );
        await Provider.of<UserProviders>(
          context,
          listen: false,
        ).setAuthenticated(
          res['user'],
          res['token'],
          groupProvider,
          expenseProvider,
        );

        ConnectivityService.instance.startWatching(groupProvider);
        showSnackBar(context, 'Account Created!');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      } else if (context.mounted) {
        showSnackBar(context, res['message'] ?? 'Signup failed');
      }
    } catch (e) {
      if (context.mounted) showSnackBar(context, e.toString());
    }
  }

  Future<void> verifyOtpAndHandleUserSignin({
    required BuildContext context,
    required String verificationId,
    required String otp,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final uc = await _auth.signInWithCredential(cred);
      if (uc.user == null) {
        showSnackBar(context, 'Auth Failed');
        return;
      }
      final res = await ApiService.loginComplete(firebaseUid: uc.user!.uid);

      if (res['success'] == true && context.mounted) {
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );
        final expenseProvider = Provider.of<ExpenseProvider>(
          context,
          listen: false,
        );
        await Provider.of<UserProviders>(
          context,
          listen: false,
        ).setAuthenticated(
          res['user'],
          res['token'],
          groupProvider,
          expenseProvider,
        );

        ConnectivityService.instance.startWatching(groupProvider);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      } else if (context.mounted) {
        showSnackBar(context, res['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (context.mounted) showSnackBar(context, e.toString());
    }
  }

  Future<void> signOut(BuildContext context) async {
    ConnectivityService.instance.stopWatching();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    await Provider.of<UserProviders>(
      context,
      listen: false,
    ).logout(groupProvider, expenseProvider);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
    }
  }
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/api/api_controller.dart';
// import 'package:splitzon/core/utils/otp_screen.dart';
// import 'package:splitzon/core/utils/otp_screen_login.dart';
// import 'package:splitzon/core/widgets/show_snack_bar.dart';
// import 'package:splitzon/provider/user_providers.dart';
// import 'package:splitzon/providers/group_provider.dart';
// import 'package:splitzon/services/connectivity_service.dart';

// class FirebaseAuthMethods {
//   final FirebaseAuth _auth;
//   FirebaseAuthMethods(this._auth);

//   /// SEND OTP (SIGNUP)
//   Future<void> sendOtp({
//     required BuildContext context,
//     required String name,
//     required String email,
//     required String phone,
//     required bool rememberMe,
//   }) async {
//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         verificationCompleted: (credential) async {
//           await _auth.signInWithCredential(credential);
//         },
//         verificationFailed: (e) {
//           showSnackBar(context, e.message ?? "OTP Failed");
//         },
//         codeSent: (verificationId, _) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OtpScreen(
//                 name: name,
//                 email: email,
//                 phone: phone,
//                 verificationId: verificationId,
//                 rememberMe: rememberMe,
//               ),
//             ),
//           );
//         },
//         codeAutoRetrievalTimeout: (_) {},
//       );
//     } catch (e) {
//       showSnackBar(context, e.toString());
//     }
//   }

//   /// SEND OTP (LOGIN)
//   Future<void> sendOtpLogin({
//     required BuildContext context,
//     required String phone,
//     required bool rememberMe,
//   }) async {
//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         verificationCompleted: (credential) async {
//           await _auth.signInWithCredential(credential);
//         },
//         verificationFailed: (e) {
//           showSnackBar(context, e.message ?? "OTP Failed");
//         },
//         codeSent: (verificationId, _) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OtpScreenLogin(
//                 phone: phone,
//                 verificationId: verificationId,
//                 rememberMe: rememberMe,
//               ),
//             ),
//           );
//         },
//         codeAutoRetrievalTimeout: (_) {},
//       );
//     } catch (e) {
//       showSnackBar(context, e.toString());
//     }
//   }

//   /// VERIFY OTP (SIGNUP)
//   Future<void> verifyOtpAndHandleUser({
//     required BuildContext context,
//     required String verificationId,
//     required String otp,
//     required String name,
//     required String email,
//     required String phone,
//     required bool rememberMe,
//   }) async {
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: otp,
//       );

//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;

//       if (user == null) {
//         showSnackBar(context, "Auth Failed");
//         return;
//       }

//       final res = await ApiService.signupComplete(
//         name: name,
//         email: email,
//         phone: phone,
//         firebaseUid: user.uid,
//       );

//       debugPrint("📦 Signup Response: $res");

//       if (res["success"] == true) {
//         if (context.mounted) {
//           final userProvider =
//               Provider.of<UserProviders>(context, listen: false);
//           final groupProvider =
//               Provider.of<GroupProvider>(context, listen: false);

//           await userProvider.setAuthenticated(
//             res["user"],
//             res["token"],
//             groupProvider,
//           );

//           // ✅ Start watching connectivity after login
//           ConnectivityService.instance.startWatching(groupProvider);

//           showSnackBar(context, "Account Created!");
//           Navigator.pushNamedAndRemoveUntil(
//               context, "/home", (route) => false);
//         }
//       } else {
//         if (context.mounted) {
//           showSnackBar(context, res["message"] ?? "Signup failed");
//         }
//       }
//     } catch (e) {
//       debugPrint("🔥 OTP Error: $e");
//       if (context.mounted) showSnackBar(context, e.toString());
//     }
//   }

//   /// VERIFY OTP (LOGIN)
//   Future<void> verifyOtpAndHandleUserSignin({
//     required BuildContext context,
//     required String verificationId,
//     required String otp,
//     required String phone,
//     required bool rememberMe,
//   }) async {
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: otp,
//       );

//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;

//       if (user == null) {
//         showSnackBar(context, "Auth Failed");
//         return;
//       }

//       final res = await ApiService.loginComplete(firebaseUid: user.uid);

//       debugPrint("📦 Login Response: $res");

//       if (res["success"] == true) {
//         if (context.mounted) {
//           final userProvider =
//               Provider.of<UserProviders>(context, listen: false);
//           final groupProvider =
//               Provider.of<GroupProvider>(context, listen: false);

//           await userProvider.setAuthenticated(
//             res["user"],
//             res["token"],
//             groupProvider,
//           );

//           // ✅ Start watching connectivity after login
//           ConnectivityService.instance.startWatching(groupProvider);

//           Navigator.pushNamedAndRemoveUntil(
//               context, "/home", (route) => false);
//         }
//       } else {
//         if (context.mounted) {
//           showSnackBar(context, res["message"] ?? "Login failed");
//         }
//       }
//     } catch (e) {
//       debugPrint("🔥 Login OTP Error: $e");
//       if (context.mounted) showSnackBar(context, e.toString());
//     }
//   }

//   /// LOGOUT
//   Future<void> signOut(BuildContext context) async {
//     final groupProvider =
//         Provider.of<GroupProvider>(context, listen: false);

//     // ✅ Stop watching connectivity on logout
//     ConnectivityService.instance.stopWatching();

//     await Provider.of<UserProviders>(context, listen: false)
//         .logout(groupProvider);

//     if (context.mounted) {
//       Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
//     }
//   }
// }

