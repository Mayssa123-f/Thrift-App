import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          "NOTIFICATIONS",
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Clear all",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader("TODAY"),
          _buildNotificationItem(
            icon: Icons.local_shipping_outlined,
            title: "Package Shipped!",
            description: "Your vintage Chanel Bag has passed verification and is on its way.",
            time: "2h ago",
            isUnread: true,
          ),
          _buildNotificationItem(
            icon: Icons.favorite_outline_rounded,
            title: "Price Drop Alert",
            description: "An item in your wishlist 'Streetwear Hoodie' is now 15% off.",
            time: "5h ago",
            isUnread: true,
          ),
          const SizedBox(height: 25),
          _buildSectionHeader("YESTERDAY"),
          _buildNotificationItem(
            icon: Icons.account_balance_wallet_outlined,
            title: "Payout Successful",
            description: "Funds totaling \$450.00 have been successfully deposited into your account.",
            time: "1d ago",
            isUnread: false,
          ),
          _buildNotificationItem(
            icon: Icons.star_outline_rounded,
            title: "New 5-Star Review",
            description: "Mayssa, a buyer left a review: 'Amazing quality, accurately described!'",
            time: "1d ago",
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 5),
      child: Text(
        title,
        style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? Colors.transparent : Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnread ? Colors.black : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isUnread ? Colors.white : Colors.black, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(time, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}