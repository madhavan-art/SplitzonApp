import 'package:flutter/material.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_theme.dart';
import 'package:splitzon/core/widgets/app_branding.dart';
import 'package:splitzon/core/widgets/app_details.dart';
import 'package:splitzon/core/widgets/primary_button.dart';
import 'package:splitzon/features/onboarding/onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingController _controller = OnboardingController();

  @override
  void initState() {
    super.initState();
    _controller.init(this);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundTheme(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
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

                      // AppLoader(),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              /// Page Indicator
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 30),

              /// Get Started Button
              PrimaryButton(
                onPressed: () {
                  // Navigator.pushReplacementNamed(context, '/home');
                  Navigator.pushReplacementNamed(context, '/introduction01');
                },
                title: 'Get Started',
                icon: Icons.arrow_forward_ios_rounded,
              ),

              const SizedBox(height: 18),

              /// Security Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    "SECURED BY ZENCLOUD",
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// Footer
              AppBranding(),
            ],
          ),
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
