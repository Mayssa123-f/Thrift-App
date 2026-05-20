import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thrift_app/models/product_model.dart';
import 'package:thrift_app/models/product.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final double imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.imageHeight = 260,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isFav = false;
  bool loadingFav = false;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _initFav();
  }

  Future<void> _initFav() async {
    final result = await FavoritesService.isFavorite(widget.product.id);

    if (!mounted) return;

    setState(() => isFav = result);
  }

  Future<void> _toggleFav() async {
    if (loadingFav) return;

    setState(() => loadingFav = true);

    try {
      if (isFav) {
        await FavoritesService.removeFavorite(widget.product.id);
        isFav = false;
      } else {
        await FavoritesService.addFavorite(widget.product.id);
        isFav = true;
      }

      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Favorite error")));
    }

    if (mounted) {
      setState(() => loadingFav = false);
    }
  }

  void _addToCart() {
    final p = widget.product;

    final product = Product(
      id: p.id.toString(),
      title: p.title,
      price: p.formattedPrice,
      image: p.image ?? '',
      category: p.category ?? '',
      tag: p.styleTag ?? '',
      description: p.description,
      sizes: p.sizes,
      seller: p.seller,
      sellerImage: p.sellerImage ?? '',
    );

    CartService.add(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${p.title} added to cart',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: widget.imageHeight,
              child: Hero(
                tag: p.image ?? p.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: isPressed ? 1.05 : 1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Image.network(
                          p.image ?? 'https://via.placeholder.com/500',
                          fit: BoxFit.cover,
                        ),
                      ),

                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _toggleFav,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                            ),
                            child: loadingFav
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: isFav ? Colors.red : Colors.black,
                                  ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.formattedPrice,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _addToCart,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 19,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                p.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: p.sellerImage != null
                        ? NetworkImage(p.sellerImage!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: p.sellerImage == null
                        ? Text(
                            p.seller.isNotEmpty ? p.seller[0] : '?',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      '@${p.seller.toLowerCase().replaceAll(" ", ".")}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.styleTag ?? p.category ?? 'Item',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
