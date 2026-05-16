import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../data/app_data.dart';
import '../../services/listing_service.dart';
import '../favorites/favorites_screen.dart';
import '../cart/cart_screen.dart';
import '../editProfile/edit_profile_screen.dart';
import '../paymentAndCheckout/payments_payouts_screen.dart';
import '../help/help_support.dart';
import '../notifications/notifications_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isSellerMode = true;
  final AuthController authController = AuthController();

  UserModel? currentUser;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await authController.getProfile();

      if (!mounted) return;

      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'MY VINTY',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileHeader(),
                  const SizedBox(height: 25),
                  _buildModeToggle(),
                  const SizedBox(height: 28),
                  _buildDashboardLabel(),
                  const SizedBox(height: 14),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _sectionLabel('ACCOUNT'),
                  const SizedBox(height: 12),
                  _menuItem(
                    Icons.favorite_outline_rounded,
                    'My Wishlist',
                    '${AppData.favorites.length} items',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    ),
                  ),
                  _menuItem(
                    Icons.shopping_bag_outlined,
                    'My Cart',
                    '${AppData.cart.length} items',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                  _menuItem(
                    Icons.inventory_2_outlined,
                    'My Listings',
                    '${ListingService.all.length} active',
                    () {},
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('SETTINGS'),
                  const SizedBox(height: 12),
                  _menuItem(
                    Icons.person_outline_rounded,
                    'Edit Profile',
                    '',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    Icons.credit_card_outlined,
                    'Payments & Payouts',
                    '',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentsPayoutsScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    Icons.help_outline_rounded,
                    'Help & Support',
                    '',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          height: 78,
          width: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
            image:
                currentUser?.profileImageUrl != null &&
                    currentUser!.profileImageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(currentUser!.profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child:
              currentUser?.profileImageUrl == null ||
                  currentUser!.profileImageUrl!.isEmpty
              ? const Icon(Icons.person, size: 35, color: Colors.grey)
              : null,
        ),

        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.fullName ?? 'User',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentUser?.role == 'seller'
                    ? 'Verified Seller'
                    : 'Casual Shopper',
                style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleBtn('Buyer', !isSellerMode),
          _toggleBtn('Seller', isSellerMode),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isSellerMode = (text == 'Seller')),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.syne(
                color: active ? Colors.white : Colors.black45,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSellerMode ? 'SELLER DASHBOARD' : 'BUYER ACTIVITY',
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = isSellerMode
        ? [
            {'label': 'Listings', 'value': '${ListingService.all.length}'},
            {'label': 'Sales', 'value': '28'},
            {'label': 'Views', 'value': '340'},
          ]
        : [
            {'label': 'Saved', 'value': '${AppData.favorites.length}'},
            {'label': 'Cart', 'value': '${AppData.cart.length}'},
            {'label': 'Orders', 'value': '5'},
          ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s == stats.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Text(
                  s['value']!,
                  style: GoogleFonts.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s['label']!.toUpperCase(),
                  style: GoogleFonts.syne(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.black38,
        letterSpacing: 1,
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await authController.logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'LOGOUT',
            style: GoogleFonts.syne(
              color: Colors.red,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
