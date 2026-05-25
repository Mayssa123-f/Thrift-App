import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/controllers/cart_controller.dart';
import 'package:thrift_app/models/cart_item_model.dart';
import 'package:thrift_app/services/order_service.dart';
import '../../constants/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartController cartController = CartController();

  int _selectedPayment = 0;
  String _selectedDelivery = 'delivery';
  bool isLoading = true;
  bool isPlacingOrder = false;
  List<CartItemModel> items = [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get shipping =>
      _selectedDelivery == 'pickup' ? 0 : (subtotal > 0 ? 8.00 : 0);
  double get tax => double.parse((subtotal * 0.05).toStringAsFixed(2));
  double get total => subtotal + shipping + tax;

  final List<String> _paymentLabels = [
    'Credit / Debit Card',

    'Cash on Delivery',
  ];

  final List<IconData> _paymentIcons = [
    Icons.credit_card_outlined,

    Icons.payments_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final result = await cartController.getCartItems();
      if (!mounted) return;
      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _processPayment() async {
    if (isPlacingOrder) return;
    setState(() => isPlacingOrder = true);

    try {
      // Cash on delivery — skip Stripe
      if (_selectedPayment == 1) {
        final result = await OrderService.createOrder(
          deliveryMethod: _selectedDelivery,
          paymentIntentId: '',
        );
        if (!mounted) return;
        _showSuccessSheet(
          result['total_price']?.toString() ?? total.toStringAsFixed(2),
        );
        return;
      }

      // Step 1 — create PaymentIntent on backend
      final intentData = await OrderService.createPaymentIntent();
      final clientSecret = intentData['clientSecret'];

      // Step 2 — init Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Vinty',
          style: ThemeMode.light,
        ),
      );

      // Step 3 — show Stripe payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 4 — extract paymentIntentId from clientSecret
      final paymentIntentId = clientSecret.split('_secret_')[0];

      // Step 5 — confirm order on backend
      final result = await OrderService.createOrder(
        deliveryMethod: _selectedDelivery,
        paymentIntentId: paymentIntentId,
      );

      if (!mounted) return;
      _showSuccessSheet(
        result['total_price']?.toString() ?? total.toStringAsFixed(2),
      );
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code != FailureCode.Canceled) {
        _showSnack('Payment failed: ${e.error.localizedMessage}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isPlacingOrder = false);
    }
  }

  void _showSuccessSheet(String paidTotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 52,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ORDER PLACED!',
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your unique finds are on their way.',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total charged: \$$paidTotal',
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'BACK TO SHOPPING',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHECKOUT',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('YOUR ORDER'),
                        ...items.map((item) => _buildOrderItem(item)),
                        const SizedBox(height: 24),
                        _sectionTitle('DELIVERY METHOD'),
                        _buildDeliveryOption(
                          'delivery',
                          'Home Delivery',
                          Icons.local_shipping_outlined,
                          '\$8.00',
                        ),
                        _buildDeliveryOption(
                          'pickup',
                          'Pickup',
                          Icons.store_outlined,
                          'Free',
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('SHIPPING ADDRESS'),
                        _buildAddressCard(),
                        const SizedBox(height: 24),
                        _sectionTitle('PAYMENT METHOD'),
                        ...List.generate(
                          _paymentLabels.length,
                          (i) => _buildPaymentOption(
                            i,
                            _paymentLabels[i],
                            _paymentIcons[i],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('ORDER SUMMARY'),
                        _buildSummaryCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: isPlacingOrder ? null : _processPayment,
                      child: isPlacingOrder
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'CONFIRM & PAY  ·  \$${total.toStringAsFixed(2)}',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    final product = item.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.image ?? 'https://via.placeholder.com/150',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.seller,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (item.selectedSize != null)
                  Text(
                    'Size: ${item.selectedSize}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.hasAcceptedOffer)
                Text(
                  product.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black38,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

              Text(
                '\$${item.effectivePrice.toStringAsFixed(2)} x${item.quantity}',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: item.hasAcceptedOffer
                      ? Colors.green.shade700
                      : Colors.black,
                ),
              ),

              if (item.hasAcceptedOffer)
                Text(
                  'Offer accepted',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
    String value,
    String label,
    IconData icon,
    String price,
  ) {
    final isSelected = _selectedDelivery == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDelivery = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            Text(
              price,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items.isNotEmpty ? items.first.product.seller : 'Seller',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  items.isNotEmpty
                      ? (items.first.product.location ??
                            'Seller location not provided')
                      : 'Seller location not provided',

                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(int index, String title, IconData icon) {
    final isSelected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _summaryRow(
            'Shipping',
            _selectedDelivery == 'pickup'
                ? 'Free'
                : '\$${shipping.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _summaryRow('Tax (5%)', '\$${tax.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black45,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
