// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:splitzon/features/onboarding/onboarding_screen.dart';

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

//     _navigateToOnboarding(context);
//   }

//   Future<void> _navigateToOnboarding(BuildContext context) async {
//     await Future.delayed(const Duration(milliseconds: 2500));

//     if (context.mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const OnboardingScreen()),
//       );
//     }
//   }

//   void dispose() {
//     animationController.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/provider/user_providers.dart';

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

    // ✅ Check auth while animation plays
    _checkAuthAndNavigate(context);
  }

  Future<void> _checkAuthAndNavigate(BuildContext context) async {
    // Wait for splash animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!context.mounted) return;

    // ✅ Check SharedPreferences for saved session
    final provider = Provider.of<UserProviders>(context, listen: false);
    final isLoggedIn = await provider.initAuth();

    if (!context.mounted) return;

    if (isLoggedIn) {
      // ✅ User session found → skip login → go home
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      // ❌ No session → go to onboarding as usual
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding',
        (route) => false,
      );
    }
  }

  void dispose() {
    animationController.dispose();
  }
}
