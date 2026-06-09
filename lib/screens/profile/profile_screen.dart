import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/screens/mylisting/my_listing_screen.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/controllers/product_controller.dart';
import 'package:thrift_app/screens/order/my_order_screen.dart';
import 'package:thrift_app/services/favorites_service.dart';
import 'package:thrift_app/services/order_service.dart';

import '../favorites/favorites_screen.dart';
import '../cart/cart_screen.dart';
import '../editProfile/edit_profile_screen.dart';
import '../paymentAndCheckout/payments_payouts_screen.dart';
import '../help/help_support.dart';
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

  int profileTab = 0;
  int wishlistCount = 0;
  int cartCount = 0;
  int listingsCount = 0;
  int salesCount = 0;
  int sellerOrdersCount = 0;
  int buyerOrdersCount = 0;
  double totalRevenue = 0;
  double totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<T?> _tryLoad<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = await authController.getProfile();

      if (!mounted) return;

      final shouldSetInitialMode = currentUser == null;

      setState(() {
        currentUser = user;
        if (shouldSetInitialMode) {
          isSellerMode = user.role == 'seller';
        }
      });

      await _loadDashboardData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    final favoritesFuture = _tryLoad(FavoritesService.getFavorites());
    final cartFuture = _tryLoad(cartController.getCartItems());
    final listingsFuture = _tryLoad(productController.getMyListings());
    final buyerOrdersFuture = _tryLoad(OrderService.getMyOrders());
    final sellerOrdersFuture = _tryLoad(OrderService.getSellerOrders());
    final walletFuture = _tryLoad(OrderService.getWallet());

    final favorites = await favoritesFuture ?? [];
    final cartItems = await cartFuture ?? [];
    final listings = await listingsFuture ?? [];
    final buyerOrders = await buyerOrdersFuture ?? [];
    final sellerResult = await sellerOrdersFuture ?? <String, dynamic>{};
    final wallet = await walletFuture ?? <String, dynamic>{};

    final sellerOrders = sellerResult['orders'] as List? ?? [];

    final completedSales = sellerOrders.where((order) {
      final status = (order['status'] ?? '').toString().toLowerCase();
      return status == 'accepted' || status == 'completed';
    }).length;

    if (!mounted) return;

    setState(() {
      wishlistCount = favorites.length;
      cartCount = cartItems.length;
      listingsCount = listings.where((p) => p.isAvailable).length;
      buyerOrdersCount = buyerOrders.length;
      sellerOrdersCount = sellerOrders.length;
      salesCount = completedSales;

      totalRevenue =
          double.tryParse(
            (sellerResult['total_earnings'] ?? wallet['total_earned'] ?? 0)
                .toString(),
          ) ??
          0;

      totalSpent =
          double.tryParse((wallet['total_spent'] ?? 0).toString()) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileHeader(),
                  const SizedBox(height: 28),
                  _buildProfileTabs(),
                  const SizedBox(height: 22),

                  if (profileTab == 0) ...[
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildDashboard(),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: _buildModeToggle(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildStatsRow(),
                    const SizedBox(height: 26),
                    _buildPerformanceCard(),
                  ] else ...[
                    _buildAccountDetails(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 1.3),
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
                  ? const Icon(Icons.person, size: 32, color: Colors.grey)
                  : null,
            ),
            const Positioned(
              right: 2,
              bottom: 6,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Color(0xFF27B742),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.fullName ?? 'User',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentUser?.role == 'seller'
                    ? 'Verified Seller'
                    : 'Casual Shopper',
                style: GoogleFonts.inter(
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
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
              await _loadProfileData();
            }
          },
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _profileTabButton(Icons.grid_view_rounded, 'Dashboard', 0),
          _profileTabButton(Icons.person_outline_rounded, 'Details', 1),
        ],
      ),
    );
  }

  Widget _profileTabButton(IconData icon, String text, int index) {
    final active = profileTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => profileTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Colors.white : Colors.black45,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.syne(
                  color: active ? Colors.white : Colors.black45,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 38,
      width: 145,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _toggleBtn(Icons.shopping_cart_outlined, 'Buyer', !isSellerMode),
          _toggleBtn(Icons.storefront_outlined, 'Seller', isSellerMode),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, String text, bool active) {
    final activeBg = text == 'Seller'
        ? const Color(0xFFFFF3D6)
        : const Color(0xFFEAF2FF);

    final activeColor = text == 'Seller'
        ? const Color(0xFFC47A00)
        : const Color(0xFF2563EB);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isSellerMode = text == 'Seller'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: active ? activeColor : Colors.white60,
                ),
                const SizedBox(width: 3),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: active ? activeColor : Colors.white60,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final amount = isSellerMode ? totalRevenue : totalSpent;

    return Container(
  width: double.infinity,
  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isSellerMode
          ? [
              const Color(0xFF111111),
              const Color(0xFF080808),
              const Color(0xFF1F1400),
            ]
          : [
              const Color(0xFF111111),
              const Color(0xFF080808),
              const Color(0xFF07101F),
            ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSellerMode ? 'Total Revenue' : 'Total Spent',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 26),

          Text(
            _formatCurrency(amount),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSellerMode
                  ? const Color(0xFF3B2600)
                  : const Color(0xFF0B1E3A),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              isSellerMode
                  ? '$salesCount completed sales'
                  : '$buyerOrdersCount purchases',
              style: GoogleFonts.inter(
                color: isSellerMode
                    ? const Color(0xFFFFD37A)
                    : const Color(0xFF8CB8FF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = isSellerMode
        ? [
            {
              'label': 'Listings',
              'value': listingsCount.toString(),
              'icon': Icons.local_offer_outlined,
            },
            {
              'label': 'Sales',
              'value': salesCount.toString(),
              'icon': Icons.shopping_bag_outlined,
            },
            {
              'label': 'Orders',
              'value': sellerOrdersCount.toString(),
              'icon': Icons.inventory_2_outlined,
            },
          ]
        : [
            {
              'label': 'Saved',
              'value': wishlistCount.toString(),
              'icon': Icons.favorite_border_rounded,
            },
            {
              'label': 'Cart',
              'value': cartCount.toString(),
              'icon': Icons.shopping_bag_outlined,
            },
            {
              'label': 'Orders',
              'value': buyerOrdersCount.toString(),
              'icon': Icons.inventory_2_outlined,
            },
          ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: s == stats.last ? 0 : 12),
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSellerMode
                        ? const Color(0xFFFFF8E8)
                        : const Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    s['icon'] as IconData,
                    color: isSellerMode
                        ? const Color(0xFFC47A00)
                        : const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  s['value'] as String,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  s['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceCard() {
    final bgColor =
        isSellerMode ? const Color(0xFFFFF8E8) : const Color(0xFFEAF2FF);
    final borderColor =
        isSellerMode ? const Color(0xFFFFE6A8) : const Color(0xFFD4E4FF);
    final iconColor =
        isSellerMode ? const Color(0xFFC47A00) : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: iconColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSellerMode
                      ? 'Keep up the great work!'
                      : 'Your style is growing!',
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSellerMode
                      ? "You're performing better than 85% of sellers."
                      : "You have $wishlistCount saved items waiting.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: Colors.black,
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
            _loadDashboardData();
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
            _loadDashboardData();
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
            _loadDashboardData();
          },
        ),

        _menuItem(Icons.shopping_bag_outlined, 'My Orders', '', () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
          _loadDashboardData();
        }),

        const SizedBox(height: 22),

        _sectionLabel('SETTINGS'),
        const SizedBox(height: 12),

        _menuItem(Icons.person_outline_rounded, 'Edit Profile', '', () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );

          if (updated == true) {
            await _loadProfileData();
          }
        }),

        _menuItem(
          Icons.credit_card_outlined,
          'Payments & Payouts',
          '',
          () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentsPayoutsScreen()),
            );
            _loadDashboardData();
          },
        ),

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

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Colors.black38,
        letterSpacing: 1.4,
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
          borderRadius: BorderRadius.circular(18),
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

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '\$$whole.${parts[1]}';
  }
}