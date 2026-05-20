import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/models/product_model.dart';

import '../../constants/app_colors.dart';
import '../../services/favorites_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/chat_room_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = '';

  bool isFav = false;
  bool isLoadingFav = true;
  bool isOpeningChat = false;

  @override
  void initState() {
    super.initState();

    selectedSize =
        widget.product.sizes.isNotEmpty ? widget.product.sizes.first : '';

    _initFavorite();
  }

  Future<void> _initFavorite() async {
    try {
      final result = await FavoritesService.isFavorite(widget.product.id);

      if (!mounted) return;

      setState(() {
        isFav = result;
        isLoadingFav = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingFav = false);
    }
  }

  Future<void> _toggleFav() async {
    if (isLoadingFav) return;

    try {
      setState(() {
        isFav = !isFav;
      });

      if (isFav) {
        await FavoritesService.addFavorite(widget.product.id);
        _showSnack('Added to favorites ❤️');
      } else {
        await FavoritesService.removeFavorite(widget.product.id);
        _showSnack('Removed from favorites');
      }
    } catch (e) {
      setState(() => isFav = !isFav);
      _showSnack('Failed to update favorites');
    }
  }

  void _addToCart() {
    _showSnack('${widget.product.title} added to cart (mock)');
  }

  Future<void> _messageSeller() async {
  if (isOpeningChat) return;

  setState(() => isOpeningChat = true);

  try {
    final chatController = ChatController();

    final conversation =
        await chatController.startConversation(
      productId: widget.product.id,
      sellerId: widget.product.sellerId,
    );

    // SEND PRODUCT CARD MESSAGE
    await chatController.sendProductMessage(
      conversationId: conversation.id,
      productId: widget.product.id,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversation: conversation,
          receiverName: widget.product.seller,
          receiverImage: widget.product.sellerImage,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    _showSnack(
      e.toString().replaceFirst('Exception: ', ''),
    );
  } finally {
    if (mounted) {
      setState(() => isOpeningChat = false);
    }
  }
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
          borderRadius: BorderRadius.circular(14),
        ),
      ),
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
                  child: isLoadingFav
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border,
                          size: 20,
                          color: isFav ? Colors.red : Colors.black,
                        ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: product.image ?? product.id,
                child: Image.network(
                  product.image ?? 'https://via.placeholder.com/500',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(15, 30, 15, 70),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill(
                        product.styleTag ?? 'No Tag',
                        Colors.black,
                        Colors.white,
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        product.category ?? 'Item',
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
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
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
                  const SizedBox(height: 32),
                  Text(
                    'Select size',
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: product.sizes.map((size) {
                      final selected = size == selectedSize;

                      return GestureDetector(
                        onTap: () => setState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.black : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            size,
                            style: GoogleFonts.syne(
                              color: selected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
              child: OutlinedButton(
                onPressed: isOpeningChat ? null : _messageSeller,
                child: isOpeningChat
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Message'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: _addToCart,
                child: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellerRow(ProductModel product) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(
            product.sellerImage ?? 'https://via.placeholder.com/150',
          ),
        ),
        const SizedBox(width: 12),
        Text(product.seller),
      ],
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
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}