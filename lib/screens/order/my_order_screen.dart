import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/order_service.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool isLoading = true;
  int selectedTab = 0;

  List<dynamic> buyerOrders = [];
  List<dynamic> sellerOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final buyerResult = await OrderService.getMyOrders();
      final sellerResult = await OrderService.getSellerOrders();

      if (!mounted) return;

      setState(() {
        buyerOrders = buyerResult;
        sellerOrders = sellerResult['orders'] ?? [];
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get currentOrders {
    return selectedTab == 0 ? buyerOrders : sellerOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MY ORDERS',
          style: GoogleFonts.syne(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                _tabs(),

                Expanded(
                  child: currentOrders.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: currentOrders.length,
                            itemBuilder: (context, index) {
                              return _orderCard(currentOrders[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [_tabButton('Purchases', 0), _tabButton('Sales', 1)],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final active = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.syne(
                color: active ? Colors.white : Colors.black45,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final int id = order['id'];
    final String title = order['title'] ?? 'Item';
    final String? image = order['image'];
    final String status = order['status'] ?? 'pending';
    final dynamic price = order['final_price'] ?? order['price'];
    final String otherUser = selectedTab == 0
        ? (order['seller'] ?? 'Seller')
        : (order['buyer'] ?? 'Buyer');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image ?? 'https://via.placeholder.com/150',
                width: 74,
                height: 86,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    selectedTab == 0
                        ? 'Seller: $otherUser'
                        : 'Buyer: $otherUser',
                    style: GoogleFonts.inter(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _statusPill(status),

                      const Spacer(),

                      Text(
                        '\$$price',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.toLowerCase() == 'accepted'
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: status.toLowerCase() == 'accepted'
              ? Colors.green.shade700
              : Colors.black54,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        selectedTab == 0 ? 'No purchases yet' : 'No sales yet',
        style: GoogleFonts.inter(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
