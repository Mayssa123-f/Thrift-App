import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/controllers/chat_controller.dart';
import 'package:thrift_app/controllers/notification_controller.dart';
import 'package:thrift_app/screens/notifications/notifications_screen.dart';
import 'package:thrift_app/screens/order/my_order_screen.dart';
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
  int unreadMessagesCount = 0;
  int refreshVersion = 0;

  final TextEditingController searchController = TextEditingController();

  Future<void> refreshCartCount() async {
    await _loadCartCount();
  }

  Future<void> _loadUnreadMessagesCount() async {
    try {
      final count = await ChatController().getUnreadMessagesCount();

      if (!mounted) return;

      setState(() {
        unreadMessagesCount = count;
      });
    } catch (_) {}
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
      _loadUnreadMessagesCount();
    };
    _loadUnreadMessagesCount();
  }

  void _buildPages() {
    pages = [
      HomeScreen(
        key: ValueKey('home-$refreshVersion'),
        search: searchController.text,
        onCartUpdated: refreshCartCount,
      ),

      SwipeScreen(
        key: ValueKey('swipe-$refreshVersion'),
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

    if (!mounted) return;

    if (result != null && result['orderPlaced'] == true) {
      final bool shouldOpenOrders = result['openOrders'] == true;

      await _loadCartCount();

      if (!mounted) return;

      setState(() {
        refreshVersion++;
        _buildPages();
        currentIndex = 0;
      });

      if (shouldOpenOrders) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
        });
      }

      return;
    }

    if (result != null && result['changed'] == true) {
      await _loadCartCount();

      if (!mounted) return;

      setState(() {
        refreshVersion++;
        _buildPages();
      });
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

      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            elevation: 3,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationsScreen()),
              );

              _loadUnreadMessagesCount();
            },
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
            ),
          ),

          if (unreadMessagesCount > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: isSearching ? _buildSearchField() : _buildLogo(),
      actions: isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black),
                onPressed: () {
                  setState(() {
                    isSearching = false;
                    searchController.clear();
                    _buildPages();
                  });
                },
              ),
              const SizedBox(width: 8),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.black),
                onPressed: () {
                  setState(() {
                    isSearching = true;
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
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(left: 4, right: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: searchController,
          autofocus: false,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: "Search Items",
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.black45,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      searchController.clear();
                      setState(() {
                        _buildPages();
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: Colors.black45,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (_) {
            setState(() {
              _buildPages();
            });
          },
        ),
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

          // Positioned(
          //   right: 18,
          //   bottom: bottomInset + 84,
          //   child: FloatingActionButton.extended(
          //     backgroundColor: Colors.black,
          //     elevation: 3,
          //     onPressed: openMessages,
          //     icon: const Icon(
          //       Icons.chat_bubble_outline_rounded,
          //       color: Colors.white,
          //     ),
          //     label: Text(
          //       "Messages",
          //       style: GoogleFonts.syne(
          //         color: Colors.white,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ),
          // ),
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
