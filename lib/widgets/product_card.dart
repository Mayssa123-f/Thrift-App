import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thrift_app/models/product_model.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';
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

  @override
  void initState() {
    super.initState();
    _initFav();
  }

  Future<void> _initFav() async {
    final result = await FavoritesService.isFavorite(widget.product.id);
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
      setState(() {});
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Favorite error")),
      );
    }

    setState(() => loadingFav = false);
  }

  void _addToCart() {
    final p = widget.product;

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

    CartService.add(product); // ✅ correct type

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.title} added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: widget.imageHeight,
            child: Hero(
              tag: p.id,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  image: DecorationImage(
                    image: NetworkImage(p.image ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _toggleFav,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: loadingFav
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(
                            isFav
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Text(
                        p.formattedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            p.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}