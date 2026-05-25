import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/models/order_model.dart';

import '../../services/order_service.dart';
import '../../controllers/chat_controller.dart';
import '../chat/chat_room_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool isLoading = true;
  OrderModel? order;

  final ChatController chatController = ChatController();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final result = await OrderService.getOrderById(widget.orderId);
    if (!mounted) return;

    setState(() {
      order = result;
      isLoading = false;
    });
  }

  Future<void> _openChat(bool isSeller) async {
    final data = order!;
    final targetUserId = isSeller ? data.buyerId : data.sellerId;

    try {
      final conversation = await chatController.startConversation(
        productId: data.productId,
        sellerId: data.sellerId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open chat")),
      );
    }
  }

  Color _themeColor(bool isSeller) {
    return isSeller ? Colors.green.shade700 : const Color(0xFF7C4DFF); // violet
  }

  @override
  Widget build(BuildContext context) {
    final data = order;
    final isSeller = data?.viewerRole == 'seller';
    final theme = _themeColor(isSeller);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Order Details",
          style: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Order not found"))
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topIntentCard(data, isSeller),
            const SizedBox(height: 18),
            _orderHeader(data),
            const SizedBox(height: 14),
            _productCard(data),
            const SizedBox(height: 24),

            _section("Order Summary"),
            _summary(data),

            const SizedBox(height: 24),
            _section("Order Status"),
            _orderTimeline(data, isSeller),

            const SizedBox(height: 24),
            _userCard(data, isSeller),

            const SizedBox(height: 24),
            _bottomActions(data, isSeller),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Text(
    t,
    style: GoogleFonts.syne(fontWeight: FontWeight.w700),
  );

  // ================= TOP =================
  Widget _topIntentCard(OrderModel order, bool isSeller) {
    final theme = _themeColor(isSeller);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isSeller ? Icons.store : Icons.shopping_bag,
            color: theme,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSeller ? "You sold this item" : "You bought this item",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _orderHeader(OrderModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Order #${order.id}",
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(order.status.toUpperCase(),
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        )
      ],
    );
  }

  // ================= PRODUCT =================
  Widget _productCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.network(order.image ?? "", width: 70, height: 80),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                Text("Size ${order.size ?? '-'}",
                    style: GoogleFonts.inter(color: Colors.black54)),
                Text("\$${order.finalPrice}",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summary(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row("Item", "\$${order.originalPrice}"),
          _row("Shipping", "\$8"),
          const Divider(),
          _row("Total", "\$${order.totalPrice}", bold: true),
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(a,
            style: GoogleFonts.inter(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(b,
            style: GoogleFonts.inter(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
      ],
    ),
  );

  // ================= TIMELINE (4 STEPS + ICONS) =================
  Widget _orderTimeline(OrderModel order, bool isSeller) {
    final theme = _themeColor(isSeller);

    bool placed = true;
    bool paid = true;
    bool shipped = order.status == "shipped" || order.status == "delivered";
    bool delivered = order.status == "delivered";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _step("Placed", Icons.check_circle, placed, theme),
          _line(theme, paid),
          _step("Paid", Icons.payment, paid, theme),
          _line(theme, shipped),
          _step("Shipped", Icons.local_shipping, shipped, theme),
          _line(theme, delivered),
          _step("Delivered", Icons.home, delivered, theme),
        ],
      ),
    );
  }

  Widget _step(String t, IconData i, bool active, Color c) {
    return Column(
      children: [
        Icon(i, color: active ? c : Colors.grey),
        const SizedBox(height: 4),
        Text(t,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }

  Widget _line(Color c, bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? c : Colors.grey.shade200,
      ),
    );
  }

  // ================= USER =================
  Widget _userCard(OrderModel order, bool isSeller) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Text(isSeller ? order.buyerName : order.sellerName),
        ],
      ),
    );
  }

  // ================= BUTTONS =================
  Widget _bottomActions(OrderModel order, bool isSeller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _openChat(isSeller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          isSeller ? "Message Buyer" : "Message Seller",
          style: GoogleFonts.syne(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }}