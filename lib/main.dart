import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'package:thrift_app/firebase_options.dart';
import 'package:thrift_app/services/notification_service.dart';

import 'constants/app_colors.dart';
import 'controllers/auth_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'utils/token_storage.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey =
      'pk_test_51SYN6qE1McKnxFJ4dxJLzOfbO4MAao7AOjzQ4OuRmQMBQkPvQuR6P4fBK8u1eSZMREWIfZPZMG6C3xyphsKt2Jai00ppiVlomu';

  await Stripe.instance.applySettings();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const VintyApp());
}

class VintyApp extends StatelessWidget {
  const VintyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Vinty',
      theme: ThemeData(
        textTheme: GoogleFonts.syneTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() =>
      _AuthCheckScreenState();
}

class _AuthCheckScreenState
    extends State<AuthCheckScreen> {
  final AuthController authController =
      AuthController();

  late VideoPlayerController _videoController;

  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().initNotifications();
    });

    _initializeVideo();

    _checkAuth();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/splash.mp4',
    );

    await _videoController.initialize();

    await _videoController.setLooping(false);

    await _videoController.play();

    if (!mounted) return;

    setState(() {
      _videoReady = true;
    });
  }

  Future<void> _goTo(Widget screen) async {
    final token =
        await FirebaseMessaging.instance.getToken();

    print("FCM TOKEN:");
    print(token);

    await Future.delayed(
      const Duration(milliseconds: 6700),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 600),

        pageBuilder: (_, animation, __) => screen,

        transitionsBuilder:
            (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _checkAuth() async {
    final token = await TokenStorage.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      await _goTo(const OnboardingScreen());
      return;
    }

    try {
      await authController.getProfile();

      if (!mounted) return;

      await NotificationService().saveFcmToken();

      await _goTo(const MainScreen());
    } catch (_) {
      await TokenStorage.clearToken();

      if (!mounted) return;

      await _goTo(const LoginScreen());
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SizedBox.expand(
        child: _videoReady
            ? FittedBox(
                fit: BoxFit.cover,

                child: SizedBox(
                  width:
                      _videoController.value.size.width,

                  height:
                      _videoController.value.size.height,

                  child: VideoPlayer(
                    _videoController,
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}