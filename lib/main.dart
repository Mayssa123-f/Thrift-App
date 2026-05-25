import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/firebase_options.dart';
import 'package:thrift_app/services/notification_service.dart';

import 'constants/app_colors.dart';
import 'controllers/auth_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'utils/token_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey =
      'pk_test_51SYN6qE1McKnxFJ4dxJLzOfbO4MAao7AOjzQ4OuRmQMBQkPvQuR6P4fBK8u1eSZMREWIfZPZMG6C3xyphsKt2Jai00ppiVlomu';

  await Stripe.instance.applySettings();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen>
    with TickerProviderStateMixin {
  final AuthController authController = AuthController();

  late AnimationController _introController;
  late AnimationController _moveController;

  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService().initNotifications();
  });
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);

    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _shake = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _checkAuth();
  }

  Future<void> _goTo(Widget screen) async {
    final token = await FirebaseMessaging.instance.getToken();

    print("FCM TOKEN:");
    print(token);
    await Future.delayed(const Duration(milliseconds: 2300));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
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
    _introController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: AnimatedBuilder(
                animation: _moveController,
                builder: (context, child) {
                  final verticalMove = -6 + (_moveController.value * 12);

                  final breathingScale = 1 + (_moveController.value * 0.018);

                  return Transform.translate(
                    offset: Offset(0, verticalMove),
                    child: Transform.scale(scale: breathingScale, child: child),
                  );
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "VINTY",
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 94,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
