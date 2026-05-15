import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactFormSheet extends StatefulWidget {
  final bool isChat;
  const ContactFormSheet({super.key, required this.isChat});

  @override
  State<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<ContactFormSheet> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              widget.isChat ? "LIVE CONVERSATION" : "SEND AN EMAIL",
              style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isChat
                  ? "Connect securely with an active Vinty platform specialist."
                  : "Detail your query below. Our team reviews entries meticulously.",
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 25),

            if (!widget.isChat) ...[
              TextField(
                decoration: InputDecoration(
                  labelText: "Subject",
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                ),
              ),
              const SizedBox(height: 15),
            ],

            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.isChat ? "Type your live chat inquiry here..." : "Describe your problem explicitly...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isChat ? "Connecting to Concierge..." : "Message sent successfully!",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
                child: Text(
                  widget.isChat ? "START CHAT" : "SUBMIT TICKET",
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
}