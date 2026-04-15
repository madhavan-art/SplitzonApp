// ════════════════════════════════════════════════════════════════
// FILE: lib/features/splash/splash_controller.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'package:splitzon/providers/group_provider.dart';
import 'package:splitzon/services/connectivity_service.dart';

class SplashController {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  void init(TickerProvider vsync, BuildContext context) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    );
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );
    scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );
    animationController.forward();
    _checkAuthAndNavigate(context);
  }

  Future<void> _checkAuthAndNavigate(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!context.mounted) return;

    final userProvider = Provider.of<UserProviders>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final isLoggedIn = await userProvider.initAuth(
      groupProvider,
      expenseProvider,
    );

    if (!context.mounted) return;

    if (isLoggedIn) {
      ConnectivityService.instance.startWatching(groupProvider);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
    }
  }

  void dispose() => animationController.dispose();
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:splitzon/provider/user_providers.dart';
// import 'package:splitzon/providers/group_provider.dart';
// import 'package:splitzon/services/connectivity_service.dart';

// class SplashController {
//   late AnimationController animationController;
//   late Animation<double> fadeAnimation;
//   late Animation<double> scaleAnimation;

//   void init(TickerProvider vsync, BuildContext context) {
//     animationController = AnimationController(
//       vsync: vsync,
//       duration: const Duration(milliseconds: 1000),
//     );

//     fadeAnimation = CurvedAnimation(
//       parent: animationController,
//       curve: Curves.easeIn,
//     );

//     scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
//       CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
//     );

//     animationController.forward();
//     _checkAuthAndNavigate(context);
//   }

//   Future<void> _checkAuthAndNavigate(BuildContext context) async {
//     await Future.delayed(const Duration(milliseconds: 2500));

//     if (!context.mounted) return;

//     final userProvider = Provider.of<UserProviders>(context, listen: false);
//     final groupProvider = Provider.of<GroupProvider>(context, listen: false);

//     final isLoggedIn = await userProvider.initAuth(groupProvider);

//     if (!context.mounted) return;

//     if (isLoggedIn) {
//       // ✅ PRINT USER DETAILS

//       print("========== USER SESSION ==========");

//       print("User ID: ${userProvider.user?.id}");
//       print("Name: ${userProvider.user?.name}");
//       print("Email: ${userProvider.user?.email}");
//       print("Phone: ${userProvider.user?.phone}");

//       // If token is stored decrypted in memory
//       print("Token (decrypted): ${userProvider.token}");

//       print("Is Logged In: $isLoggedIn");

//       print("==================================");
//       // ✅ Session restored — restart connectivity watcher
//       // so any groups created offline while app was closed also get synced
//       ConnectivityService.instance.startWatching(groupProvider);

//       Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
//     } else {
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         '/onboarding',
//         (route) => false,
//       );
//     }
//   }

//   void dispose() {
//     animationController.dispose();
//   }
// }
