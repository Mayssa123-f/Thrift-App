import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/screens/notifications/notifications_screen.dart';
import '../../constants/app_colors.dart';
import '../home/home_screen.dart';
import '../swipe/swipe_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../sell/multi_step_sell_screen.dart'; // Make sure this path is correct
import '../cart/cart_screen.dart';
import '../../services/cart_service.dart';
import '../chat/conversations_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  // 1. FIXED PAGE LIST: Ensure this order matches the Nav Items exactly
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    pages = [
      HomeScreen(search: searchController.text), // Index 0
      SwipeScreen(search: searchController.text), // Index 1
      const SizedBox(), // Index 2 (Placeholder for Sell - opened as Modal)
      const FavoritesScreen(), // Index 3
      const ProfileScreen(), // Index 4
    ];
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.white,
  extendBody: true,
  appBar: _buildAppBar(),

  body: IndexedStack(
    index: currentIndex,
    children: pages,
  ),

 floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 95),
  child: FloatingActionButton(
    backgroundColor: Colors.black,
    elevation: 4,
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConversationsScreen(),
        ),
      );
    },
    child: const Icon(
      Icons.chat_bubble_outline_rounded,
      color: Colors.white,
      size: 24,
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
          onPressed: () => setState(() {
            isSearching = !isSearching;
            if (!isSearching) searchController.clear();
          }),
        ),
        _buildCartButton(),
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

        const SizedBox(width: 5),
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
        onChanged: (value) => setState(() => _updatePages()),
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
    final count = CartService.count;
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
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
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 2) {
              // 3. SELL ACTION: Open the multi-step flow as a Modal
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true, // Makes it slide up from bottom
                  builder: (context) => const MultiStepSellScreen(),
                ),
              );
            } else {
              setState(() => currentIndex = index);
            }
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          elevation: 0,
          items: [
            _navItem(Icons.grid_view_rounded, "Home"),
            _navItem(Icons.style_rounded, "Swipe"),
            _navItem(Icons.add_circle_rounded, "Sell"), // Special middle button
            _navItem(Icons.favorite_border_rounded, "Wishlist"),
            _navItem(Icons.person_outline_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon, size: 26), label: label);
  }
}
