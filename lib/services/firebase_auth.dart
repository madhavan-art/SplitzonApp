import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/api/api_controller.dart';
import 'package:splitzon/core/utils/otp_screen.dart';
import 'package:splitzon/core/utils/otp_screen_login.dart';
import 'package:splitzon/core/widgets/show_snack_bar.dart';
import 'package:splitzon/provider/user_providers.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;
  FirebaseAuthMethods(this._auth);

  /// SEND OTP (SIGNUP)
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
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          showSnackBar(context, e.message ?? "OTP Failed");
        },
        codeSent: (verificationId, _) {
          Navigator.push(
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
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  /// SEND OTP (LOGIN) ← this was missing!
  Future<void> sendOtpLogin({
    required BuildContext context,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          showSnackBar(context, e.message ?? "OTP Failed");
        },
        codeSent: (verificationId, _) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreenLogin(
                phone: phone,
                verificationId: verificationId,
                rememberMe: rememberMe,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  /// VERIFY OTP (SIGNUP)
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
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user == null) {
        showSnackBar(context, "Auth Failed");
        return;
      }

      final res = await ApiService.signupComplete(
        name: name,
        email: email,
        phone: phone,
        firebaseUid: user.uid,
      );

      print("📦 Signup Response: $res");

      if (res["success"] == true) {
        if (context.mounted) {
          await Provider.of<UserProviders>(
            context,
            listen: false,
          ).setAuthenticated(res["user"]);

          showSnackBar(context, "Account Created!");
          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, res["message"] ?? "Signup failed");
        }
      }
    } catch (e) {
      print("🔥 OTP Error: $e");
      if (context.mounted) showSnackBar(context, e.toString());
    }
  }

  /// VERIFY OTP (LOGIN)
  Future<void> verifyOtpAndHandleUserSignin({
    required BuildContext context,
    required String verificationId,
    required String otp,
    required String phone,
    required bool rememberMe,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      if (user == null) {
        showSnackBar(context, "Auth Failed");
        return;
      }

      final res = await ApiService.loginComplete(firebaseUid: user.uid);

      print("📦 Login Response: $res");

      if (res["success"] == true) {
        if (context.mounted) {
          await Provider.of<UserProviders>(
            context,
            listen: false,
          ).setAuthenticated(res["user"]);

          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, res["message"] ?? "Login failed");
        }
      }
    } catch (e) {
      print("🔥 Login OTP Error: $e");
      if (context.mounted) showSnackBar(context, e.toString());
    }
  }

  /// LOGOUT
  Future<void> signOut(BuildContext context) async {
    await Provider.of<UserProviders>(context, listen: false).logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }
}
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:splitzon/api/api_controller.dart';
// import 'package:splitzon/core/utils/otp_screen.dart';
// import 'package:splitzon/core/utils/otp_screen_login.dart';
// import 'package:splitzon/core/widgets/show_snack_bar.dart';

// class FirebaseAuthMethods {
//   final FirebaseAuth _auth;

//   FirebaseAuthMethods(this._auth);

//   /// ===============================
//   /// SEND OTP (SIGNUP)
//   /// ===============================
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

//   /// ===============================
//   /// VERIFY OTP (SIGNUP)
//   /// ===============================
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

//       UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );

//       User? user = userCredential.user;

//       if (user == null) {
//         showSnackBar(context, "Auth Failed");
//         return;
//       }

//       print("✅ Firebase UID: ${user.uid}"); // ← add

//       /// 🔥 SAVE TO BACKEND (MongoDB)
//       final res = await ApiService.signupComplete(
//         name: name,
//         email: email,
//         phone: phone,
//         firebaseUid: user.uid,
//       );

//       print("📦 Response: $res"); // ← add

//       if (res["success"] == true) {
//         showSnackBar(context, "Account Created");

//         Navigator.pushNamedAndRemoveUntil(
//           context,
//           "/home",
//           (route) => false,
//           arguments: res["user"],
//         );
//       } else {
//         showSnackBar(context, res["message"] ?? "Something went wrong");
//       }
//     } catch (e) {
//       print("🔥 OTP Error: $e"); // ← add
//       showSnackBar(context, e.toString()); // ← show real error
//     }
//   }

//   /// ===============================
//   /// SEND OTP LOGIN
//   /// ===============================
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

//   /// ===============================
//   /// VERIFY OTP LOGIN
//   /// ===============================
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

//       UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );

//       User? user = userCredential.user;

//       if (user == null) {
//         showSnackBar(context, "Auth Failed");
//         return;
//       }

//       /// 🔥 FETCH USER FROM BACKEND
//       final res = await ApiService.loginComplete(firebaseUid: user.uid);

//       if (res["success"] == true) {
//         Navigator.pushNamedAndRemoveUntil(
//           context,
//           "/home",
//           (route) => false,
//           arguments: res["user"],
//         );
//       } else {
//         showSnackBar(context, res["message"]);
//       }
//     } catch (e) {
//       showSnackBar(context, "Invalid OTP");
//     }
//   }

//   /// LOGOUT
//   Future<void> signOut(BuildContext context) async {
//     await _auth.signOut();
//     // await GoogleSignIn().signOut();

//     Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
//   }
// }
