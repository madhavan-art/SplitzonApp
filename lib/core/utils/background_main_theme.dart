import 'package:flutter/material.dart';
import 'package:splitzon/core/constants/app_colors.dart';

class BackgroundMainTheme extends StatelessWidget {
  final Widget child;
  const BackgroundMainTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(.2),
            ),
          ),

          child,
        ],
      ),
    );
  }
}
