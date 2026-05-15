import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQContentSheet extends StatelessWidget {
  final String topicTitle;
  const FAQContentSheet({super.key, Mackenzie, required this.topicTitle});

  Map<String, List<Map<String, String>>> get _faqData => {
    "Buying on Vinty": [
      {"q": "How do I purchase an item?", "a": "Find your vintage piece, select your size, and click 'Buy Now'. We process payments securely via Stripe or Apple Pay."},
      {"q": "Are items authenticated?", "a": "Yes! Every luxury item goes through our rigorous physical validation process before being dispatched to you."}
    ],
    "Selling & Payouts": [
      {"q": "When do I get paid?", "a": "Payouts are transferred directly to your bank account as soon as the buyer confirms delivery and authenticity verification completes."},
      {"q": "What are the selling fees?", "a": "Vinty keeps a clean 10% commission fee per successful sale. Listing your item is completely free."}
    ],
    "Shipping & Tracking": [
      {"q": "How can I track my order?", "a": "Once your item ships, a live tracking code from DHL or FedEx will automatically populate in your profile dashboard."},
      {"q": "Who pays for shipping?", "a": "Shipping charges are systematically added to the buyer's invoice total at checkout."}
    ],
    "Refunds & Returns": [
      {"q": "What is the return policy?", "a": "Returns are valid within 3 days of delivery if an item is not as described or fails our authenticity guarantee checks."},
      {"q": "How long do refunds take?", "a": "Once approved, refunds typically take 3-5 business days to clear back onto your original payment card method."}
    ],
  };

  @override
  Widget build(BuildContext context) {
    final faqs = _faqData[topicTitle] ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(
              topicTitle.toUpperCase(),
              style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
            ),
            const Divider(height: 30, thickness: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        title: Text(faqs[index]['q']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        children: [
                          Text(faqs[index]['a']!, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}