import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/models/user_model.dart';
import 'package:thrift_app/services/auth_service.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import 'dart:async';

class ChatRoomScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController scrollController = ScrollController();
  final ChatController chatController = ChatController();
  final TextEditingController messageController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  List<ChatMessageModel> messages = [];
  Timer? refreshTimer;
  @override
  void initState() {
    super.initState();
    _loadMessages();

refreshTimer = Timer.periodic(
  const Duration(seconds: 2),
  (_) => _loadMessages(),
);    
  }
void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });
}
 
Future<void> _loadMessages() async {
 

  
    final data = await chatController.getMessages(
      widget.conversation.id,
    );

    if (!mounted) return;

    setState(() {
      messages = data;
      isLoading = false;
    });
    _scrollToBottom();
}
  Future<void> _sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      final newMessage = await chatController.sendMessage(
        conversationId: widget.conversation.id,
        messageText: text,
      );

      if (!mounted) return;

      setState(() {
        messages.add(newMessage);
        messageController.clear();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  void _openMakeOfferSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final TextEditingController offerController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "MAKE AN OFFER",
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Send a private offer to the seller.",
                style: GoogleFonts.inter(color: Colors.black45),
              ),

              const SizedBox(height: 22),

              TextField(
                controller: offerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  hintText: "30",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Offer UI ready. Backend connect next."),
                      ),
                    );
                  },
                  child: Text(
                    "Send Offer",
                    style: GoogleFonts.syne(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 Widget _messageBubble(ChatMessageModel message) {
  final currentUserId = AuthService.currentUser?.id;

  final bool isMine = message.senderId == currentUserId;

  // SYSTEM MESSAGE
  if (message.messageType == 'system') {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.messageText ?? "",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // OFFER MESSAGE
  if (message.messageType == 'offer') {
    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 6),
            bottomRight: Radius.circular(isMine ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Offer",
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message.messageText ?? "",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Waiting for response",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NORMAL TEXT MESSAGE
  return Align(
    alignment:
        isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMine ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
      ),
      child: Text(
        message.messageText ?? "",
        style: GoogleFonts.inter(
          color: isMine ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
  @override
void dispose() {
  refreshTimer?.cancel();
  messageController.dispose();
  super.dispose();
  scrollController.dispose();
}

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.productTitle ?? "Product Chat";

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          title,
          style: GoogleFonts.syne(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 52,
                    width: 52,
                    color: Colors.grey.shade200,
                    child: widget.conversation.productImage != null
                        ? Image.network(
                            widget.conversation.productImage!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_outlined),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: _openMakeOfferSheet,
                  child: Text(
                    "Offer",
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _messageBubble(messages[index]);
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _openMakeOfferSheet,
                    icon: const Icon(Icons.local_offer_outlined),
                  ),

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}