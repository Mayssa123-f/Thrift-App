import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/models/product_model.dart';

import '../../constants/app_colors.dart';
import '../../controllers/product_controller.dart';

import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';

class SwipeScreen extends StatefulWidget {
  final String search;

  const SwipeScreen({super.key, required this.search});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final ProductController productController = ProductController();

  List<ProductModel> _stack = [];
  bool isLoading = true;

  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;

  static const double _swipeThreshold = 100;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// 🔥 FETCH FROM DATABASE
  Future<void> _loadProducts() async {
    try {
      setState(() => isLoading = true);

      final result = await productController.getProducts(
        search: widget.search,
        style: "All",
      );

      if (!mounted) return;

      setState(() {
        _stack = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  ProductModel? get _current =>
      _stack.isNotEmpty ? _stack.last : null;

  double get _rotation => (_dragX / 300).clamp(-0.25, 0.25);

  void _onDragEnd() {
    if (_dragX > _swipeThreshold) {
      _swipeRight();
    } else if (_dragX < -_swipeThreshold) {
      _swipeLeft();
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
        _isDragging = false;
      });
    }
  }

  void _swipeRight() {
    _removeTop();
  }

  /// ❤️ FAVORITES (BACKEND)
  Future<void> _swipeLeft() async {
    if (_current == null) return;

    final product = _current!;

    try {
      await FavoritesService.addFavorite(product.id);

      _showSnack('${product.title} added to favorites ❤️');
    } catch (e) {
      _showSnack('Failed to add favorite');
    }

    _removeTop();
  }

  /// 🛒 CART (USING ProductModel → Product)
  void _addCurrentToCart() {
    if (_current == null) return;

    final p = _current!;

    final product = Product(
      id: p.id.toString(),
      title: p.title,
      price: p.price.toString(),
      image: p.image ?? '',
      category: p.category ?? '',
      tag: p.styleTag ?? '',
      description: p.description,
      sizes: p.sizes,
      seller: p.seller,
      sellerImage: p.sellerImage ?? '',
    );

    CartService.add(product);

    _showSnack('${product.title} added to cart 🛒');

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 25),

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

            Expanded(
              child: _stack.isEmpty
                  ? _buildEmptyState()
                  : Stack(
                alignment: Alignment.center,
                children: [
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

                  GestureDetector(
                    onPanStart: (_) =>
                        setState(() => _isDragging = true),
                    onPanUpdate: (details) {
                      setState(() {
                        _dragX += details.delta.dx;
                        _dragY += details.delta.dy;
                      });
                    },
                    onPanEnd: (_) => _onDragEnd(),
                    child: Transform.translate(
                      offset: Offset(_dragX, _dragY * 0.4),
                      child: Transform.rotate(
                        angle: _rotation,
                        child: _buildCard(_current!),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_stack.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45,
                  vertical: 30,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _actionBtn(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.red,
                      bg: Colors.white,
                      size: 55,
                      onTap: _swipeLeft,
                      border: Colors.grey.shade200,
                    ),
                    _actionBtn(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: Colors.white,
                      bg: Colors.black,
                      size: 70,
                      onTap: _addCurrentToCart,
                    ),
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

  Widget _buildCard(ProductModel product, {bool isBackground = false}) {
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
          image: NetworkImage(product.image ?? ''),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.75),
            ],
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                  NetworkImage(product.sellerImage ?? ''),
                ),
                const SizedBox(width: 8),
                Text(
                  product.seller,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.title.toUpperCase(),
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.formattedPrice,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No more items"));
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
          border:
          border != null ? Border.all(color: border) : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }
}