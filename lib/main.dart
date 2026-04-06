import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/features/auth/auth_screen.dart';
import 'package:splitzon/features/auth/login_screen.dart';
import 'package:splitzon/features/home/home_screen.dart';
import 'package:splitzon/features/introduction/introduction_screen.dart';
import 'package:splitzon/features/onboarding/onboarding_screen.dart';
import 'package:splitzon/features/splash/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProviders())],
      child: const MyApp(),
    ),
  );
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitzon',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(), // ✅ Inter for entire app
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/introduction01': (context) => const IntroductionScreen01(),
        '/auth': (context) => const AuthenticationScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
