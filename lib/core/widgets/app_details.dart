import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitzon/core/constants/app_colors.dart';

class AppName extends StatelessWidget {
  const AppName({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "S",
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        ),
        Text(
          "plitzon",
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppNameIntro extends StatelessWidget {
  const AppNameIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "S",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.textPrimary,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        ),
        Text(
          "plitzon",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
            // shadows: [
            //   Shadow(
            //     color: Colors.black.withOpacity(0.25),
            //     blurRadius: 30,
            //     offset: const Offset(0, 18),
            //   ),
            // ],
          ),
        ),
      ],
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4DA3FF), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}
