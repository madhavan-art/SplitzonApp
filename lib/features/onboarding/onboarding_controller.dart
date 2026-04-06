import 'package:flutter/material.dart';

class OnboardingController {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  void init(TickerProvider vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );

    fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(controller);
    scaleAnimation = Tween(begin: 0.9, end: 1.0).animate(controller);

    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }
}
