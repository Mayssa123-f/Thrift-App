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
    selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';
  }

  bool get isFav => FavoritesService.isFavorite(widget.product);
  bool get inCart => CartService.isInCart(widget.product);

  void _toggleFav() {
    FavoritesService.toggle(widget.product);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(
        isFav
            ? '${widget.product.title} saved'
            : '${widget.product.title} removed from favorites',
      ),
    );
  }

  void _addToCart() {
    CartService.add(widget.product);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar(
        inCart
            ? 'Already in your cart'
            : '${widget.product.title} added to cart',
      ),
    );
  }

  void _messageSeller() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_snackBar('Messaging coming soon'));
  }

  SnackBar _snackBar(String message) {
    return SnackBar(
      content: Text(
        message,
        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      duration: const Duration(milliseconds: 900),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Colors.black,
                ),
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
              background: Hero(
                tag: product.image,
                child: Image.network(product.image, fit: BoxFit.cover),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill(product.tag, Colors.black, Colors.white),
                      const SizedBox(width: 8),
                      _pill(
                        product.category,
                        Colors.grey.shade100,
                        Colors.black54,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.price,
                        style: GoogleFonts.syne(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _sellerRow(product),

                  const SizedBox(height: 24),

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
                    runSpacing: 10,
                    children: product.sizes.map((size) {
                      final isSelected = size == selectedSize;

                      return GestureDetector(
                        onTap: () => setState(() => selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
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

                  const SizedBox(height: 32),

                  _completeYourLookSection(),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _messageSeller,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                label: Text(
                  'Message',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inCart ? Colors.grey.shade200 : Colors.black,
                  foregroundColor: inCart ? Colors.black : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _addToCart,
                child: Text(
                  inCart ? 'In Cart' : 'Add to Cart',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellerRow(Product product) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade100),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundImage: NetworkImage(product.sellerImage),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.seller,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _completeYourLookSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'COMPLETE YOUR LOOK ✨',
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                'Powered by AI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'AI style suggestions to complete your fit',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 165,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _fitItem(
                  'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=600',
                  'Oversized Tee',
                  '\$16',
                ),
                const SizedBox(width: 14),
                _fitItem(
                  'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?q=80&w=600',
                  'Baggy Pants',
                  '\$28',
                ),
                const SizedBox(width: 14),
                _fitItem(
                  'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600',
                  'Chunky Sneakers',
                  '\$42',
                ),
                const SizedBox(width: 14),
                _fitItem(
                  'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?q=80&w=600',
                  'Silver Chain',
                  '\$12',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fitItem(String image, String title, String price) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
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
