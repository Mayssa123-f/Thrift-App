import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CashOutSheet extends StatefulWidget {
  final double availableBalance;
  const CashOutSheet({super.key, required this.availableBalance});

  @override
  State<CashOutSheet> createState() => _CashOutSheetState();
}

class _CashOutSheetState extends State<CashOutSheet> {
  final _amountController = TextEditingController();
  bool _isInstant = false;
  double _processingFee = 0.00;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.availableBalance.toStringAsFixed(2);
  }

  void _calculateFees(String val) {
    double input = double.tryParse(val) ?? 0.0;
    setState(() {
      // Premium tier fee structure: 1.5% for instant payout, capped or free for standard.
      _processingFee = _isInstant ? (input * 0.015) : 0.00;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double currentInput = double.tryParse(_amountController.text) ?? 0.0;
    double netPayout = currentInput - _processingFee;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Text("SECURE CASH OUT", style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18)),
            Text("Funds will be routed to your primary destination bank card.", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 25),

            // 🪙 INPUT AMOUNT BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text("\$", style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _calculateFees,
                      style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                  GestureButton(
                    onTap: () {
                      _amountController.text = widget.availableBalance.toStringAsFixed(2);
                      _calculateFees(_amountController.text);
                    },
                    child: Text("USE MAX", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey.shade600)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ⚡ Payout Speed Selection
            Text("TRANSFER SPEED", style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _speedCard(
                    title: "Standard",
                    subtitle: "1-3 Days • Free",
                    isSelected: !_isInstant,
                    onTap: () {
                      setState(() {
                        _isInstant = false;
                        _calculateFees(_amountController.text);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _speedCard(
                    title: "Instant",
                    subtitle: "Minutes • 1.5% Fee",
                    isSelected: _isInstant,
                    onTap: () {
                      setState(() {
                        _isInstant = true;
                        _calculateFees(_amountController.text);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 📊 RECEIPT BREAKDOWN
            _breakdownRow("Gross Transfer Amount", "\$${currentInput.toStringAsFixed(2)}"),
            _breakdownRow("Vinty Processing Fee", "-\$${_processingFee.toStringAsFixed(2)}"),
            const Divider(height: 24),
            _breakdownRow("Net Total Payout", "\$${(netPayout < 0 ? 0.00 : netPayout).toStringAsFixed(2)}", isBold: true),

            const SizedBox(height: 30),

            // 🚀 ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: (currentInput <= 0 || currentInput > widget.availableBalance) ? null : () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Payout of \$${(netPayout).toStringAsFixed(2)} initiated successfully!",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
                child: Text(
                  "CONFIRM TRANSFER",
                  style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _speedCard({required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool isBold = false}) {
    final style = isBold
        ? GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)
        : GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

// Wrapper for custom minimal button
class GestureButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const GestureButton({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child);
  }
}