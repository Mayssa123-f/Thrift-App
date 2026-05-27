import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/google_auth_botton.dart';
import '../main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthController authController = AuthController();

  bool isObscure = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(
    String hint, {
    Widget? suffix,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: Colors.grey.shade500,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.black,
          width: 1.2,
        ),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
    );
  }

  Future<void> _register() async {
    setState(() => isLoading = true);

    try {
      await authController.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _googleRegister() async {
    setState(() => isLoading = true);

    try {
      await authController.continueWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/vinty_login_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                30,
                15,
                30,
                24,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// TOP SECTION
                  _buildBrandHeader(),

                  const SizedBox(height: 135),

                  /// REGISTER CARD
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildRegisterCard(),
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

  Widget _buildBrandHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VINTY',
          style: GoogleFonts.syne(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'THRIFT IT.\nSTYLE IT.\nLOVE IT.',
          style: GoogleFonts.inter(
            fontSize: 11,
            height: 1.8,
            letterSpacing: 4,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Account',
          style: GoogleFonts.ibmPlexSerif(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Join the sustainable fashion movement.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: const Color(0xFF6F6258),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 22),

        /// NAME
        TextField(
          controller: nameController,
          decoration: _inputStyle(
            'Full Name',
            prefix: const Icon(
              Icons.person_outline_rounded,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 14),

        /// EMAIL
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputStyle(
            'Email Address',
            prefix: const Icon(
              Icons.mail_outline_rounded,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 14),

        /// PASSWORD
        TextField(
          controller: passwordController,
          obscureText: isObscure,
          decoration: _inputStyle(
            'Password',
            prefix: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
            ),
            suffix: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () {
                setState(() => isObscure = !isObscure);
              },
            ),
          ),
        ),

        const SizedBox(height: 26),

        /// CREATE BUTTON
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _register,

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.syne(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 22),

        /// DIVIDER
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey.shade300),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),

              child: Text(
                'OR',
                style: GoogleFonts.inter(
                  color: const Color(0xFF7A604C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Expanded(
              child: Divider(color: Colors.grey.shade300),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// GOOGLE BUTTON
        GoogleAuthButton(
          isLoading: isLoading,
          onPressed: _googleRegister,
        ),

        const SizedBox(height: 28),

        /// LOGIN TEXT
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: GoogleFonts.inter(
                color: const Color(0xFF6F6258),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),

              child: Text(
                'Sign In',
                style: GoogleFonts.syne(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}