import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
// Make sure this path is correct based on your folder structure
import 'screens/onboarding/onboarding_screen.dart';

void main() {
  runApp(const VintyApp());
}

class VintyApp extends StatelessWidget {
  const VintyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vinty',
      theme: ThemeData(
        textTheme: GoogleFonts.syneTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
      ),
      // FIXED: Point to SplashScreen (or OnboardingScreen), NOT VintyApp
      home: const SplashScreen(),
    );
  }
}

// Ensure your SplashScreen class is either below here or imported!
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("VINTY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      ),
    );
  }
}