import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  // We use dynamic here to satisfy the Dart compiler's flexibility requirements
  final List<Map<String, dynamic>> onboardingData = [
    {
      "image": "https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=1000",
      "title": "GIVE FASHION\nA SECOND LIFE",
      "subtitle": "Join the movement. Buy and sell unique pieces while helping the planet stay sustainable.",
    },
    {
      "image": "https://images.unsplash.com/photo-1523381210434-271e8be1f52b?q=80&w=1000",
      "title": "DISCOVER YOUR\nOWN AESTHETIC",
      "subtitle": "Find vintage, Y2K, and hidden streetwear gems curated specifically for your vibe.",
    },
    {
      "image": "https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?q=80&w=1000",
      "title": "SWIPE, SAVE,\nAND SHOP",
      "subtitle": "Build your dream closet with our interactive swipe feed and personalized picks.",
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. TOP IMAGE SECTION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (context, index) {
                // Safely extract the image string
                final String imagePath = onboardingData[index]["image"]?.toString() ?? "";

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: DecorationImage(
                      image: NetworkImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. SKIP BUTTON
          Positioned(
            top: 60,
            right: 25,
            child: TextButton(
              onPressed: () => _navigateToLogin(),
              child: Text(
                "SKIP",
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2,
                  shadows: [const Shadow(blurRadius: 10, color: Colors.black45)],
                ),
              ),
            ),
          ),

          // 3. BOTTOM CONTENT CARD
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingData.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: currentPage == index ? Colors.black : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 35),

                  // CONTENT WRAPPER
                  Expanded(
                    child: Column(
                      children: [
                        // Safe conversion to String for Text widgets
                        Text(
                          onboardingData[currentPage]["title"]?.toString() ?? "WELCOME",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          onboardingData[currentPage]["subtitle"]?.toString() ?? "",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PRIMARY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        if (currentPage < onboardingData.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                          );
                        } else {
                          _navigateToLogin();
                        }
                      },
                      child: Text(
                        currentPage == onboardingData.length - 1 ? "GET STARTED" : "CONTINUE",
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}