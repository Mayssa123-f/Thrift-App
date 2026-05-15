import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "HELP & SUPPORT",
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 SEARCH BAR
            TextField(
              decoration: InputDecoration(
                hintText: "How can we help?",
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 35),

            // ⚡ QUICK TOPICS
            _sectionHeader("TOP TOPICS"),
            const SizedBox(height: 15),
            _buildSupportTile("Buying on Vinty", Icons.shopping_bag_outlined),
            _buildSupportTile("Selling & Payouts", Icons.sell_outlined),
            _buildSupportTile("Shipping & Tracking", Icons.local_shipping_outlined),
            _buildSupportTile("Refunds & Returns", Icons.assignment_return_outlined),

            const SizedBox(height: 40),

            // 💬 CONTACT SECTION
            _sectionHeader("STILL NEED HELP?"),
            const SizedBox(height: 20),
            _buildContactCard(
              context,
              "Chat with Us",
              "Average response: 5 mins",
              Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              "Email Support",
              "Response within 24 hours",
              Icons.email_outlined,
            ),

            const SizedBox(height: 50),
            Center(
              child: Text(
                "Version 1.0.4",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1),
    );
  }

  Widget _buildSupportTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: 20),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}