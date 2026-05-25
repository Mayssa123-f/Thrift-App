import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/controllers/notification_controller.dart';
import 'package:thrift_app/screens/notifications/notifications_screen.dart';
import 'package:thrift_app/services/notification_service.dart';

import '../cart/cart_screen.dart';
import '../chat/conversations_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../sell/multi_step_sell_screen.dart';
import '../swipe/swipe_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool isSearching = false;
  int cartCount = 0;
  int notificationCount = 0;

  final TextEditingController searchController = TextEditingController();

  Future<void> refreshCartCount() async {
    await _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final items = await CartController().getCartItems();

      if (!mounted) return;

      setState(() {
        cartCount = items.length;
      });
    } catch (_) {}
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await NotificationController().getUnreadCount();

      if (!mounted) return;

      setState(() {
        notificationCount = count;
      });
    } catch (_) {}
  }

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
    _loadCartCount();
    _loadNotificationCount();
    NotificationService.onNotificationReceived = () {
      _loadNotificationCount();
    };
  }

  void _buildPages() {
    pages = [
      HomeScreen(
        search: searchController.text,
        onCartUpdated: refreshCartCount,
      ),

      SwipeScreen(
        search: searchController.text,
        onCartUpdated: refreshCartCount,
      ),

      const SizedBox(),

      FavoritesScreen(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
      ProfileScreen(
        key: ValueKey('profile-${DateTime.now().millisecondsSinceEpoch}'),
      ),
    ];
  }

  void openCart() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );

    if (result != null) {
      if (result['changed'] == true) {
        _loadCartCount();
      }

      if (result['goHome'] == true) {
        setState(() {
          currentIndex = 0;
        });
      }
    }
  }

  void openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  void dispose() {
    NotificationService.onNotificationReceived = null;
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: _buildAppBar(),

      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      title: isSearching ? _buildSearchField() : _buildLogo(),
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              isSearching = !isSearching;

              if (!isSearching) {
                searchController.clear();
              }

              _buildPages();
            });
          },
        ),
        _buildCartButton(),
        _buildNotificationButton(),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildNotificationButton() {
    final count = notificationCount;

    return Stack(
      children: [
        IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );

            _loadNotificationCount();
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.black,
          ),
        ),

        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: const InputDecoration(
          hintText: "Search items...",
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.black),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (_) {
          setState(() {
            _buildPages();
          });
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Text(
      "VINTY",
      style: GoogleFonts.syne(
        color: Colors.black,
        fontWeight: FontWeight.w800,
        fontSize: 24,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildCartButton() {
    final count = cartCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
          onPressed: openCart,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 70 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: BottomNavClipper(),
              child: Container(
                height: 50 + bottomInset,
                padding: EdgeInsets.only(bottom: bottomInset),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navButton(0, Icons.grid_view_rounded),
                    _navButton(1, Icons.style_rounded),
                    const SizedBox(width: 68),
                    _navButton(3, Icons.favorite_border_rounded),
                    _navButton(4, Icons.person_outline_rounded),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const MultiStepSellScreen(),
                  ),
                );
              },
              child: Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: bottomInset + 84,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.black,
              elevation: 3,
              onPressed: openMessages,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
              ),
              label: Text(
                "Messages",
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(int index, IconData icon) {
    final selected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          currentIndex = index;

          if (index == 3 || index == 4) {
            _buildPages();
          }
        });
      },
      child: SizedBox(
        width: 56,
        height: 74,
        child: Icon(
          icon,
          size: 24,
          color: selected ? Colors.black : Colors.grey.shade500,
        ),
      ),
    );
  }
}

class BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    final notchHeight = 45.0;

    path.moveTo(0, 0);

    /// LEFT SIDE
    path.lineTo(size.width * 0.38, 0);

    /// CURVE DOWN
    path.cubicTo(
      size.width * 0.42,
      0,
      size.width * 0.43,
      notchHeight,
      size.width * 0.50,
      notchHeight,
    );

    /// CURVE UP
    path.cubicTo(
      size.width * 0.57,
      notchHeight,
      size.width * 0.58,
      0,
      size.width * 0.62,
      0,
    );

    /// RIGHT SIDE
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}