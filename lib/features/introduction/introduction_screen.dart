import 'package:flutter/material.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_theme.dart';
import 'package:splitzon/core/widgets/app_details.dart';
import 'package:splitzon/core/widgets/primary_button.dart';

class IntroductionScreen01 extends StatefulWidget {
  const IntroductionScreen01({super.key});

  @override
  State<IntroductionScreen01> createState() => _IntroductionScreen01State();
}

class _IntroductionScreen01State extends State<IntroductionScreen01> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  final List<IntroData> introList = [
    IntroData(
      title: "Harmony in Every Split",
      subtitle: "Modern finance for real-life moments.",
      icon: Icons.swap_horiz_sharp,
    ),
    IntroData(
      title: "Effortless Tracking",
      subtitle: "Real-time tracking. Zero confusion. Stress free.",
      icon: Icons.manage_history_rounded,
    ),
    IntroData(
      title: "Clear. Confirmed. Complete.",
      subtitle: "Bring every shared expense back to zero.",
      icon: Icons.verified_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BackgroundTheme(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              /// PAGE VIEW
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: introList.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = introList[index];

                    return Column(
                      children: [
                        const Spacer(),
                        const Spacer(),

                        /// CARD SECTION
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              /// MAIN CARD
                              Container(
                                height: 220,
                                width: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.95),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.08),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      /// BRAND + BADGE
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const AppNameIntro(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                width: 1,
                                                color: Colors.blue.withOpacity(
                                                  .3,
                                                ),
                                              ),
                                            ),
                                            child: const Text(
                                              "Active Bill",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      /// ICON BOX
                                      Container(
                                        height: 80,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2563EB),
                                              Color(0xFF1E40AF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Icon(
                                          data.icon,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),

                                      const Spacer(),

                                      /// AMOUNT
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const [
                                          Icon(
                                            Icons.currency_rupee,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          Text(
                                            '300.00',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// TOP BADGE
                              Positioned(
                                top: -38,
                                right: -20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.05),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Settled",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// BOTTOM BADGE
                              Positioned(
                                bottom: 10,
                                left: -20,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    /// Badge Row
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  .05,
                                                ),
                                                blurRadius: 15,
                                              ),
                                            ],
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.auto_awesome,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "Magic Split",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // const SizedBox(width: 10),
                                        SizedBox(
                                          width: 70,
                                          height: 30,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              /// First Profile
                                              Positioned(
                                                left: 0,
                                                child: _profileAvatar(
                                                  "assets/profile1.webp",
                                                ),
                                              ),

                                              /// Second Profile
                                              Positioned(
                                                left: 20,
                                                child: _profileAvatar(
                                                  "assets/profile2.jpg",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 60),

                        /// TITLE + SUBTITLE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),

              /// DOTS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  introList.length,
                  (index) => _dot(index == currentIndex),
                ),
              ),

              const SizedBox(height: 24),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  title: currentIndex == introList.length - 1
                      ? "Get Started"
                      : "Next",
                  icon: Icons.navigate_next_sharp,
                  onPressed: () {
                    if (currentIndex < introList.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 6),
      height: 6,
      width: active ? 22 : 6,
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.blue.withOpacity(.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class IntroData {
  final String title;
  final String subtitle;
  final IconData icon;

  IntroData({required this.title, required this.subtitle, required this.icon});
}

Widget _blurCircle(double size, Color color) {
  return Container(
    height: size,
    width: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

Widget _profileAvatar(String imagePath) {
  return Container(
    height: 30,
    width: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 6),
      ],
    ),
  );
}
