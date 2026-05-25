import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/controllers/notification_controller.dart';
import 'package:thrift_app/screens/notifications/notifications_screen.dart';
import 'package:thrift_app/services/notification_service.dart';

import '../../services/cart_service.dart';
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
    searchController.dispose();
    super.dispose();
    NotificationService.onNotificationReceived = null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: _buildAppBar(),

      body: IndexedStack(index: currentIndex, children: pages),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConversationsScreen()),
          );
        },
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

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 24, 30),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,

            onTap: (index) {
              if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const MultiStepSellScreen(),
                  ),
                );
                return;
              }

              setState(() {
                currentIndex = index;

                if (index == 3 || index == 4) {
                  _buildPages();
                }
              });
            },

            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,

            showSelectedLabels: false,
            showUnselectedLabels: false,

            selectedFontSize: 0,
            unselectedFontSize: 0,

            iconSize: 26,

            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.45),

            items: [
              _navItem(Icons.grid_view_rounded),
              _navItem(Icons.style_rounded),
              _navItem(Icons.add_circle_rounded),
              _navItem(Icons.favorite_border_rounded),
              _navItem(Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon) {
    return BottomNavigationBarItem(
      icon: Center(child: Icon(icon, size: 26)),
      label: '',
    );
  }
}
