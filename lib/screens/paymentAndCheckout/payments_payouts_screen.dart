import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/services/order_service.dart';
import 'widgets/cash_out_sheet.dart';

class PaymentsPayoutsScreen extends StatefulWidget {
  const PaymentsPayoutsScreen({super.key});

  @override
  State<PaymentsPayoutsScreen> createState() =>
      _PaymentsPayoutsScreenState();
}

class _PaymentsPayoutsScreenState
    extends State<PaymentsPayoutsScreen> {
  bool isLoading = true;

  double balance = 0;
  double totalEarned = 0;
  double totalSpent = 0;

  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  // ================= SAFE WALLET LOADING =================
  Future<void> _loadWallet() async {
    try {
      final data = await OrderService.getWallet();

      if (!mounted) return;

      setState(() {
        balance = double.tryParse(data['balance'].toString()) ?? 0.0;
        totalEarned = double.tryParse(data['total_earned'].toString()) ?? 0.0;
        totalSpent = double.tryParse(data['total_spent'].toString()) ?? 0.0;

        transactions = (data['transactions'] as List?) ?? [];

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PAYMENTS & PAYOUTS',
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadWallet,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(context),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      'Total Earned',
                      '+\$${totalEarned.toStringAsFixed(2)}',
                      Icons.arrow_downward_rounded,
                      Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryTile(
                      'Total Spent',
                      '-\$${totalSpent.toStringAsFixed(2)}',
                      Icons.arrow_upward_rounded,
                      Colors.red.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _sectionHeader('TRANSACTION HISTORY'),
              const SizedBox(height: 14),

              transactions.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 50, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.syne(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : Column(
                children: transactions
                    .map((t) => _buildTransaction(t))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BALANCE CARD =================
  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vinty Wallet',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: GoogleFonts.syne(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text('Available balance',
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              onPressed: balance <= 0
                  ? null
                  : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      CashOutSheet(availableBalance: balance),
                );
              },
              child: Text(
                'CASH OUT',
                style: GoogleFonts.syne(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY TILE =================
  Widget _buildSummaryTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          )
        ],
      ),
    );
  }

  // ================= TRANSACTION =================
  Widget _buildTransaction(Map<String, dynamic> t) {
    final isSale = t['type'] == 'sale';
    final isCompleted = t['status'] == 'completed';

    // SAFE PARSE FIX HERE 👇
    final price =
        double.tryParse(t['final_price'].toString()) ?? 0.0;

    final title = t['title'] ?? 'Item';
    final status = (t['status'] ?? 'pending').toString().toUpperCase();

    final showPositive = isSale && isCompleted;
    final showNegative = !isSale;

    final amountText = showPositive
        ? '+\$${price.toStringAsFixed(2)}'
        : showNegative
        ? '-\$${price.toStringAsFixed(2)}'
        : '\$${price.toStringAsFixed(2)}';

    final amountColor = showPositive
        ? Colors.green
        : showNegative
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700)),
                Text(status,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),

          Text(
            amountText,
            style: GoogleFonts.syne(
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.syne(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.black45,
        letterSpacing: 1,
      ),
    );
  }
}