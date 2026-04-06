import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart'; // adjust path if needed

class AppBranding extends StatelessWidget {
  final String version;

  const AppBranding({super.key, this.version = "1.0"});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Powered by ",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBrand,
              ),
            ),
            Image.asset('assets/trisentrix_logo.png', height: 22),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Version $version",
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textVersion,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
