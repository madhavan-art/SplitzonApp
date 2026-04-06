import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E88E5);
  static const secondary = Color(0xFF4DA3FF);

  // Background
  static final backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFFEAF4FF).withOpacity(0.6),
      const Color(0xFFD6EBFF).withOpacity(0.6),
      const Color(0xFFB9DCFF).withOpacity(0.6),
    ],
  );
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF4DA3FF), Color(0xFF1E88E5)],
  );

  // Text
  static const textPrimary = Color(0xFF1E3A8A);
  static final textSecondary = Color(0xFF1E3A8A).withOpacity(0.5);
  static const textHighlight = Colors.orange;
  static const textBrand = const Color(0xFF1A365D);
  static final textVersion = Color(0xFF1A365D).withOpacity(.7);
}
