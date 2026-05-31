import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/screens/mylisting/my_listing_screen.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/controllers/product_controller.dart';
import 'package:thrift_app/screens/order/my_order_screen.dart';
import 'package:thrift_app/services/favorites_service.dart';
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
  final CartController cartController = CartController();
  final ProductController productController = ProductController();
  int profileTab = 0; // 0 = Dashboard, 1 = Details
  int wishlistCount = 0;
  int cartCount = 0;
  int listingsCount = 0;
  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAccountCounts();
  }

  Future<void> _loadAccountCounts() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      final cartItems = await cartController.getCartItems();
      final listings = await productController.getMyListings();

      if (!mounted) return;

      setState(() {
        wishlistCount = favorites.length;
        cartCount = cartItems.length;
        listingsCount = listings.where((p) => p.isAvailable).length;
      });
    } catch (_) {}
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

      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   title: Text(
      //     'MY VINTY',
      //     style: GoogleFonts.syne(
      //       fontWeight: FontWeight.w800,
      //       color: Colors.black,
      //       fontSize: 22,
      //       letterSpacing: -0.5,
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => const NotificationsScreen(),
      //           ),
      //         );
      //       },
      //       icon: const Icon(
      //         Icons.notifications_none_rounded,
      //         color: Colors.black,
      //       ),
      //     ),

      //     const SizedBox(width: 8),
      //   ],
      // ),
     body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildProfileTabs(),
            const SizedBox(height: 24),

            if (profileTab == 0) ...[
              _buildRevenueCard(),
              const SizedBox(height: 26),
              _sectionLabel('SELLER OVERVIEW'),
              const SizedBox(height: 12),
              _buildStatsRow(),
              const SizedBox(height: 28),
              _sectionLabel('QUICK ACTIONS'),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 28),
              _buildBoostCard(),
            ] else ...[
              _buildAccountDetails(),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildProfileTabs() {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        _profileTabButton('Dashboard', 0),
        _profileTabButton('Details', 1),
      ],
    ),
  );
}

Widget _profileTabButton(String text, int index) {
  final active = profileTab == index;

  return Expanded(
    child: GestureDetector(
      onTap: () => setState(() => profileTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.syne(
              color: active ? Colors.white : Colors.black45,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildRevenueCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Revenue',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\$2,450.00',
          style: GoogleFonts.syne(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '↑ 18% vs last month',
            style: GoogleFonts.inter(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 90,
          child: CustomPaint(
            painter: RevenueChartPainter(),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    ),
  );
}
Widget _buildAccountDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('ACCOUNT'),
      const SizedBox(height: 12),

      _menuItem(
        Icons.favorite_outline_rounded,
        'My Wishlist',
        '$wishlistCount items',
        () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
          _loadAccountCounts();
        },
      ),

      _menuItem(
        Icons.shopping_bag_outlined,
        'My Cart',
        '$cartCount items',
        () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
          _loadAccountCounts();
        },
      ),

      _menuItem(
        Icons.inventory_2_outlined,
        'My Listings',
        '$listingsCount active',
        () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyListingsScreen()),
          );
          _loadAccountCounts();
        },
      ),

      _menuItem(Icons.shopping_bag_outlined, 'My Orders', '', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        );
      }),

      const SizedBox(height: 20),
      _sectionLabel('SETTINGS'),
      const SizedBox(height: 12),

      _menuItem(Icons.person_outline_rounded, 'Edit Profile', '', () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );

        if (updated == true) {
          await _loadUser();
          await _loadAccountCounts();
        }
      }),

      _menuItem(Icons.credit_card_outlined, 'Payments & Payouts', '', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentsPayoutsScreen()),
        );
      }),

      _menuItem(Icons.help_outline_rounded, 'Help & Support', '', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
        );
      }),

      const SizedBox(height: 28),
      _buildLogoutButton(),
    ],
  );
}
Widget _buildQuickActions() {
  final actions = [
    [Icons.add_rounded, 'Add Listing'],
    [Icons.inventory_2_outlined, 'Manage\nListings'],
    [Icons.insights_rounded, 'Sales\nAnalytics'],
    [Icons.account_balance_wallet_outlined, 'Payouts'],
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: actions.map((a) {
      return Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(a[0] as IconData, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            a[1] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }).toList(),
  );
}

Widget _buildBoostCard() {
  return Container(
    width: double.infinity,
    height: 150,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFF2E7D8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boost your listings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get more views and sell faster.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Promote Now',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );

            if (updated == true) {
              await _loadUser();
              await _loadAccountCounts();
            }
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
class RevenueChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.18, size.height * 0.45),
      Offset(size.width * 0.32, size.height * 0.70),
      Offset(size.width * 0.50, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.58),
      Offset(size.width * 0.82, size.height * 0.40),
      Offset(size.width, size.height * 0.12),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}