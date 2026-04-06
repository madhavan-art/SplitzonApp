import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/widgets/app_branding.dart';
import 'package:splitzon/core/widgets/app_details.dart';
import 'package:splitzon/core/widgets/app_loader.dart';
import 'package:splitzon/features/splash/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final SplashController _controller = SplashController();
  @override
  void initState() {
    super.initState();
    _controller.init(this, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// Soft Gradient Background
            Container(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            ),

            /// Floating Glow Shapes
            Positioned(
              top: -60,
              left: -40,
              child: _blurCircle(
                200,
                const Color(0xFF4DA3FF).withOpacity(0.20),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -50,
              child: _blurCircle(
                225,
                const Color.fromARGB(255, 37, 94, 141).withOpacity(0.6),
              ),
            ),

            Column(
              children: [
                const Spacer(),

                FadeTransition(
                  opacity: _controller.fadeAnimation,
                  child: ScaleTransition(
                    scale: _controller.scaleAnimation,
                    child: Column(
                      children: [
                        /// Soft Gradient Logo Container
                        AppLogo(),

                        const SizedBox(height: 40),

                        /// App Name
                        AppName(),

                        const SizedBox(height: 14),

                        /// Subtitle
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Your reimagined ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Text(
                                  "fintech",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textHighlight,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "expense tracker.",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        AppLoader(),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                /// Cleaner Footer
                AppBranding(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
