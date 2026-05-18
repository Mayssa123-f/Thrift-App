import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';
import '../product/product_details_screen.dart';

class SwipeScreen extends StatefulWidget {
  final String search;

  const SwipeScreen({super.key, required this.search});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  late List<Product> _stack;

  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;

  static const double _swipeThreshold = 100;

  @override
  void initState() {
    super.initState();
    _stack = List.from(MockProducts.all);
  }

  Product? get _current => _stack.isNotEmpty ? _stack.last : null;

  // ❤️ LEFT = FAVORITE
  double get _favoriteOpacity =>
      (_dragX < 0 ? (-_dragX / _swipeThreshold).clamp(0, 1) : 0);

  // ❌ RIGHT = SKIP
  double get _skipOpacity =>
      (_dragX > 0 ? (_dragX / _swipeThreshold).clamp(0, 1) : 0);

  double get _rotation => (_dragX / 300).clamp(-0.25, 0.25);

  void _onDragEnd() {
    // 👉 RIGHT = SKIP ❌
    if (_dragX > _swipeThreshold) {
      _swipeRight();
    }
    // 👉 LEFT = FAVORITE ❤️
    else if (_dragX < -_swipeThreshold) {
      _swipeLeft();
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
    }
  }

  // ❌ RIGHT SWIPE = SKIP
  void _swipeRight() {
    _removeTop();
  }

  // ❤️ LEFT SWIPE = FAVORITE
  void _swipeLeft() {
    if (_current == null) return;

    FavoritesService.toggle(_current!);

    _showSnack('${_current!.title} added to favorites ❤️');

    _removeTop();
  }

  void _addCurrentToCart() {
    if (_current == null) return;

    CartService.add(_current!);

    _showSnack('${_current!.title} added to cart 🛒');

    _removeTop();
  }

  void _removeTop() {
    setState(() {
      if (_stack.isNotEmpty) {
        _stack.removeLast();
      }

      _dragX = 0;
      _dragY = 0;
      _isDragging = false;
    });
  }

  void _resetStack() {
    setState(() {
      _stack = List.from(MockProducts.all);

      _dragX = 0;
      _dragY = 0;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            // HEADER
            Text(
              'CURATED FOR YOU',
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${_stack.length} items left',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 20),

            // CARDS
            Expanded(
              child: _stack.isEmpty
                  ? _buildEmptyState()
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // BACK CARD
                        if (_stack.length > 1)
                          Positioned(
                            bottom: 0,
                            child: Transform.scale(
                              scale: 0.93,
                              child: _buildCard(
                                _stack[_stack.length - 2],
                                isBackground: true,
                              ),
                            ),
                          ),

                        // TOP CARD
                        GestureDetector(
                          onPanStart: (_) {
                            setState(() {
                              _isDragging = true;
                            });
                          },

                          onPanUpdate: (details) {
                            setState(() {
                              _dragX += details.delta.dx;
                              _dragY += details.delta.dy;
                            });
                          },

                          onPanEnd: (_) {
                            _onDragEnd();
                          },

                          onTap: () {
                            if (_current != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Swipe details will be connected to backend next',
                                  ),
                                ),
                              );
                            }
                          },

                          child: Transform.translate(
                            offset: Offset(_dragX, _dragY * 0.4),

                            child: Transform.rotate(
                              angle: _rotation,

                              child: Stack(
                                children: [
                                  _buildCard(_current!),

                                  // ❌ RIGHT SWIPE OVERLAY
                                  if (_dragX > 0)
                                    Positioned.fill(
                                      child: AnimatedOpacity(
                                        opacity: _skipOpacity,
                                        duration: Duration.zero,

                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            color: Colors.red.withOpacity(0.15),
                                          ),

                                          child: Align(
                                            alignment: Alignment.topRight,

                                            child: Padding(
                                              padding: const EdgeInsets.all(24),

                                              child: Transform.rotate(
                                                angle: 0.4,

                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),

                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.red,
                                                      width: 2.5,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),

                                                  child: Text(
                                                    'SKIP',
                                                    style: GoogleFonts.syne(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 22,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // ❤️ LEFT SWIPE OVERLAY
                                  if (_dragX < 0)
                                    Positioned.fill(
                                      child: AnimatedOpacity(
                                        opacity: _favoriteOpacity,
                                        duration: Duration.zero,

                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),

                                            color: Colors.green.withOpacity(
                                              0.15,
                                            ),
                                          ),

                                          child: Align(
                                            alignment: Alignment.topLeft,

                                            child: Padding(
                                              padding: const EdgeInsets.all(24),

                                              child: Transform.rotate(
                                                angle: -0.4,

                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),

                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.green,
                                                      width: 2.5,
                                                    ),

                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),

                                                  child: Text(
                                                    'SAVE',
                                                    style: GoogleFonts.syne(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 22,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // BUTTONS
            if (_stack.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45,
                  vertical: 30,
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    // ❤️ FAVORITE LEFT
                    _actionBtn(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.red,
                      bg: Colors.white,
                      size: 55,
                      onTap: _swipeLeft,
                      border: Colors.grey.shade200,
                    ),

                    // 🛒 CART CENTER
                    _actionBtn(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: Colors.white,
                      bg: Colors.black,
                      size: 70,
                      onTap: _addCurrentToCart,
                    ),

                    // ❌ SKIP RIGHT
                    _actionBtn(
                      icon: Icons.close_rounded,
                      iconColor: Colors.black,
                      bg: Colors.white,
                      size: 55,
                      onTap: _swipeRight,
                      border: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Product product, {bool isBackground = false}) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.85,
      height: size.height * 0.58,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        border: Border.all(
          color: isBackground ? Colors.transparent : Colors.grey.shade200,
        ),

        image: DecorationImage(
          image: NetworkImage(product.image),
          fit: BoxFit.cover,
        ),
      ),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),

          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [Colors.transparent, Colors.black.withOpacity(0.75)],

            stops: const [0.55, 1.0],
          ),
        ),

        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // SELLER
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(product.sellerImage),
                ),

                const SizedBox(width: 8),

                Text(
                  product.seller,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // TITLE
            Text(
              product.title.toUpperCase(),
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // PRICE
            Row(
              children: [
                Text(
                  product.price,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),

                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Text(
                    product.category,
                    style: GoogleFonts.syne(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Tap for details  ·  Drag to decide',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.style_rounded, size: 80, color: Colors.grey.shade200),

          const SizedBox(height: 20),

          Text(
            "You've seen it all!",
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'New drops coming soon.',
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
          ),

          const SizedBox(height: 30),

          GestureDetector(
            onTap: _resetStack,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),

              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Text(
                'START OVER',
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required double size,
    required VoidCallback onTap,
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: size,
        width: size,

        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border) : null,
        ),

        child: Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }
}
