import 'package:flutter/material.dart';
import 'package:splitzon/core/constants/app_colors.dart';

class BackgroundTheme extends StatelessWidget {
  final Widget child;
  const BackgroundTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),

          /// Soft Glow Circles
          Positioned(
            top: -60,
            left: -40,
            child: _blurCircle(200, const Color(0xFF4DA3FF).withOpacity(0.20)),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: _blurCircle(225, const Color(0xFF1E88E5).withOpacity(0.25)),
          ),
          child,
        ],
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
