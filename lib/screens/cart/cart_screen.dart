import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/models/cart_item_model.dart';

import '../../constants/app_colors.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartController cartController = CartController();
  bool cartChanged = false;

  List<CartItemModel> items = [];
  bool isLoading = true;

  double get total {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() => isLoading = true);

      final result = await cartController.getCartItems();

      if (!mounted) return;

      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    try {
      await cartController.removeFromCart(item.product.id);

      if (!mounted) return;

      setState(() {
        items.removeWhere((cartItem) => cartItem.cartItemId == item.cartItemId);
      });
      cartChanged = true;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _clearCart() async {
    try {
      await cartController.clearCart();

      if (!mounted) return;

      setState(() {
        items.clear();
      });
      cartChanged = true;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, cartChanged);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context, cartChanged),
          ),
          title: Text(
            'MY CART',
            style: GoogleFonts.syne(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
          actions: [
            if (items.isNotEmpty)
              TextButton(
                onPressed: _clearCart,
                child: Text(
                  'Clear',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemBuilder: (context, index) {
                        return _buildCartItem(items[index]);
                      },
                    ),
                  ),
                  _buildSummary(),
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
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 20),
          Text(
            'Your bag is empty',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start browsing to add items',
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context, {'changed': cartChanged, 'goHome': true});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'GO SHOPPING',
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

  Widget _buildCartItem(CartItemModel item) {
    final product = item.product;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              product.image ?? 'https://via.placeholder.com/150',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  product.seller,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),

                if (item.selectedSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${item.selectedSize}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                if (item.hasAcceptedOffer) ...[
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black38,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Offer accepted',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '\$${item.effectivePrice.toStringAsFixed(2)}  x${item.quantity}',
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),

                  Text(
                    '${product.formattedPrice}  x${item.quantity}',
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),

          GestureDetector(
            onTap: () => _removeItem(item),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );

                if (result != null && result['orderPlaced'] == true) {
                  Navigator.pop(context, {'orderPlaced': true});
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              child: Text(
                'CHECKOUT · \$${total.toStringAsFixed(2)}',
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
