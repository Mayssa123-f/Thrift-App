import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = '';

  @override
  void initState() {
    super.initState();
    selectedSize = widget.product.sizes.first;
  }

  bool get isFav => FavoritesService.isFavorite(widget.product);
  bool get inCart => CartService.isInCart(widget.product);

  void _toggleFav() {
    setState(() => FavoritesService.toggle(widget.product));
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(isFav
          ? '${widget.product.title} removed from favorites'
          : '${widget.product.title} saved ❤️'),
    );
  }

  void _addToCart() {
    CartService.add(widget.product);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(inCart
          ? 'Already in your cart'
          : '${widget.product.title} added to cart 🛒'),
    );
  }

  SnackBar _snackBar(String message) {
    return SnackBar(
      content: Text(message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      duration: const Duration(milliseconds: 900),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // COLLAPSIBLE IMAGE HEADER
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: Colors.black),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _toggleFav,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border,
                    size: 20,
                    color: isFav ? Colors.red : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                product.image,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // CONTENT
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TAG + CATEGORY ROW
                  Row(
                    children: [
                      _pill(product.tag, Colors.black, Colors.white),
                      const SizedBox(width: 8),
                      _pill(product.category, Colors.grey.shade100,
                          Colors.black54),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TITLE + PRICE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title.toUpperCase(),
                          style: GoogleFonts.syne(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.price,
                        style: GoogleFonts.syne(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // SELLER ROW
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(product.sellerImage),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.seller,
                            style: GoogleFonts.syne(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Verified seller',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // DESCRIPTION
                  Text(
                    'About this piece',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SIZE SELECTOR
                  Text(
                    'Select size',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: product.sizes.map((size) {
                      final isSelected = size == selectedSize;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            size,
                            style: GoogleFonts.syne(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 36),

                  // ADD TO CART BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        inCart ? Colors.grey.shade200 : Colors.black,
                        foregroundColor:
                        inCart ? Colors.black : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _addToCart,
                      child: Text(
                        inCart ? 'ALREADY IN CART' : 'ADD TO CART',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}