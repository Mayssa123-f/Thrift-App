import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentsPayoutsScreen extends StatelessWidget {
  const PaymentsPayoutsScreen({super.key});

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
          "PAYMENTS & PAYOUTS",
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💰 WALLET BALANCE CARD
            _buildBalanceCard(),

            const SizedBox(height: 40),

            // 💳 SAVED METHODS
            _sectionHeader("SAVED PAYMENT METHODS"),
            const SizedBox(height: 15),
            _buildPaymentMethod(Icons.credit_card, "Visa ending in 4242", "Exp 12/26"),
            _buildPaymentMethod(Icons.apple, "Apple Pay", "Default Method"),

            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18, color: Colors.blue),
              label: Text("Add new method", style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 40),

            // 📜 TRANSACTION HISTORY
            _sectionHeader("RECENT TRANSACTIONS"),
            const SizedBox(height: 15),
            _buildTransaction("Vintage Chanel Bag", "+\$450.00", "Payout", true),
            _buildTransaction("Streetwear Hoodie", "-\$85.00", "Purchase", false),
            _buildTransaction("Levi's 501", "+\$60.00", "Payout", true),
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

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vinty Balance", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("\$1,240.50", style: GoogleFonts.syne(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {}, // Payout logic
              child: Text("CASH OUT", style: GoogleFonts.syne(color: Colors.black, fontWeight: FontWeight.w800)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTransaction(String title, String amount, String type, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                Text(type, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: isPositive ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}