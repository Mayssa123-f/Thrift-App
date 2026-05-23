import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thrift_app/services/notification_service.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final ConversationModel conversation;
  final ProductModel? sourceProduct;
  final String? receiverName;
  final String? receiverImage;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
    this.sourceProduct,
    this.receiverName,
    this.receiverImage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatController chatController = ChatController();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Timer? refreshTimer;

  bool isLoading = true;
  bool isSending = false;
  List<ChatMessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    NotificationService.setActiveConversation(widget.conversation.id);
    _loadMessages();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadMessages(),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final data = await chatController.getMessages(widget.conversation.id);

      if (!mounted) return;

      setState(() {
        messages = data;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
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
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _productContextCard() {
    final product = widget.sourceProduct;

    final title = product?.title ?? widget.conversation.productTitle;
    final image = product?.image ?? widget.conversation.productImage;
    final price =
        product?.formattedPrice ??
        (widget.conversation.productPrice != null
            ? "\$${widget.conversation.productPrice}"
            : null);

    if (title == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image ?? 'https://via.placeholder.com/150',
              height: 58,
              width: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You started this chat from",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (price != null)
                  Text(
                    price,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            "View",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    // PRODUCT MESSAGE
    if (message.messageType == 'product') {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 290,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMine ? 20 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 20),
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  message.productImage ?? '',
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message.productTitle ?? "Product",
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                message.messageText ?? "",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    "\$${message.productPrice}",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "View Item",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // NORMAL TEXT MESSAGE
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    NotificationService.setActiveConversation(null);
    refreshTimer?.cancel();
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiverName =
        widget.receiverName ?? widget.conversation.receiverName ?? "Seller";
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverImage != null
                  ? NetworkImage(widget.receiverImage!)
                  : widget.conversation.receiverImage != null
                  ? NetworkImage(widget.conversation.receiverImage!)
                  : null,
              child: widget.receiverImage == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              receiverName,
              style: GoogleFonts.syne(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
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
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
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
