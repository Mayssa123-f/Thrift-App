import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isObscure = true;

  // Consistent input decoration helper
  InputDecoration _inputStyle(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.darkGray, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Back Button for better UX
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(height: 30),

              Text(
                "Create\nNew Account",
                style: GoogleFonts.syne(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Join the sustainable fashion movement.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.darkGray,
                ),
              ),

              const SizedBox(height: 40),

              // NAME FIELD
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(),
                decoration: _inputStyle("Full Name"),
              ),

              const SizedBox(height: 16),

              // EMAIL FIELD
              TextField(
                controller: emailController,
                style: GoogleFonts.inter(),
                decoration: _inputStyle("Email Address"),
              ),

              const SizedBox(height: 16),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: isObscure,
                style: GoogleFonts.inter(),
                decoration: _inputStyle(
                  "Password",
                  suffix: IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.darkGray,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isObscure = !isObscure),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black, // High-contrast black button
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // Logic for account creation later
                  },
                  child: Text(
                    "Create Account",
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // FOOTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: GoogleFonts.inter(color: AppColors.darkGray),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Login",
                      style: GoogleFonts.syne(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}