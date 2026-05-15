import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart'; // Ensure this matches your path
import 'register_screen.dart'; // ✅ IMPORTANT: Import your RegisterScreen file
import '../main/main_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isObscure = true;

  InputDecoration _inputStyle(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
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
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 30),
              ),

              const SizedBox(height: 30),

              Text(
                "Welcome back to\nVinty Market",
                style: GoogleFonts.syne(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                style: GoogleFonts.inter(),
                decoration: _inputStyle("Email Address"),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: isObscure,
                style: GoogleFonts.inter(),
                decoration: _inputStyle(
                  "Password",
                  suffix: IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => isObscure = !isObscure),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  child: Text(
                    "Sign In",
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "New to Vinty?",
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      // ✅ NAVIGATION LINKED HERE
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      "Create Account",
                      style: GoogleFonts.syne(
                        color: Colors.black,
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